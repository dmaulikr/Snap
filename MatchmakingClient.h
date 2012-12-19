//
//  MatchmakingClient.h
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MatchmakingClient;

@protocol MatchmakingClientDelegate <NSObject>
- (void)matchmakingClient:(MatchmakingClient *)client serverBecameAvailable:(NSString *)peerID;
- (void)matchmakingClient:(MatchmakingClient *)client serverBecameUnavailable:(NSString *)peerID;
- (void)matchmakingClient:(MatchmakingClient *)client didConnectToServer:(NSString *)peerID;
- (void)matchmakingClient:(MatchmakingClient *)client didDisconnectFromServer:(NSString *)peerID;
- (void)matchmakingClientNoNetwork:(MatchmakingClient *)client;
@end

@interface MatchmakingClient : NSObject

@property (nonatomic, weak) id <MatchmakingClientDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray *availableServers;
@property (nonatomic, strong, readonly) GKSession *session;

- (void)startSearchingForServersWithSessionID:(NSString *)sessionID;
- (void)connectToServerWithPeerID:(NSString *)peerID;
- (void)disconnectFromServer;

@end
