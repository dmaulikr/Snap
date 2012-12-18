//
//  MatchmakingServer.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "MatchmakingServer.h"

@interface MatchmakingServer () <GKSessionDelegate>
@property (nonatomic, strong, readwrite) NSMutableArray *connectedClients;
@property (nonatomic, strong, readwrite) GKSession *session;
@end

@implementation MatchmakingServer

- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID
{
    self.connectedClients = [NSMutableArray arrayWithCapacity:self.maxClients];
    self.session = [[GKSession alloc] initWithSessionID:sessionID displayName:nil sessionMode:GKSessionModeServer];
    self.session.delegate = self;
    self.session.available = YES;
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    #ifdef DEBUG
    NSLog(@"MatchmakingServer: peer %@ changed state %d", peerID, state);
    #endif
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    #ifdef DEBUG
    NSLog(@"MatchmakingServer: connection request from peer %@", peerID);
    #endif
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
