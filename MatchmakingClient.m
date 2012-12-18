//
//  MatchmakingClient.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "MatchmakingClient.h"

@interface MatchmakingClient () <GKSessionDelegate>
@property (nonatomic, strong) NSMutableArray *availableServers;
@property (nonatomic, strong) GKSession *session;
@end

@implementation MatchmakingClient

- (void)startSearchingForServersWithSessionID:(NSString *)sessionID
{
    self.availableServers = [NSMutableArray arrayWithCapacity:10];
    self.session = [[GKSession alloc] initWithSessionID:sessionID displayName:nil sessionMode:GKSessionModeClient];
    self.session.delegate = self;
    self.session.available = YES;
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
#ifdef DEBUG
    NSLog(@"MatchmakingClient: peer %@ changed state %d", peerID, state);
#endif
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
#ifdef DEBUG
    NSLog(@"MatchmakingClient: connection request from peer %@", peerID);
#endif
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"MatchmakingClient: connection with peer %@ failed %@", peerID, error);
#endif
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"MatchmakingClient: session failed %@", error);
#endif
}

@end
