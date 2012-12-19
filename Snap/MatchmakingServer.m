//
//  MatchmakingServer.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import "MatchmakingServer.h"

typedef enum {
    ServerStateIdle,
    ServerStateAcceptingConnections,
    ServerStateIgnoringNewConnections
} ServerState;

@interface MatchmakingServer () <GKSessionDelegate>
@property (nonatomic, strong, readwrite) NSMutableArray *connectedClients;
@property (nonatomic, strong, readwrite) GKSession *session;
@property (nonatomic, assign) ServerState serverState;
@end

@implementation MatchmakingServer

- (id)init
{
    if (self = [super init]) {
        _serverState = ServerStateIdle;
    }
    
    return self;
}

- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID
{
    if (self.serverState == ServerStateIdle) {
        self.serverState = ServerStateAcceptingConnections;
        self.connectedClients = [NSMutableArray arrayWithCapacity:self.maxClients];
        self.session = [[GKSession alloc] initWithSessionID:sessionID displayName:nil sessionMode:GKSessionModeServer];
        self.session.delegate = self;
        self.session.available = YES;
    }
}

- (void)stopAcceptingConnections
{
    NSAssert(self.serverState == ServerStateAcceptingConnections, @"Wrong state");
    self.serverState = ServerStateIgnoringNewConnections;
    self.session.available = NO;
}

#pragma mark - Private methods

- (void)endSession
{
    NSAssert(self.serverState != ServerStateIdle, @"Wrong state");
    self.serverState = ServerStateIdle;
    [self.session disconnectFromAllPeers];
    self.session.available = NO;
    self.session.delegate = nil;
    self.session = nil;
    self.connectedClients = nil;
    [self.delegate matchmakingServerSessionDidEnd:self];
}

#pragma mark - GKSessionDelegate

// GKSession becomes invalid if server is suspended, e.g., enters background

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    #ifdef DEBUG
    NSLog(@"MatchmakingServer: peer %@ changed state %d", peerID, state);
    #endif
    
    switch (state) {
        case GKPeerStateAvailable:
            break;
            
        case GKPeerStateUnavailable:
            break;
            
        case GKPeerStateConnected:
            if (self.serverState == ServerStateAcceptingConnections) {
                if (![self.connectedClients containsObject:peerID]) {
                    [self.connectedClients addObject:peerID];
                    [self.delegate matchmakingServer:self clientDidConnect:peerID];
                }
            }
            break;
            
        case GKPeerStateDisconnected:
            if (self.serverState != ServerStateIdle) {
                if ([self.connectedClients containsObject:peerID]) {
                    [self.connectedClients removeObject:peerID];
                    [self.delegate matchmakingServer:self clientDidDisconnect:peerID];
                }
            }
            break;
            
        case GKPeerStateConnecting:
            break;
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    #ifdef DEBUG
    NSLog(@"MatchmakingServer: connection request from peer %@", peerID);
    #endif
    
    if (self.serverState == ServerStateAcceptingConnections && [self.connectedClients count] < self.maxClients) {
        NSError *error;
        
        if ([session acceptConnectionFromPeer:peerID error:&error]) {
            NSLog(@"MatchmakingServer: Connection accepted from peer %@", peerID);
        } else {
            NSLog(@"MatchmakingServer: Error accepting connection from peer %@, %@", peerID, error);
        }
    } else {
        [session denyConnectionFromPeer:peerID];
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    #ifdef DEBUG
    NSLog(@"MatchmakingServer: connection with peer %@ failed %@", peerID, error);
    #endif
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    #ifdef DEBUG
    NSLog(@"MatchmakingServer: session failed %@", error);
    #endif
    
    if ([[error domain] isEqualToString:GKSessionErrorDomain]) {
        if ([error code] == GKSessionCannotEnableError) {
            [self.delegate matchmakingServerNoNetwork:self];
            [self endSession];
        }
    }
}

@end
