//
//  Player.h
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

@class Card;
@class Stack;

@interface Player : NSObject

@property (nonatomic, assign) PlayerPosition position;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, assign) int gamesWon;

@property (nonatomic, strong) Stack *closedCards;
@property (nonatomic, strong) Stack *openCards;

@property (nonatomic, assign) BOOL receivedResponse;

- (Card *)turnOverTopCard;

@end
