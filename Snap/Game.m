//
//  Game.m
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Game.h"
#import "Deck.h"
#import "Card.h"
#import "Player.h"
#import "Stack.h"
#import "Packet.h"
#import "PacketSignInResponse.h"
#import "PacketServerReady.h"
#import "PacketDealCards.h"
#import "PacketActivatePlayer.h"
#import "PacketPlayerShouldSnap.h"
#import "PacketPlayerCalledSnap.h"
#import "PacketOtherClientQuit.h"

// Global variable
PlayerPosition testPosition;

@interface Game () <GKSessionDelegate>
@property (nonatomic, assign) GameState state;
@property (nonatomic, strong) GKSession *session;
@property (nonatomic, copy) NSString *serverPeerID;
@property (nonatomic, copy) NSString *localPlayerName;
@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, strong) NSMutableSet *matchingPlayers;
@property (nonatomic, assign) PlayerPosition startingPlayerPosition;
@property (nonatomic, assign) PlayerPosition activePlayerPosition;
@property (nonatomic, assign) BOOL firstTime;
@property (nonatomic, assign) BOOL busyDealing;
@property (nonatomic, assign) BOOL hasTurnedCard;
@property (nonatomic, assign) BOOL haveSnap;
@property (nonatomic, assign) int sendPacketNumber;
@property (nonatomic, assign) BOOL mustPayCards;
@end

@implementation Game

// TODO:1 Currently the game isn’t going to be 100% fair. The player who flips a card sees that card before any of the other clients, and therefore has an advantage (it takes a few milliseconds to send out the network packets). We could compensate for this by delaying the turn-over animation for the currently active player. One way to do this is to measure the latency between the devices (the network "ping"). The server also has an advantage, because it receives the packets first and then sends out packets to the clients.

- (id)init
{
    if (self = [super init]) {
        _players = [NSMutableDictionary dictionaryWithCapacity:4];
        _matchingPlayers = [NSMutableSet setWithCapacity:4];
    }
    
    return self;
}

- (void)dealloc
{
    DLog(@"dealloc %@", self);
}

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients
{
    self.isServer = YES;
    self.session = session;
    self.session.available = NO;
    self.session.delegate = self;
    [self.session setDataReceiveHandler:self withContext:nil];
    self.state = GameStateWaitingForSignIn;
    [self.delegate gameWaitingForClientsReady:self];
    
    // Create player for the server
    Player *player = [Player new];
    player.name = name;
    player.peerID = session.peerID;
    player.position = PlayerPositionBottom;
    self.players[player.peerID] = player;
    
    // Add a player object for each client
    [clients enumerateObjectsUsingBlock:^(NSString *peerID, NSUInteger idx, BOOL *stop) {
        Player *player = [Player new];
        player.peerID = peerID;
        self.players[player.peerID] = player;
        
        switch (idx) {
            case 0:
                player.position = [clients count] == 1 ? PlayerPositionTop : PlayerPositionLeft;
                break;
                
            case 1:
                player.position = PlayerPositionTop;
                break;
                
            case 2:
                player.position = PlayerPositionRight;
                break;
                
            default:
                break;
        }
    }];
    
    Packet *packet = [Packet packetWithType:PacketTypeSignInRequest];
    [self sendPacketToAllClients:packet];
}

- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID
{
    self.isServer = NO;
    self.session = session;
    self.session.available = NO;
    self.session.delegate = self;
    [self.session setDataReceiveHandler:self withContext:nil];
    self.serverPeerID = peerID;
    self.localPlayerName = name;
    self.state = GameStateWaitingForSignIn;
    [self.delegate gameWaitingForServerReady:self];
}

- (void)startSinglePlayerGame
{
    /*
     There are basically two ways we can add single-player functionality to a multiplayer game:
     1. Keep the networking logic but instead of sending packets over the network, deliver them immediately to the clientReceivedPacket: method. The client and server logic are handled by one and the same Game object. (Of course, you can also make two different Game objects if that makes sense for your game, one that handles the client logic and one that does the server logic.).
     2. Don’t send any packets, but use timers to call the Game methods directly. This is the approach taken by Snap!, because it makes a bit more sense for our game. Each client has a slightly different view of the game world — i.e., player positions are rotated so that the client’s own player always sits at the bottom — and that makes it tricky to make Game act as both client and server.
     */
    
    self.isServer = YES;
    
    Player *player = [Player new];
    player.name = @"You";
    player.peerID = @"1";
    player.position = PlayerPositionBottom;
    self.players[player.peerID] = player;
    
    player = [Player new];
    player.name = @"Ray";
    player.peerID = @"2";
    player.position = PlayerPositionLeft;
    self.players[player.peerID] = player;
    
    player = [Player new];
    player.name = @"Lucy";
    player.peerID = @"3";
    player.position = PlayerPositionTop;
    self.players[player.peerID] = player;
    
    player = [Player new];
    player.name = @"Steve";
    player.peerID = @"4";
    player.position = PlayerPositionRight;
    self.players[player.peerID] = player;
    
    [self beginGame];
}

