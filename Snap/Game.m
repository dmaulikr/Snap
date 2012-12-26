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
#import "PacketOtherClientQuit.h"

// Global variable
PlayerPosition testPosition;

@interface Game () <GKSessionDelegate>
@property (nonatomic, assign) GameState state;
@property (nonatomic, strong) GKSession *session;
@property (nonatomic, copy) NSString *serverPeerID;
@property (nonatomic, copy) NSString *localPlayerName;
@property (nonatomic, strong) NSMutableDictionary *players;
@property (nonatomic, assign) PlayerPosition startingPlayerPosition;
@property (nonatomic, assign) PlayerPosition activePlayerPosition;
@property (nonatomic, assign) BOOL firstTime;
@property (nonatomic, assign) BOOL busyDealing;
@property (nonatomic, assign) BOOL hasTurnedCard;
@property (nonatomic, assign) int sendPacketNumber;
@end

@implementation Game

// TODO:1 Currently the game isn’t going to be 100% fair. The player who flips a card sees that card before any of the other clients, and therefore has an advantage (it takes a few milliseconds to send out the network packets). We could compensate for this by delaying the turn-over animation for the currently active player. One way to do this is to measure the latency between the devices (the network "ping"). The server also has an advantage, because it receives the packets first and then sends out packets to the clients.

- (id)init
{
    if (self = [super init]) {
        _players = [NSMutableDictionary dictionaryWithCapacity:4];
    }
    
    return self;
}

