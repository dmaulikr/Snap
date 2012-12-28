//
//  Game.h
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

// TODO: This should be refactored into Game model and GameController classes

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

- (void)game:(Game *)game player:(Player *)player calledSnapWithMatchingPlayers:(NSSet *)matchingPlayers;
- (void)game:(Game *)game playerCalledSnapWithNoMatch:(Player *)player;
- (void)game:(Game *)game playerCalledSnapTooLate:(Player *)player;

// TODO: Should be game:player:didPayCard:toPlayer:
- (void)game:(Game *)game player:(Player *)fromPlayer paysCard:(Card *)card toPlayer:(Player *)toPlayer;

- (void)game:(Game *)game didRecycleCards:(NSArray *)recycledCards forPlayer:(Player *)player;
- (void)game:(Game *)game playerDidDisconnect:(Player *)disconnectedPlayer redistributedCards:(NSDictionary *)redistributedCards;
- (void)game:(Game *)game didQuitWithReason:(QuitReason)reason;

- (void)game:(Game *)game roundDidEndWithWinner:(Player *)winner;
- (void)gameDidBeginNewRound:(Game *)game;
@end

@interface Game : NSObject

@property (nonatomic, weak) id <GameDelegate> delegate;
@property (nonatomic, assign) BOOL isServer;

- (void)startServerGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;
- (void)startClientGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID;
- (void)startSinglePlayerGame;
- (void)beginRound;
- (Player *)activePlayer;
- (Player *)playerAtPosition:(PlayerPosition)position;
- (void)turnCardForPlayerAtBottom;
- (void)playerCalledSnap:(Player *)player;
- (void)playerMustPayCards:(Player *)player;
- (void)resumeAfterRecyclingCardsForPlayer:(Player *)player;
- (BOOL)resumeAfterMovingCardsForPlayer:(Player *)player;
- (void)nextRound;
- (void)quitGameWithReason:(QuitReason)reason;

@end
