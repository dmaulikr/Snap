//
//  CardView.m
//  Snap
//
//  Created by Scott Gardner on 12/23/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "CardView.h"
#import "Card.h"
#import "Player.h"

const CGFloat CardWidth = 67.0f; // This includes drop shadows
const CGFloat CardHeight = 99.0f;

@interface CardView ()
@property (nonatomic, strong) UIImageView *backImageView;
@property (nonatomic, strong) UIImageView *frontImageView;
@property (nonatomic, assign) CGFloat angle;
@end

@implementation CardView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self loadBack];
    }
    
    return self;
}

- (void)animateDealingToPlayer:(Player *)player withDelay:(NSTimeInterval)delay
{
    self.frame = CGRectMake(-100.0f, -100.0f, CardWidth, CardHeight);
    self.transform = CGAffineTransformMakeRotation(M_PI);
    CGPoint point = [self centerForPlayer:player];
    self.angle = [self angleForPlayer:player];
        
    [UIView animateWithDuration:0.2f delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.center = point;
        self.transform = CGAffineTransformMakeRotation(self.angle);
    } completion:nil];
}

#pragma mark - Private methods

- (void)loadBack
{
    if (!self.backImageView) {
        self.backImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.backImageView.image = [UIImage imageNamed:@"Back"];
        self.backImageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.backImageView];
    }
}

// centerForPlayer: and angleForPlayer: include randomization to add realism to the placement (point and angle) of each card in a stack

- (CGPoint)centerForPlayer:(Player *)player
{
    CGRect rect = self.superview.bounds;
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    CGFloat x = -3.0f + RANDOM_INT(6) + CardWidth/2.0f;
    CGFloat y = -3.0f + RANDOM_INT(6) + CardHeight/2.0f;
    
    switch (player.position) {
        case PlayerPositionBottom:
            x += midX - CardWidth - 7.0f;
            y += maxY - CardHeight - 30.0f;
            break;
            
        case PlayerPositionLeft:
            x += 31.0f;
            y += midY - CardWidth - 45.0f;
            break;
            
        case PlayerPositionTop:
            x += midX + 7.0f;
            y += 29.0f;
            break;
            
        case PlayerPositionRight:
            x += maxX - CardHeight + 1.0f;
            y += midY - 30.0f;
            break;
            
        default:
            break;
    }
    
    return CGPointMake(x, y);
}
                  
- (CGFloat)angleForPlayer:(Player *)player
{
    float angle = (-0.5f + RANDOM_FLOAT()) / 4.0f;
    
    switch (player.position) {
        case PlayerPositionLeft:
            angle += M_PI / 2.0f;
            break;
            
        case PlayerPositionTop:
            angle += M_PI;
            break;
            
        case PlayerPositionRight:
            angle -= M_PI / 2.0f;
            break;
            
        default:
            break;
    }
    
    return angle;
}

@end
