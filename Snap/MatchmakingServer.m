//
//  MatchmakingServer.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import "MatchmakingServer.h"

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

- (void)dealloc
{
    DLog(@"dealloc %@", self);
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
    ZAssert(self.serverState == ServerStateAcceptingConnections, @"Wrong state");
    self.serverState = ServerStateIgnoringNewConnections;
    self.session.available = NO;
}

#pragma mark - Private

- (void)endSession
{
    ZAssert(self.serverState != ServerStateIdle, @"Wrong state");
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
    DLog(@"MatchmakingServer: peer %@ changed state %d", peerID, state);
    
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
    DLog(@"MatchmakingServer: connection request from peer %@", peerID);
    
    if (self.serverState == ServerStateAcceptingConnections && [self.connectedClients count] < self.maxClients) {
        NSError *error;
        
        if ([session acceptConnectionFromPeer:peerID error:&error]) {
            DLog(@"MatchmakingServer: connection accepted from peer %@", peerID);
        } else {
            DLog(@"MatchmakingServer: error accepting connection from peer %@, %@", peerID, error);
        }
    } else {
        [session denyConnectionFromPeer:peerID];
    }
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    DLog(@"MatchmakingServer: connection with peer %@ failed %@", peerID, error);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    DLog(@"MatchmakingServer: session failed %@", error);
    
    if ([[error domain] isEqualToString:GKSessionErrorDomain]) {
        if ([error code] == GKSessionCannotEnableError) {
            [self.delegate matchmakingServerNoNetwork:self];
            [self endSession];
        }
    }
}

@end