- (void)beginRound
{
    // In multiplayer mode, the game state changes from GameStateDealing to GameStatePlaying after the server receives the ClientDealtCards packet from all clients; because that doesn't happen in single-player mode we have to change the state manually
    if ([self isSinglePlayerGame]) self.state = GameStatePlaying;
    
    self.busyDealing = NO;
    self.hasTurnedCard = NO;
    self.haveSnap = NO;
    self.mustPayCards = NO;
    [self.matchingPlayers removeAllObjects];
    [self activatePlayerAtPosition:self.activePlayerPosition];
}

- (Player *)playerAtPosition:(PlayerPosition)position
{
	ZAssert(position >= PlayerPositionBottom && position <= PlayerPositionRight, @"Invalid player position");
    
	__block Player *player;
    
	[self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *aPlayer, BOOL *stop) {
        player = aPlayer;
        
        if (player.position == position) {
            *stop = YES;
        } else {
            player = nil;
        }
    }];
    
	return player;
}

- (void)playerCalledSnap:(Player *)player
{
    if (self.isServer) {
        if (self.haveSnap) {
            Packet *packet = [PacketPlayerCalledSnap packetWithPeerID:player.peerID snapType:SnapTypeTooLate matchingPeerIDs:nil];
            [self sendPacketToAllClients:packet];
            [self.delegate game:self playerCalledSnapTooLate:player];

        } else {
            if ([self isSinglePlayerGame]) {
                // Prevent active computer player from turning over card when other player just called Snap
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(turnCardForActivePlayer) object:nil];
            }
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(activateNextPlayer) object:nil];
            self.haveSnap = YES;
            
            if ([self.matchingPlayers count]) {
                NSMutableSet *matchingPeerIDs = [NSMutableSet setWithCapacity:4];
                
                [self.matchingPlayers enumerateObjectsUsingBlock:^(Player *player, BOOL *stop) {
                    [matchingPeerIDs addObject:player.peerID];
                }];
                
                Packet *packet = [PacketPlayerCalledSnap packetWithPeerID:player.peerID snapType:SnapTypeCorrect matchingPeerIDs:matchingPeerIDs];
                [self sendPacketToAllClients:packet];
                [self.delegate game:self player:player calledSnapWithMatchingPlayers:self.matchingPlayers];
            } else {
                Packet *packet = [PacketPlayerCalledSnap packetWithPeerID:player.peerID snapType:SnapTypeWrong matchingPeerIDs:nil];
                [self sendPacketToAllClients:packet];
                [self.delegate game:self playerCalledSnapWithNoMatch:player];
            }
        }
    
    } else {
        Packet *packet = [PacketPlayerShouldSnap packetWithPeerID:self.session.peerID];
        [self sendPacketToServer:packet];
    }
}

- (void)playerMustPayCards:(Player *)player
{
    self.mustPayCards = YES;
    int cardsNeeded = 0;
    
    for (PlayerPosition p = player.position; p < player.position; p++) {
        Player *otherPlayer = [self playerAtPosition:p % 4];
        
        if (otherPlayer && otherPlayer != player && [otherPlayer totalCardCount]) {
            cardsNeeded++;
        }
    }
    
    if (cardsNeeded > [player.closedCards cardCount]) {
        NSArray *recycledCards = [player recycleCards];
        
        if ([recycledCards count]) {
            [self.delegate game:self didRecycleCards:recycledCards forPlayer:player];
            return;
        }
    }
    
    [self resumeAfterRecyclingCardsForPlayer:player];
}

