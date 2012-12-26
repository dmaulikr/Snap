//
//  Card.h
//  Snap
//
//  Created by Scott Gardner on 12/21/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

@interface Card : NSObject

@property (nonatomic, assign) Suit suit;
@property (nonatomic, assign) int value;
@property (nonatomic, assign) BOOL isTurnedOver;

- (id)initWithSuit:(Suit)suit value:(int)value;

@end
