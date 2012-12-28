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
        _lastPacketNumberReceived = -1; // First packet received will be number 0
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
    DLog(@"dealloc %@", self);
}

- (int)totalCardCount
{
    return [self.closedCards cardCount] + [self.openCards cardCount];
}

- (Card *)turnOverTopCard
{
    ZAssert([self.closedCards cardCount], @"Player has no more cards");
    Card *card = [self.closedCards topmostCard];
    [self.closedCards removeTopmostCard];
    [self.openCards addCardToTop:card];
    card.isTurnedOver = YES;
    return card;
}

- (BOOL)shouldRecycle
{
    return [self.closedCards cardCount] == 0 && [self.openCards cardCount] > 1;
}

- (NSArray *)recycleCards
{
    return [self giveAllOpenCardsToPlayer:self];
}

- (NSArray *)giveAllOpenCardsToPlayer:(Player *)otherPlayer
{
    NSUInteger count = [self.openCards cardCount];
    NSMutableArray *movedCards = [NSMutableArray arrayWithCapacity:count];
    
    for (NSUInteger i = 0; i < count; i++) {
        Card *card = self.openCards.cards[i];
        card.isTurnedOver = NO;
        [otherPlayer.closedCards addCardToBottom:card];
        [movedCards addObject:card];
    }
    
    [self.openCards removeAllCards];
    return movedCards;
}

- (Card *)giveTopmostClosedCardToPlayer:(Player *)otherPlayer
{
    Card *card = [self.closedCards topmostCard];
    
    if (card) {
        [otherPlayer.closedCards addCardToBottom:card];
        [self.closedCards removeTopmostCard];
    }
    
    return card;
}

@end