- (void)resumeAfterRecyclingCardsForPlayer:(Player *)player
{
    if (self.mustPayCards) {
        for (PlayerPosition p = player.position; p < player.position + 4; p++) {
            Player *otherPlayer = [self playerAtPosition:p % 4];
            
            if (otherPlayer && otherPlayer != player && [otherPlayer totalCardCount]) {
                Card *card = [player giveTopmostClosedCardToPlayer:otherPlayer];
                
                if (card) {
                    [self.delegate game:self player:player paysCard:card toPlayer:otherPlayer];
                }
            }
        }
    }
}

- (BOOL)resumeAfterMovingCardsForPlayer:(Player *)player
{
    self.mustPayCards = NO;
    Player *winner = [self checkWinner];
    
    if (winner) {
        [self endRoundWithWinner:winner];
        return YES;
    }
    
    Player *activePlayer = [self activePlayer];
    
    // The "|| self.hasTurnedCard" catches an edge case: if Player A (on a client) has no closed cards and it’s not their turn, and Player B turns a card and Player A immediately taps Snap, Player A would end up paying two cards instead of one, because the ActivatePlayer message starts the recycling which interferes with playerMustPayCards:. The solution is to cancel the scheduled activateNextPlayer message when any player taps Snap! in playerCalledSnap:, and resume in resumeAfterMovingCardsForPlayer:.
    if ([activePlayer totalCardCount] == 0
        || self.hasTurnedCard
        || ([activePlayer.closedCards cardCount] == 0 && [activePlayer.openCards cardCount] == 1)) { // Activate next player if active player has only one open card
        if (self.isServer) {
            [self activateNextPlayer];
        }
        
        return YES;
    } else if ([[self activePlayer] shouldRecycle]) {
        [self recycleCardsForActivePlayer];
        return NO;
    } else if ([self isSinglePlayerGame] && self.activePlayerPosition != PlayerPositionBottom) {
        [self scheduleTurningCardForComputerPlayer];
        return NO;
    }
    
    return NO;
}

- (void)endRoundWithWinner:(Player *)winner
{
    DLog(@"End of the round, winner is %@", winner);
    self.state = GameStateGameOver;
    winner.gamesWon++;
    [self.delegate game:self roundDidEndWithWinner:winner];
}

- (void)nextRound
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.state = GameStateDealing;
    self.firstTime = YES;
    self.busyDealing = YES;
    [self.delegate gameDidBeginNewRound:self];
    
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        [player.closedCards removeAllCards];
        [player.openCards removeAllCards];
    }];
    
    if (self.isServer) {
        [self pickNextStartingPlayer];
        [self dealCards];
    }
}

- (void)quitGameWithReason:(QuitReason)reason
{
    // Cancel scheduled pending calls (e.g., activating the next player after the delay, but that player quits or gets disconnected before the scheduled method is fired)
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.state = GameStateQuitting;
    
    if (reason == QuitReasonUserQuit && ![self isSinglePlayerGame]) {
        if (self.isServer) {
            Packet *packet = [Packet packetWithType:PacketTypeServerQuit];
            [self sendPacketToAllClients:packet];
        } else {
            Packet *packet = [Packet packetWithType:PacketTypeClientQuit];
            [self sendPacketToServer:packet];
        }
    }
    
    [self.session disconnectFromAllPeers];
    self.session.delegate = nil;
    self.session = nil;
    [self.delegate game:self didQuitWithReason:reason];
}

#pragma mark - Private

- (void)beginGame
{
    self.state = GameStateDealing;
    self.firstTime = YES;
    self.busyDealing = YES;
    [self.delegate gameDidBegin:self];
    
    if (self.isServer) {
        [self pickRandomStartingPlayer];
        [self dealCards];
    }
}

- (void)pickRandomStartingPlayer
{
    do {
        self.startingPlayerPosition = arc4random() % 4;
    } while (![self playerAtPosition:self.startingPlayerPosition]);
    
    self.activePlayerPosition = self.startingPlayerPosition;
    
    // Uncomment to force server to be active player at start
//     self.activePlayerPosition = PlayerPositionBottom;
}

- (void)pickNextStartingPlayer
{
    do {
        self.startingPlayerPosition++;
        
        if (self.startingPlayerPosition > PlayerPositionRight) {
            self.startingPlayerPosition = PlayerPositionBottom;
        }
    } while (![self playerAtPosition:self.startingPlayerPosition]);
    
    self.activePlayerPosition = self.startingPlayerPosition;
}

