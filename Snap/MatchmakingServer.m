//
//  MatchmakingServer.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
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

#pragma mark - GKSessionDelegate

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
            
            // New client has connected to server
        case GKPeerStateConnected:
            if (self.serverState == ServerStateAcceptingConnections) {
                if (![self.connectedClients containsObject:peerID]) {
                    [self.connectedClients addObject:peerID];
                    [self.delegate matchmakingServer:self clientDidConnect:peerID];
                }
            }
            break;
            
            // Client has disconnected from server
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
}

@end
