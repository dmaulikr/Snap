//
//  MatchmakingServer.h
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MatchmakingServer;

@protocol MatchmakingServerDelegate <NSObject>
- (void)matchmakingServer:(MatchmakingServer *)server clientDidConnect:(NSString *)peerID;
- (void)matchmakingServer:(MatchmakingServer *)server clientDidDisconnect:(NSString *)peerID;
@end

@interface MatchmakingServer : NSObject

@property (nonatomic, weak) id <MatchmakingServerDelegate> delegate;
@property (nonatomic, assign) int maxClients;
@property (nonatomic, strong, readonly) NSMutableArray *connectedClients;
@property (nonatomic, strong, readonly) GKSession *session;

- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID;

@end
