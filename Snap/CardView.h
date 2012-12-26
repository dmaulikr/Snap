//
//  CardView.h
//  Snap
//
//  Created by Scott Gardner on 12/23/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

@class Card;
@class Player;

const CGFloat CardWidth;
const CGFloat CardHeight;

@interface CardView : UIView

@property (nonatomic, strong) Card *card;

- (void)animateDealingToPlayer:(Player *)player withDelay:(NSTimeInterval)delay;
- (void)animateTurningOverForPlayer:(Player *)player;

@end