- (void)dealCards
{
    ZAssert(self.isServer, @"Must be server");
    ZAssert(self.state == GameStateDealing, @"Wrong state");
    Deck *deck = [Deck new];
    [deck shuffle];
    
    while ([deck cardsRemaining]) {
        for (PlayerPosition p = self.startingPlayerPosition; p <  self.startingPlayerPosition + 4; p++) {
            Player *player = [self playerAtPosition:(p % 4)];
            
            if (player && [deck cardsRemaining]) {
                Card *card = [deck draw];
                [player.closedCards addCardToTop:card];
            }
        }
    }
    
    Player *startingPlayer = [self activePlayer];
    
    NSMutableDictionary *playerCards = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        NSArray *cards = player.closedCards.cards;
        playerCards[player.peerID] = cards;
    }];
    
    PacketDealCards *packet = [PacketDealCards packetWithCards:playerCards startingWithPlayerPeerID:startingPlayer.peerID];
    [self sendPacketToAllClients:packet];
    
    [self.delegate gameShouldDealCards:self startingWithPlayer:startingPlayer];
}

- (Player *)activePlayer
{
    return [self playerAtPosition:self.activePlayerPosition];
}

- (Player *)playerWithPeerID:(NSString *)peerID
{
    return self.players[peerID];
}

- (void)turnCardForPlayer:(Player *)player
{
    ZAssert([player.closedCards cardCount], @"Player has no more cards");
    
    // Prevents player being able to quickly tap the closed card stack to turn over multiple cards during one turn
    self.hasTurnedCard = YES;
    
    self.haveSnap = NO;
    
    Card *card = [player turnOverTopCard];
    [self.delegate game:self player:player turnedOverCard:card];
    [self checkMatch];
}

- (void)turnCardForActivePlayer
{
    // Cancel any pending computer player Snap messages from previous round
    if ([self isSinglePlayerGame]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerCalledSnap:) object:[self playerAtPosition:PlayerPositionLeft]];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerCalledSnap:) object:[self playerAtPosition:PlayerPositionTop]];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerCalledSnap:) object:[self playerAtPosition:PlayerPositionRight]];
    }
    
    [self turnCardForPlayer:[self activePlayer]];
    
    if ([self isSinglePlayerGame]) {
        if ([self.matchingPlayers count] || RANDOM_INT(30) == 0) { // Originally set to RANDOM_INT(50)
            for (PlayerPosition p = PlayerPositionLeft; p <= PlayerPositionRight; p++) {
                Player *computerPlayer = [self playerAtPosition:p];
                
                // Randomly make computer players erroneously call Snap
                if ([computerPlayer totalCardCount]) {
                    NSTimeInterval delay = 0.5f + RANDOM_FLOAT() * 2.0f;
                    [self performSelector:@selector(playerCalledSnap:) withObject:computerPlayer afterDelay:delay];
                }
            }
        }
    }
    
    if (self.isServer) [self performSelector:@selector(activateNextPlayer) withObject:nil afterDelay:0.5f];
}

- (void)turnCardForPlayerAtBottom
{
    if (self.state == GameStatePlaying
        && self.activePlayerPosition == PlayerPositionBottom
        
        // Prevents active player from being able to turn over card before dealing (animation) is finished
        && !self.busyDealing
        
        && !self.hasTurnedCard
        && [[self activePlayer].closedCards cardCount]) {
        [self turnCardForActivePlayer];
        
        if (!self.isServer) {
            Packet *packet = [Packet packetWithType:PacketTypeClientTurnedCard];
            [self sendPacketToServer:packet];
        }
    }
}

- (void)checkMatch
{
    // TODO: Only needs to run on server, not clients
    
    [self.matchingPlayers removeAllObjects];
    
    for (PlayerPosition p = PlayerPositionBottom; p <= PlayerPositionRight; p++) {
        Player *player1 = [self playerAtPosition:p];
        
        if (player1) {
            for (PlayerPosition q = PlayerPositionBottom; q <= PlayerPositionRight; q++) {
                Player *player2 = [self playerAtPosition:q];
                
                if (p != q && player2) {
                    Card *card1 = [player1.openCards topmostCard];
                    Card *card2 = [player2.openCards topmostCard];
                    
                    if (card1 && card2 && [card1 matchesCard:card2]) {
                        [self.matchingPlayers addObject:player1];
                        break;
                    }
                }
            }
        }
    }
    
    DLog(@"Matching players %@", self.matchingPlayers);
}