- (void)dealloc
{
    #ifdef DEBUG
    NSLog(@"dealloc %@", self);
    #endif
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
                
            default:
                player.position = PlayerPositionRight;
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

- (void)beginRound
{
    self.busyDealing = NO;
    self.hasTurnedCard = NO;
    [self activatePlayerAtPosition:self.activePlayerPosition];
}

- (Player *)playerAtPosition:(PlayerPosition)position
{
	NSAssert(position >= PlayerPositionBottom && position <= PlayerPositionRight, @"Invalid player position");
    
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

- (void)quitGameWithReason:(QuitReason)reason
{
    // Cancel scheduled pending calls (e.g., activating the next player after the delay, but that player quits or gets disconnected before the scheduled method is fired)
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.state = GameStateQuitting;
    
    if (reason == QuitReasonUserQuit) {
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

#pragma mark - Private methods

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
    self.activePlayerPosition = PlayerPositionBottom;
}

- (void)dealCards
{
    NSAssert(self.isServer, @"Must be server");
    NSAssert(self.state == GameStateDealing, @"Wrong state");
    Deck *deck = [Deck new];
    [deck shuffle];
    
    while ([deck.cards count]) {
        for (PlayerPosition p = self.startingPlayerPosition; p <  self.startingPlayerPosition + 4; p++) {
            Player *player = [self playerAtPosition:(p % 4)];
            
            if (player && [deck.cards count]) {
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

- (void)turnCardForPlayer:(Player *)player
{
    NSAssert([player.closedCards.cards count], @"Player has no more cards");
    
    // Prevents player being able to quickly tap the closed card stack to turn over multiple cards during one turn
    self.hasTurnedCard = YES;
    
    Card *card = [player turnOverTopCard];
    [self.delegate game:self player:player turnedOverCard:card];
}

- (void)turnCardForActivePlayer
{
    [self turnCardForPlayer:[self activePlayer]];
    if (self.isServer) [self performSelector:@selector(activateNextPlayer) withObject:nil afterDelay:0.5f];
}

- (void)turnCardForPlayerAtBottom
{
    if (self.state == GameStatePlaying
        && self.activePlayerPosition == PlayerPositionBottom
        
        // Prevents active player from being able to turn over card before dealing (animation) is finished
        && !self.busyDealing
        
        && !self.hasTurnedCard
        && [[self activePlayer].closedCards.cards count]) {
        [self turnCardForActivePlayer];
        
        if (!self.isServer) {
            Packet *packet = [Packet packetWithType:PacketTypeClientTurnedCard];
            [self sendPacketToServer:packet];
        }
    }
}

- (Player *)activePlayer
{
    return [self playerAtPosition:self.activePlayerPosition];
}

- (void)activateNextPlayer
{
    NSAssert(self.isServer, @"Must be server");
    
    while (true) {
        self.activePlayerPosition++;
        
        if (self.activePlayerPosition > PlayerPositionRight) self.activePlayerPosition = PlayerPositionBottom;
        Player *nextPlayer = [self activePlayer];
        
        if (nextPlayer) {
            // This will also send a PacketActivatePlayer packet to all clients
            [self activatePlayerAtPosition:self.activePlayerPosition];
            
            return;
        }
    }
}

- (void)activatePlayerAtPosition:(PlayerPosition)position
{
    // Newly-activated player will not have turned over a card yet
    self.hasTurnedCard = NO;
    
    if (self.isServer) {
        NSString *peerID = [self activePlayer].peerID;
        Packet *packet = [PacketActivatePlayer packetWithPeerID:peerID];
        [self sendPacketToAllClients:packet];
    }
    
    [self.delegate game:self didActivatePlayer:[self activePlayer]];
}

- (void)activatePlayerWithPeerID:(NSString *)peerID
{
    NSAssert(!self.isServer, @"Must be client");
    Player *player = [self playerWithPeerID:peerID];
    self.activePlayerPosition = player.position;
    [self activatePlayerAtPosition:self.activePlayerPosition];
}

- (void)sendPacketToServer:(Packet *)packet
{
    if (packet.packetNumber != -1) packet.packetNumber = self.sendPacketNumber++;
    
    GKSendDataMode dataMode = GKSendDataReliable;
    NSData *data = [packet data];
    NSError *error;
    
    if (![self.session sendData:data toPeers:@[self.serverPeerID] withDataMode:dataMode error:&error]) {
        NSLog(@"Error sending data to server: %@", error);
    }
}

- (void)sendPacketToAllClients:(Packet *)packet
{
    if (packet.packetNumber != -1) packet.packetNumber = self.sendPacketNumber++;
    
    /*
     Apple recommends GameKit transmissions be 1,000 bytes or less (which can then be transmitted in a single TCP/IP packet). Larger message need to be split up and then recombined by the receiver, which GameKit will handle but it is slower.
     */
    
    // Intially set all players' receivedResponse to NO except the server
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        player.receivedResponse = [self.session.peerID isEqualToString:player.peerID];
    }];
    
    GKSendDataMode dataMode = GKSendDataReliable; // Continuously sent until received or connection times out
    NSData *data = [packet data];
    NSError *error;
    
    if (![self.session sendDataToAllPeers:data withDataMode:dataMode error:&error]) {
        NSLog(@"Error sending data to clients: %@", error);
    }
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context
{
    #ifdef DEBUG
    // [data length] returns the number of bytes
    NSLog(@"Game: received data from peer %@, data:%@, length: %d", peerID, data, [data length]);
    #endif
    
    Packet *packet = [Packet packetWithData:data];
    
    if (!packet) {
        NSLog(@"Invalid packet: %@", data);
        return;
    }
    
    Player *player = [self playerWithPeerID:peerID];
    
    if (player) {
        if (packet.packetNumber != -1 && packet.packetNumber <= player.lastPacketNumberReceived) {
            NSLog(@"Out-of-order packet!");
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
                NSLog(@"The players are %@", self.players);
                [self changeRelativePositionsOfPlayers];
                Packet *packet = [Packet packetWithType:PacketTypeClientReady];
                [self sendPacketToServer:packet];
                [self beginGame];
            }
            break;
            
        case PacketTypeDealCards:
            if (self.state == GameStateDealing) {
                [self handleDealCardsPacket:(PacketDealCards *)packet];
            }
            break;
            
        case PacketTypeActivatePlayer:
            if (self.state == GameStatePlaying) {
                [self handleActivatePlayerPacket:(PacketActivatePlayer *)packet];
            }
            break;
            
        case PacketTypeOtherClientQuit:
            if (self.state != GameStateQuitting) {
                PacketOtherClientQuit *quitPacket = ((PacketOtherClientQuit *)packet);
                [self clientDidDisconnect:quitPacket.peerID];
            }
            break;
            
        case PacketTypeServerQuit:
            [self quitGameWithReason:QuitReasonServerQuit];
            break;
            
        default:
            NSLog(@"Client received unexpected packet: %@", packet);
            break;
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
        	NSLog(@"State: %d, received responses: %d", self.state, [self receivedResponsesFromAllPlayers]);
        
            if (self.state == GameStateWaitingForReady && [self receivedResponsesFromAllPlayers]) {
            	NSLog(@"Beginning game");
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
            
        case PacketTypeClientQuit:
            [self clientDidDisconnect:player.peerID];
            break;
            
        default:
            NSLog(@"Server received unexpected packet: %@", packet);
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

- (Player *)playerWithPeerID:(NSString *)peerID
{
    return self.players[peerID];
}

- (void)changeRelativePositionsOfPlayers
{
    NSAssert(!self.isServer, @"Must be client");
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
        NSLog(@"********** Faking missed message");
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
        if (player && [player.closedCards.cards count]) {
            
            // Since the game rules call for automatically activating the next player when a player turns over a card, and all clients already receive an ActivatePlayer packet, this a good place to implement showing the turned-over card on the other clients (i.e., the client is not the active player), before activating the new player
            [self turnCardForPlayer:player];
        }
    }
    
    [self performSelector:@selector(activatePlayerWithPeerID:) withObject:packet.peerID afterDelay:0.5f];
}

- (void)clientDidDisconnect:(NSString *)peerID
{
    if (self.state != GameStateQuitting) {
        Player *player = [self playerWithPeerID:peerID];
        
        if (player) {
            [self.players removeObjectForKey:peerID];
            
            if (self.state != GameStateWaitingForSignIn) {
                // Inform clients that this player disconnected
                if (self.isServer) {
                    PacketOtherClientQuit *packet = [PacketOtherClientQuit packetWithPeerID:peerID];
                    [self sendPacketToAllClients:packet];
                }
                
                [self.delegate game:self playerDidDisconnect:player];
            }
        }
    }
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    #ifdef DEBUG
    NSLog(@"Game: peer %@ changed state %d", peerID, state);
    #endif
    
    if (state == GKPeerStateDisconnected) {
        if (self.isServer) {
            [self clientDidDisconnect:peerID];
        } else if ([peerID isEqualToString:self.serverPeerID]) {
            [self quitGameWithReason:QuitReasonConnectionDropped];
        }
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    #ifdef DEBUG
    NSLog(@"Game: connection request from peer %@", peerID);
    #endif
    
    [session denyConnectionFromPeer:peerID];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    #ifdef DEBUG
    NSLog(@"Game: connection with peer %@ failed %@", peerID, error);
    #endif
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    #ifdef DEBUG
    NSLog(@"Game: session failed %@", error);
    #endif
    
    if ([[error domain] isEqualToString:GKSessionErrorDomain]) {
        if (self.state != GameStateQuitting) {
            [self quitGameWithReason:QuitReasonConnectionDropped];
        }
    }
}

@end
