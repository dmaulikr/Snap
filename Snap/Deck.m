//
//  Deck.m
//  Snap
//
//  Created by Scott Gardner on 12/21/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Deck.h"

@interface Deck ()
@end

@implementation Deck

- (id)init
{
    if (self = [super init]) {
        _cards = [NSMutableArray arrayWithCapacity:52];
        [self setUpCards];
    }
    
    return self;
}

- (void)shuffle
{
    NSUInteger count = [self.cards count];
    NSMutableArray *shuffled = [NSMutableArray arrayWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        int idx = arc4random() % [self cardsRemaining];
        Card *card = self.cards[idx];
        [shuffled addObject:card];
        [self.cards removeObject:card];
    }
    
    NSAssert([self cardsRemaining] == 0, @"Original deck should now be empty");
    self.cards = shuffled;
}

- (Card *)draw
{
    NSAssert([self cardsRemaining] > 0, @"No more cards in the deck");
    Card *card = [self.cards lastObject];
    [self.cards removeLastObject];
    return card;
}

- (NSUInteger)cardsRemaining
{
    return [self.cards count];
}

#pragma mark - Private methods

- (void)setUpCards
{
    for (Suit suit = SuitClubs; suit <= SuitSpades; suit++) {
        // Setting value to CardQueen will reduce deck to 8 cards (4 Queens, 4 Kings)
        for (int value = CardAce /*CardQueen*/; value <= CardKing; value++) {
            Card *card = [[Card alloc] initWithSuit:suit value:value];
            [self.cards addObject:card];
        }
    }
    
    NSAssert([self cardsRemaining] == 52, @"Deck should contain 52 cards");
}

@end
