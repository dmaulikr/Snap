//
//  Card.m
//  Snap
//
//  Created by Scott Gardner on 12/21/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Card.h"

@implementation Card

- (id)initWithSuit:(Suit)suit value:(int)value
{
    ZAssert(value >= CardAce && value <= CardKing, @"Invalid card value");
    
    if (self = [super init]) {
        _suit = suit;
        _value = value;
    }
    
    return self;
}

- (BOOL)isEqualToCard:(Card *)otherCard
{
	NSParameterAssert(otherCard);
    return otherCard.suit == self.suit && otherCard.value == self.value;
}

- (BOOL)matchesCard:(Card *)otherCard
{
    NSParameterAssert(otherCard);
    return self.value == otherCard.value;
}

@end
