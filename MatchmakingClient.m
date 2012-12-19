//
//  MatchmakingClient.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import "MatchmakingClient.h"

typedef enum {
    ClientStateIdle,
    ClientStateSearchingForServers,
    ClientStateConnecting,
    ClientStateConnected
} ClientState;

@interface MatchmakingClient () <GKSessionDelegate>
@property (nonatomic, strong) NSMutableArray *availableServers;
@property (nonatomic, strong) GKSession *session;
@property (nonatomic, assign) ClientState clientState;
@property (nonatomic, copy) NSString *serverPeerID;
@end

@implementation MatchmakingClient

- (id)init
{
    if (self = [super init]) {
        _clientState = ClientStateIdle;
    }
    
    return self;
}

- (void)startSearchingForServersWithSessionID:(NSString *)sessionID
{
    if (self.clientState == ClientStateIdle) {
        self.clientState = ClientStateSearchingForServers;
        self.availableServers = [NSMutableArray arrayWithCapacity:10];
        self.session = [[GKSession alloc] initWithSessionID:sessionID displayName:nil sessionMode:GKSessionModeClient];
        self.session.delegate = self;
        self.session.available = YES;
    }
}

- (void)connectToServerWithPeerID:(NSString *)peerID
{
    NSAssert(self.clientState == ClientStateSearchingForServers, @"Wrong state");
    self.clientState = ClientStateConnecting;
    self.serverPeerID = peerID;
    [self.session connectToPeer:peerID withTimeout:self.session.disconnectTimeout];
}

- (void)dealloc
{
    #ifdef DEBUG
    NSLog(@"dealloc %@", self);
    #endif
}

#pragma mark - Private methods

- (void)disconnectFromServer
{
    NSAssert(self.clientState != ClientStateIdle, @"Wrong state");
    self.clientState = ClientStateIdle;
    [self.session disconnectFromAllPeers];
    self.session.available = NO;
    self.session.delegate = nil;
    self.session = nil;
    self.availableServers = nil;
    [self.delegate matchmakingClient:self didDisconnectFromServer:self.serverPeerID];
    self.serverPeerID = nil;
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    #ifdef DEBUG
    NSLog(@"MatchmakingClient: peer %@ changed state %d", peerID, state);
    #endif
    
    switch (state) {
        case GKPeerStateAvailable:
            if (self.clientState == ClientStateSearchingForServers) {
                if (![self.availableServers containsObject:peerID]) {
                    [self.availableServers addObject:peerID];
                    [self.delegate matchmakingClient:self serverBecameAvailable:peerID];
                }
            }
            break;
            
        case GKPeerStateUnavailable:
            if (self.clientState == ClientStateSearchingForServers) {
                if ([self.availableServers containsObject:peerID]) {
                    [self.availableServers removeObject:peerID];
                    [self.delegate matchmakingClient:self serverBecameUnavailable:peerID];
                }
                
                // Is this the server we're currently trying to connect with?
                if (self.clientState == ClientStateConnecting && [peerID isEqualToString:self.serverPeerID]) {
                    [self disconnectFromServer];
                }
            }
            break;
            
        case GKPeerStateConnected:
            if (self.clientState == ClientStateConnecting) {
                self.clientState = ClientStateConnected;
                [self.delegate matchmakingClient:self didConnectToServer:peerID];
            }
            break;
            
        case GKPeerStateDisconnected:
            if (self.clientState == ClientStateConnected) {
                [self disconnectFromServer];
            }
            break;
            
        case GKPeerStateConnecting:
            break;
                        
        default:
            break;
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    #ifdef DEBUG
    NSLog(@"MatchmakingClient: connection request from peer %@", peerID);
    #endif
}

// Also called when server explicity calls denyConnectionFromPeer, e.g., server already has max client connections
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    #ifdef DEBUG
    NSLog(@"MatchmakingClient: connection with peer %@ failed %@", peerID, error);
    #endif
    
    [self disconnectFromServer];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    #ifdef DEBUG
    NSLog(@"MatchmakingClient: session failed %@", error);
    #endif
    
    if ([[error domain] isEqualToString:GKSessionErrorDomain]) {
        if ([error code] == GKSessionCannotEnableError) {
            [self.delegate matchmakingClientNoNetwork:self];
            [self disconnectFromServer];
        }
    }
}

@end