- (Player *)checkWinner
{
    __block Player *winner;
    
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        if ([player totalCardCount] == 52) {
            winner = player;
            *stop = YES;
        }
    }];
    
    return winner;
}

- (void)activateNextPlayer
{
    ZAssert(self.isServer, @"Must be server");
    
    while (true) {
        self.activePlayerPosition++;
        
        if (self.activePlayerPosition > PlayerPositionRight) self.activePlayerPosition = PlayerPositionBottom;
        Player *nextPlayer = [self activePlayer];
        
        if (nextPlayer) {
            if ([nextPlayer.closedCards cardCount]) {
                // This will also send a PacketActivatePlayer packet to all clients
                [self activatePlayerAtPosition:self.activePlayerPosition];
                
                return;
            }
            
            if ([nextPlayer shouldRecycle]) {
                [self activatePlayerAtPosition:self.activePlayerPosition];
                [self recycleCardsForActivePlayer];
                return;
            }
        }
    }
}

- (void)activatePlayerAtPosition:(PlayerPosition)position
{
    // Newly-activated player will not have turned over a card yet
    self.hasTurnedCard = NO;
    
    if ([self isSinglePlayerGame]) {
        if (self.activePlayerPosition != PlayerPositionBottom) [self scheduleTurningCardForComputerPlayer];
    } else if (self.isServer) {
        NSString *peerID = [self activePlayer].peerID;
        Packet *packet = [PacketActivatePlayer packetWithPeerID:peerID];
        [self sendPacketToAllClients:packet];
    }
    
    [self.delegate game:self didActivatePlayer:[self activePlayer]];
}

- (void)activatePlayerWithPeerID:(NSString *)peerID
{
    ZAssert(!self.isServer, @"Must be client");
    Player *player = [self playerWithPeerID:peerID];
    self.activePlayerPosition = player.position;
    [self activatePlayerAtPosition:self.activePlayerPosition];
    
    if ([player shouldRecycle]) {
        [self recycleCardsForActivePlayer];
    }
}

- (void)changeRelativePositionsOfPlayers
{
    ZAssert(!self.isServer, @"Must be client");
    Player *localPlayer = [self playerWithPeerID:self.session.peerID];
    int diff = localPlayer.position;
    localPlayer.position = PlayerPositionBottom;
    
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *otherPlayer, BOOL *stop) {
        if (otherPlayer != localPlayer) {
            otherPlayer.position = (otherPlayer.position - diff) % 4;
        }
    }];
    
    testPosition = diff;
}

- (void)scheduleTurningCardForComputerPlayer
{
    // Randomize delay to make the computer player more human-like
//    NSTimeInterval delay = 0.5f + RANDOM_FLOAT() * 2.0f;
    NSTimeInterval delay = RANDOM_FLOAT();
    [self performSelector:@selector(turnCardForActivePlayer) withObject:nil afterDelay:delay];
}

- (void)recycleCardsForActivePlayer
{
    Player *player = [self activePlayer];
    NSArray *recycledCards = [player recycleCards];
    ZAssert([recycledCards count], @"Should have cards to recycle");
    [self checkMatch];
    [self.delegate game:self didRecycleCards:recycledCards forPlayer:player];
}

- (void)clientDidDisconnect:(NSString *)peerID redistributedCards:(NSDictionary *)redistributedCards
{
    if (self.state != GameStateQuitting) {
        Player *player = [self playerWithPeerID:peerID];
        
        if (player) {
            [self.players removeObjectForKey:peerID];
            
            if (self.state != GameStateWaitingForSignIn) {
                // Inform clients that this player disconnected
                // Redistribute disconnected player's cards to remaining players
                if (self.isServer) {
                    redistributedCards = [self redistributeCardsOfDisconnectedPlayer:player];
                    PacketOtherClientQuit *packet = [PacketOtherClientQuit packetWithPeerID:peerID cards:redistributedCards];
                    [self sendPacketToAllClients:packet];
                }
                
                // Add the new cards to the bottom of the closed piles
                [redistributedCards enumerateKeysAndObjectsUsingBlock:^(NSString *peerID, NSArray *cards, BOOL *stop) {
                    Player *player = [self playerWithPeerID:peerID];
                    
                    if (player) {
                        [cards enumerateObjectsUsingBlock:^(Card *card, NSUInteger idx, BOOL *stop) {
                            card.isTurnedOver = NO;
                            [player.closedCards addCardToBottom:card];
                        }];
                    }
                }];
                
                [self.delegate game:self playerDidDisconnect:player redistributedCards:redistributedCards];
                
                // If disconnected player was currently the active player, activate the next player
                if (self.isServer && player.position == self.activePlayerPosition) {
                    [self activateNextPlayer];
                }
            }
        }
    }
}

