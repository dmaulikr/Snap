//
//  Player.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Player.h"
#import "Card.h"
#import "Stack.h"

@implementation Player

- (id)init
{
    if (self = [super init]) {
        _closedCards = [Stack new];
        _openCards = [Stack new];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ peerID = %@, name = %@, position = %d", [super description], self.peerID, self.name, self.position];
}

- (void)dealloc
{
    #ifdef DEBUG
    NSLog(@"dealloc %@", self);
    #endif
}

- (Card *)turnOverTopCard
{
    NSAssert([self.closedCards.cards count], @"Player has no more cards");
    Card *card = [self.closedCards topmostCard];
    [self.closedCards removeTopmostCard];
    [self.openCards addCardToTop:card];
    card.isTurnedOver = YES;
    return card;
}

@end
