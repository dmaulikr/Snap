//
//  MatchmakingServer.h
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MatchmakingServer;

@protocol MatchmakingServerDelegate <NSObject>
- (void)matchmakingServer:(MatchmakingServer *)server clientDidConnect:(NSString *)peerID;
- (void)matchmakingServer:(MatchmakingServer *)server clientDidDisconnect:(NSString *)peerID;
- (void)matchmakingServerNoNetwork:(MatchmakingServer *)server;
- (void)matchmakingServerSessionDidEnd:(MatchmakingServer *)server;
@end

@interface MatchmakingServer : NSObject

@property (nonatomic, weak) id <MatchmakingServerDelegate> delegate;
@property (nonatomic, assign) int maxClients;
@property (nonatomic, strong, readonly) NSMutableArray *connectedClients;
@property (nonatomic, strong, readonly) GKSession *session;

- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID;
- (void)stopAcceptingConnections;
- (void)endSession;

@end
