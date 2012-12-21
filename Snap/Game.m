//
//  Game.m
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Game.h"
#import "Packet.h"
#import "PacketSignInResponse.h"
#import "PacketServerReady.h"
#import "PacketOtherClientQuit.h"

typedef enum {
    GameStateWaitingForSignIn,
    GameStateWaitingForReady,
    GameStateDealing,
    GameStatePlaying,
    GameStateGameOver,
    GameStateQuitting
} GameState;

@interface Game () <GKSessionDelegate>
@property (nonatomic, assign) GameState state;
@property (nonatomic, strong) GKSession *session;
@property (nonatomic, copy) NSString *serverPeerID;
@property (nonatomic, copy) NSString *localPlayerName;
@property (nonatomic, strong) NSMutableDictionary *players;
@end

@implementation Game

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

- (void)quitGameWithReason:(QuitReason)reason
{
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

#pragma mark - Private methods

/*
 Apple recommends GameKit transmissions be 1,000 bytes or less (which can then be transmitted in a single TCP/IP packet). Larger message need to be split up and then recombined by the receiver, which GameKit will handle but it is slower.
 */

- (void)sendPacketToAllClients:(Packet *)packet
{
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

- (void)sendPacketToServer:(Packet *)packet
{
    GKSendDataMode dataMode = GKSendDataReliable;
    NSData *data = [packet data];
    NSError *error;
    
    if (![self.session sendData:data toPeers:@[self.serverPeerID] withDataMode:dataMode error:&error]) {
        NSLog(@"Error sending data to server: %@", error);
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
}

- (void)beginGame
{
    self.state = GameStateDealing;
    [self.delegate gameDidBegin:self];
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
