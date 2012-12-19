//
//  Game.m
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Game.h"
#import "Player.h"
#import "Packet.h"
#import "PacketSignInResponse.h"

typedef enum {
    GameStateWaitForSignIn,
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
    self.state = GameStateWaitForSignIn;
    [self.delegate gameWaitingForClientsReady:self];
    
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
    self.state = GameStateWaitForSignIn;
    [self.delegate gameWaitingForServerReady:self];
}

- (void)quitGameWithReason:(QuitReason)reason
{
    self.state = GameStateQuitting;
    [self.session disconnectFromAllPeers];
    self.session.delegate = nil;
    self.session = nil;
    [self.delegate game:self didQuitWithReason:reason];
}

#pragma mark - Private methods

/*
 Apple recommends GameKit transmissions be 1,000 bytes or less (which can then be transmitted in a single TCP/IP packet). Larger message need to be split up and then recombined by the receiver, which GameKit will handle but it is slower.
 */

- (void)sendPacketToAllClients:(Packet *)packet
{
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
    NSLog(@"Game: receive data from peer %@, data:%@, length: %d", peerID, data, [data length]);
    #endif
    
    Packet *packet = [Packet packetWithData:data];
    
    if (!packet) {
        NSLog(@"Invalid packet: %@", data);
        return;
    }
    
    Player *player = [self playerWithPeerID:peerID];
    
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
            if (self.state == GameStateWaitForSignIn) {
                self.state = GameStateWaitingForReady;
                Packet *packet = [PacketSignInResponse packetWithPlayerName:self.localPlayerName];
                [self sendPacketToServer:packet];
            }
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
            if (self.state == GameStateWaitForSignIn) {
                player.name = ((PacketSignInResponse *)packet).playerName;
                NSLog(@"Server received sign-in response from client '%@'", player.name);
            }
            break;
            
        default:
            NSLog(@"Server received unexpected packet: %@", packet);
            break;
    }
}

- (Player *)playerWithPeerID:(NSString *)peerID
{
    return self.players[peerID];
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    #ifdef DEBUG
    NSLog(@"Game: peer %@ changed state %d", peerID, state);
    #endif
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    #ifdef DEBUG
    NSLog(@"Game: connection request from peer %@", peerID);
    #endif
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
}

@end
