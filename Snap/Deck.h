//
//  Deck.h
//  Snap
//
//  Created by Scott Gardner on 12/21/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Card.h"

@interface Deck : NSObject

@property (nonatomic, strong) NSMutableArray *cards;

- (void)shuffle;
- (Card *)draw;
- (NSUInteger)cardsRemaining;

@end
