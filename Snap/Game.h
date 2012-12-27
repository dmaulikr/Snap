//
//  Game.h
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Player.h"

@class Game;

@protocol GameDelegate <NSObject>
- (void)gameWaitingForServerReady:(Game *)game;
- (void)gameWaitingForClientsReady:(Game *)game;
- (void)gameDidBegin:(Game *)game;
- (void)gameShouldDealCards:(Game *)game startingWithPlayer:(Player *)player;
- (void)game:(Game *)game didActivatePlayer:(Player *)player;

// TODO: Should be game:player:didTurnOverCard:
- (void)game:(Game *)game player:(Player *)player turnedOverCard:(Card *)card;

- (void)game:(Game *)game didRecycleCards:(NSArray *)recycledCards forPlayer:(Player *)player;
- (void)game:(Game *)game playerDidDisconnect:(Player *)disconnectedPlayer redistributedCards:(NSDictionary *)redistributedCards;
- (void)game:(Game *)game didQuitWithReason:(QuitReason)reason;
@end

@interface Game : NSObject

@property (nonatomic, weak) id <GameDelegate> delegate;
@property (nonatomic, assign) BOOL isServer;

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;
- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID;
- (void)quitGameWithReason:(QuitReason)reason;
- (void)beginRound;
- (Player *)activePlayer;
- (Player *)playerAtPosition:(PlayerPosition)position;
- (void)turnCardForPlayerAtBottom;
- (void)resumeAfterRecyclingCardsForPlayer:(Player *)player;

@end
