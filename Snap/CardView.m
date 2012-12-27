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

- (void)animateTurningOverForPlayer:(Player *)player
{
    /*
     This animation could also be implemented using Core Animation's 3D animation around the Y axis. However, using UIView's TransitionFlipFromLeft animation doesn't work well here because the card views are rotated already around the center of the table, and so the additional rotation will look weird.
     */
    
    // The loadFront method will load the UIImageView with the card’s front-facing picture.
    
    [self loadFront];
    [self.superview bringSubviewToFront:self];
    
    // Load Darken.png into a new UIImageView and add it as a subview, with its alpha initially 0.0, so it is fully transparent.
    
    UIImageView *darkenView = [[UIImageView alloc] initWithFrame:self.bounds];
    darkenView.backgroundColor = [UIColor clearColor];
    darkenView.image = [UIImage imageNamed:@"Darken"];
    darkenView.alpha = 0.0f;
    [self addSubview:darkenView];
    
    // Calculate the end position and angle for the card. To make this work we have to change centerForPlayer: to recognize that the Card is now turned over, which we'll do in a moment. For a turned-over card, centerForPlayer: returns a slightly different position, so that it moves over to the open pile.
    
    CGPoint startPoint = self.center;
    CGPoint endPoint = [self centerForPlayer:player];
    CGFloat afterAngle = [self angleForPlayer:player];
    
    // The animation itself happens in two steps, which is why we calculate the halfway point and the halfway angle. The first step of the animation reduces the width of the card to 1 point, while at the same time making the darkenView more opaque. Because the darkenView covers the entire surface of the card, the CardView now appears darker, which simulates the shadow that light casts on the card.
    
    CGPoint halfwayPoint = CGPointMake((startPoint.x + endPoint.x) / 2.0f, (startPoint.y + endPoint.y) / 2.0f);
    CGFloat halfwayAngle = (self.angle + afterAngle) / 2.0f;
    
    [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect rect = self.backImageView.bounds;
        rect.size.width = 1.0f;
        self.backImageView.bounds = rect;
        
        darkenView.bounds = rect;
        darkenView.alpha = 0.5f;
        
        self.center = halfwayPoint;
        self.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(halfwayAngle), 1.2f, 1.2f);
        
        // At this point the card is half flipped over. We also slightly scaled up the card view (by 120%) as it approaches the halfway point, to make it seem like the card is actually lifted up by the player.
        
    } completion:^(BOOL finished) {
        // Now we swap the back image with the front image.
        self.frontImageView.bounds = self.backImageView.bounds;
        self.frontImageView.hidden = NO;
        
        [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            // Resize the card view back to its full width, while simultaneously making the darken view fully transparent again.
            
            CGRect rect = self.frontImageView.bounds;
            rect.size.width = CardWidth;
            self.frontImageView.bounds = rect;
            
            darkenView.bounds = rect;
            darkenView.alpha = 0.0f;
            
            self.center = endPoint;
            self.transform = CGAffineTransformMakeRotation(afterAngle);
        } completion:^(BOOL finished) {
            // Remove the darken view and the UIImageView for the back, because we no longer need them and the card is turned over.
            
            [darkenView removeFromSuperview];
            [self unloadBack];
        }];
    }];
}

- (void)animateRecycleForPlayer:(Player *)player withDelay:(NSTimeInterval)delay
{
    [self.superview sendSubviewToBack:self];
    [self unloadFront];
    [self loadBack];
    
    [UIView animateWithDuration:0.2f delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.center = [self centerForPlayer:player];
    } completion:nil];
}

- (void)animateCloseAndMoveFromPlayer:(Player *)fromPlayer toPlayer:(Player *)toPlayer withDelay:(NSTimeInterval)delay
{
    [self.superview sendSubviewToBack:self];
    [self unloadFront];
    [self loadBack];
    CGPoint point = [self centerForPlayer:toPlayer];
    self.angle = [self angleForPlayer:toPlayer];
    
    [UIView animateWithDuration:0.4f delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.center = point;
        self.transform = CGAffineTransformMakeRotation(self.angle);
    } completion:nil];
}

#pragma mark - Private methods

- (void)loadFront
{
    if (!self.frontImageView) {
        self.frontImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        
        // Scale to fill in order to resize the image to match the image view throughout the resizing animation
        self.frontImageView.contentMode = UIViewContentModeScaleToFill;
        
        self.frontImageView.hidden = YES;
        [self addSubview:self.frontImageView];
        
        NSString *suitString;
        
        switch (self.card.suit) {
            case SuitClubs:
                suitString = @"Clubs";
                break;
                
            case SuitDiamonds:
                suitString = @"Diamonds";
                break;
                
            case SuitHearts:
                suitString = @"Hearts";
                break;
                
            case SuitSpades:
                suitString = @"Spades";
                break;
                
            default:
                break;
        }
        
        NSString *valueString;
        
        switch (self.card.value) {
            case CardAce:
                valueString = @"Ace";
                break;
                
            case CardJack:
                valueString = @"Jack";
                break;
                
            case CardQueen:
                valueString = @"Queen";
                break;
                
            case CardKing:
                valueString = @"King";
                break;
                
            default:
            	valueString = [NSString stringWithFormat:@"%d", self.card.value];
                break;
        }
        
        NSString *filename = [NSString stringWithFormat:@"%@ %@", suitString, valueString];
        self.frontImageView.image = [UIImage imageNamed:filename];
    }
}

- (void)unloadFront
{
    [self.frontImageView removeFromSuperview];
    self.frontImageView = nil;
}

- (void)loadBack
{
    if (!self.backImageView) {
        self.backImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.backImageView.image = [UIImage imageNamed:@"Back"];
        self.backImageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.backImageView];
    }
}

- (void)unloadBack
{
    [self.backImageView removeFromSuperview];
    self.backImageView = nil;
}

// centerForPlayer: and angleForPlayer: include randomization to add realism to the placement (point and angle) of each card in a stack

- (CGPoint)centerForPlayer:(Player *)player
{
    CGRect rect = self.superview.bounds;
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    CGFloat x = -3.0f + RANDOM_INT(6) + CardWidth / 2.0f;
    CGFloat y = -3.0f + RANDOM_INT(6) + CardHeight / 2.0f;
    
    if (self.card.isTurnedOver) {
        switch (player.position) {
            case PlayerPositionBottom:
                x += midX + 7.0f;
                y += maxY - CardHeight - 30.0f;
                break;
                
            case PlayerPositionLeft:
                x += 31.0f;
                y += midY - 30.0f;
                break;
                
            case PlayerPositionTop:
                x += midX - CardWidth - 7.0f;
                y += 29.0f;
                break;
                
            case PlayerPositionRight:
                x += maxX - CardHeight + 1.0f;
                y += midY - CardWidth - 45.0f;
                break;
                
            default:
                break;
        }
    } else { // Card is not turned over
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