- (NSDictionary *)redistributeCardsOfDisconnectedPlayer:(Player *)disconnectedPlayer
{
    /*
     TODO:1 One situation that isn’t handled is if multiple clients disconnect at around the same time, the card redistribute messages may arrive in the wrong order. Small chance, but it could theoretically happen — after all, nothing is guaranteed when networking. We could handle this with the packetNumber scheme, but that may conflict with the ActivatePlayer packets, causing the message that activates the client itself not to be guaranteed anymore (because that ActivatePlayer packet could be dropped if it arrives out-of-order with an OtherClientQuit packet).
     */
    
    NSMutableDictionary *playerCards = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        // Exclude still-connected players with no cards remaining (i.e., they're out of the round)
        if (player != disconnectedPlayer && [player totalCardCount]) {
            NSMutableArray *cards = [NSMutableArray arrayWithCapacity:26];
            playerCards[key] = cards;
        }
    }];
    
    NSMutableArray *oldCards = [NSMutableArray arrayWithCapacity:52];
    [oldCards addObjectsFromArray:disconnectedPlayer.closedCards.cards];
    [oldCards addObjectsFromArray:disconnectedPlayer.openCards.cards];
    
    while ([oldCards count]) {
        [playerCards enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableArray *cards, BOOL *stop) {
            if ([oldCards count]) {
                [cards addObject:[oldCards lastObject]];
                [oldCards removeLastObject];
            } else {
                *stop = YES;
            }
        }];
    }
    
    return playerCards;
}

- (BOOL)isSinglePlayerGame
{
    return self.session == nil;
}

#pragma mark - Networking

- (void)sendPacketToServer:(Packet *)packet
{
    ZAssert(![self isSinglePlayerGame], @"Should not send packets in single player mode");
    
    if (packet.packetNumber != -1) packet.packetNumber = self.sendPacketNumber++;
    
    GKSendDataMode dataMode = packet.sendReliably ? GKSendDataReliable : GKSendDataUnreliable;
    NSData *data = [packet data];
    NSError *error;
    
    if (![self.session sendData:data toPeers:@[self.serverPeerID] withDataMode:dataMode error:&error]) {
        DLog(@"Error sending data to server: %@", error);
    }
}

- (void)sendPacketToAllClients:(Packet *)packet
{
    if ([self isSinglePlayerGame]) return;
    
    if (packet.packetNumber != -1) packet.packetNumber = self.sendPacketNumber++;
    
    /*
     Apple recommends GameKit transmissions be 1,000 bytes or less (which can then be transmitted in a single TCP/IP packet). Larger message need to be split up and then recombined by the receiver, which GameKit will handle but it is slower.
     */
    
    // Intially set all players' receivedResponse to NO except the server
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        player.receivedResponse = [self.session.peerID isEqualToString:player.peerID];
    }];
    
    GKSendDataMode dataMode = packet.sendReliably ? GKSendDataReliable : GKSendDataUnreliable;
    NSData *data = [packet data];
    NSError *error;
    
    if (![self.session sendDataToAllPeers:data withDataMode:dataMode error:&error]) {
        DLog(@"Error sending data to clients: %@", error);
    }
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context
{
    // [data length] returns the number of bytes
    DLog(@"Game: received data from peer %@, data:%@, length: %d", peerID, data, [data length]);
    
    Packet *packet = [Packet packetWithData:data];
    
    if (!packet) {
        DLog(@"Invalid packet: %@", data);
        return;
    }
    
    Player *player = [self playerWithPeerID:peerID];
    
    if (player) {
        if (packet.packetNumber != -1 && packet.packetNumber <= player.lastPacketNumberReceived) {
            DLog(@"Out-of-order packet!");
            return;
        }
        
        player.lastPacketNumberReceived = packet.packetNumber;
        player.receivedResponse = YES;
    }
    
    if (self.isServer) {
        [self serverReceivedPacket:packet fromPlayer:player];
    } else {
        [self clientReceivedPacket:packet];
    }
}

