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
    NSAssert(value >= CardAce && value <= CardKing, @"Invalid card value");
    
    if (self = [super init]) {
        _suit = suit;
        _value = value;
    }
    
    return self;
}

@end
