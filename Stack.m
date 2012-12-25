//
//  Stack.m
//  Snap
//
//  Created by Scott Gardner on 12/23/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Stack.h"
#import "Card.h"

@implementation Stack

- (void)addCardToTop:(Card *)card
{
    NSAssert(card, @"Card cannot be nil");
    NSAssert([self.cards indexOfObject:card] == NSNotFound, @"Already have this card");
    [self.cards addObject:card];
}

- (void)addCards:(NSArray *)cards
{
    self.cards = [cards mutableCopy];
}

- (id)init
{
    if (self = [super init]) {
        _cards = [NSMutableArray arrayWithCapacity:26];
    }
    
    return self;
}

@end