- (void)serverReceivedPacket:(Packet *)packet fromPlayer:(Player *)player
{
    switch (packet.packetType) {
        case PacketTypeSignInResponse:
            if (self.state == GameStateWaitingForSignIn) {
                player.name = ((PacketSignInResponse *)packet).playerName;
                
                if ([self receivedResponsesFromAllPlayers]) {
                    self.state = GameStateWaitingForReady;
                    Packet *packet = [PacketServerReady packetWithPlayers:self.players];
                    [self sendPacketToAllClients:packet];
                }
            }
            break;
            
        case PacketTypeClientReady:
        	DLog(@"State: %d, received responses: %d", self.state, [self receivedResponsesFromAllPlayers]);
            
            if (self.state == GameStateWaitingForReady && [self receivedResponsesFromAllPlayers]) {
            	DLog(@"Beginning game");
                [self beginGame];
            }
            break;
            
        case PacketTypeClientDealtCards:
            if (self.state == GameStateDealing && [self receivedResponsesFromAllPlayers]) {
                self.state = GameStatePlaying;
            }
            break;
            
        case PacketTypeClientTurnedCard:
            if (self.state == GameStatePlaying && player == [self activePlayer]) {
                [self turnCardForActivePlayer];
            }
            break;
            
        case PacketTypePlayerShouldSnap:
            if (self.state == GameStatePlaying) {
                NSString *peerID = ((PacketPlayerShouldSnap *)packet).peerID;
                Player *player = [self playerWithPeerID:peerID];
                if (player) [self playerCalledSnap:player];
            }
            break;
            
        case PacketTypeClientQuit:
            [self clientDidDisconnect:player.peerID redistributedCards:nil]; // TODO:
            break;
            
        default:
            DLog(@"Server received unexpected packet: %@", packet);
            break;
    }
}

- (void)clientReceivedPacket:(Packet *)packet
{
    switch (packet.packetType) {
        case PacketTypeSignInRequest:
            if (self.state == GameStateWaitingForSignIn) {
                self.state = GameStateWaitingForReady;
                Packet *packet = [PacketSignInResponse packetWithPlayerName:self.localPlayerName];
                [self sendPacketToServer:packet];
            }
            break;
            
        case PacketTypeServerReady:
            if (self.state == GameStateWaitingForReady) {
                self.players = ((PacketServerReady *)packet).players;
                DLog(@"The players are %@", self.players);
                [self changeRelativePositionsOfPlayers];
                Packet *packet = [Packet packetWithType:PacketTypeClientReady];
                [self sendPacketToServer:packet];
                [self beginGame];
            }
            break;
            
        case PacketTypeDealCards:
            if (self.state == GameStateGameOver) {
                [self nextRound];
            }
            // Do not make an "else if," because after nextRound returns, the state will be GameStateDealing
            if (self.state == GameStateDealing) {
                [self handleDealCardsPacket:(PacketDealCards *)packet];
            }
            break;
            
        case PacketTypeActivatePlayer:
            if (self.state == GameStatePlaying) {
                [self handleActivatePlayerPacket:(PacketActivatePlayer *)packet];
            }
            break;
            
        case PacketTypePlayerCalledSnap:
            if (self.state == GameStatePlaying) {
                [self handlePlayerCalledSnapPacket:(PacketPlayerCalledSnap *)packet];
            }
            break;
            
        case PacketTypeOtherClientQuit:
            if (self.state != GameStateQuitting) {
                PacketOtherClientQuit *quitPacket = ((PacketOtherClientQuit *)packet);
                [self clientDidDisconnect:quitPacket.peerID redistributedCards:quitPacket.cards];
            }
            break;
            
        case PacketTypeServerQuit:
            [self quitGameWithReason:QuitReasonServerQuit];
            break;
            
        default:
            DLog(@"Client received unexpected packet: %@", packet);
            break;
    }
}

- (BOOL)receivedResponsesFromAllPlayers
{
    __block BOOL receivedResponsesFromAllPlayers = YES;
    
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        if (!player.receivedResponse) receivedResponsesFromAllPlayers = NO;
        *stop = YES;
    }];
    
    return receivedResponsesFromAllPlayers;
}

