//
//  Stack.h
//  Snap
//
//  Created by Scott Gardner on 12/23/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

@class Card;

@interface Stack : NSObject

@property (nonatomic, strong) NSMutableArray *cards;

- (void)addCardToTop:(Card *)card;
- (void)addCards:(NSArray *)cards;
- (Card *)topmostCard;
- (void)removeTopmostCard;

@end