- (void)handleDealCardsPacket:(PacketDealCards *)packet
{
    [packet.cards enumerateKeysAndObjectsUsingBlock:^(NSString *peerID, NSArray *cards, BOOL *stop) {
        Player *player = [self playerWithPeerID:peerID];
        [player.closedCards addCards:cards];
    }];
    
    Player *startingPlayer = [self playerWithPeerID:packet.startingPeerID];
    self.activePlayerPosition = startingPlayer.position;
    Packet *responsePacket = [Packet packetWithType:PacketTypeClientDealtCards];
    [self sendPacketToServer:responsePacket];
    self.state = GameStatePlaying;
    [self.delegate gameShouldDealCards:self startingWithPlayer:startingPlayer];
}

- (void)handleActivatePlayerPacket:(PacketActivatePlayer *)packet
{
    // At the beginning of a new round where the server is the dealer, ignore the ActivatePlayer packet to prevent the next client from processing it and immediately turning over the server player's topmost card on their screen (before the server has even tapped the closed card stack to turn over a card!)
    if (self.firstTime) {
        self.firstTime = NO;
        return;
    }
    
    Player *newPlayer = [self playerWithPeerID:packet.peerID];
    if (!newPlayer) return;
    
    /*
    // Fake missing ActivePlayer packets (to simulate receiving packets out of order)
    static int foo = 0;
    
    // Every other ActivatePlayer packet will be skipped by the client who sits at the top (as seen from the server); it will only get the ActivatePlayer packet for the player after that top player, and the player in between is skipped
    if (foo++ % 2 == 1 && testPosition == PlayerPositionTop && newPlayer.position != PlayerPositionBottom) {
        DLog(@"********** Faking missed message");
        return;
    }
    // */
    
    PlayerPosition minPosition = self.activePlayerPosition;
    if (minPosition == PlayerPositionBottom) minPosition = PlayerPositionLeft;
    PlayerPosition maxPosition = newPlayer.position;
    if (maxPosition < minPosition) maxPosition = PlayerPositionRight + 1;
    
    // Hande special situation when there is only one player (that is not the local user) who has more than one card
    if (self.activePlayerPosition == newPlayer.position && self.activePlayerPosition != PlayerPositionBottom) {
        maxPosition = minPosition + 1;
    }
    
    for (PlayerPosition p = minPosition; p < maxPosition; p++) {
        Player *player = [self playerAtPosition:p];
        
        // Skip players that have no cards or only one open card
        if (player && [player.closedCards cardCount]) {
            
            // Since the game rules call for automatically activating the next player when a player turns over a card, and all clients already receive an ActivatePlayer packet, this a good place to implement showing the turned-over card on the other clients (i.e., the client is not the active player), before activating the new player
            [self turnCardForPlayer:player];
        }
    }
    
    [self performSelector:@selector(activatePlayerWithPeerID:) withObject:packet.peerID afterDelay:0.5f];
}

- (void)handlePlayerCalledSnapPacket:(PacketPlayerCalledSnap *)packet
{
    SnapType snapType = packet.snapType;
    Player *player = [self playerWithPeerID:packet.peerID];
    
    if (player) {
        switch (snapType) {
            case SnapTypeWrong:
                [self.delegate game:self playerCalledSnapWithNoMatch:player];
                break;
                
            case SnapTypeTooLate:
                [self.delegate game:self playerCalledSnapTooLate:player];
                break;
                
            case SnapTypeCorrect:
            {
                __block NSMutableSet *matchingPlayers = [NSMutableSet setWithCapacity:4];
                
                [packet.matchingPeerIDs enumerateObjectsUsingBlock:^(NSString *peerID, BOOL *stop) {
                    Player *player = [self playerWithPeerID:peerID];
                    if (player) [matchingPlayers addObject:player];
                }];
                
                [self.delegate game:self player:player calledSnapWithMatchingPlayers:matchingPlayers];
            }
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    DLog(@"Game: peer %@ changed state %d", peerID, state);
    
    if (state == GKPeerStateDisconnected) {
        if (self.isServer) {
            [self clientDidDisconnect:peerID redistributedCards:nil]; // TODO:
        } else if ([peerID isEqualToString:self.serverPeerID]) {
            [self quitGameWithReason:QuitReasonConnectionDropped];
        }
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    DLog(@"Game: connection request from peer %@", peerID);
    [session denyConnectionFromPeer:peerID];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    DLog(@"Game: connection with peer %@ failed %@", peerID, error);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    DLog(@"Game: session failed %@", error);
    
    if ([[error domain] isEqualToString:GKSessionErrorDomain]) {
        if (self.state != GameStateQuitting) {
            [self quitGameWithReason:QuitReasonConnectionDropped];
        }
    }
}

@end
