//
//  GameViewController.h
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Game.h"

@class GameViewController;

@protocol GameViewControllerDelegate <NSObject>
- (void)gameViewController:(GameViewController *)controller didQuitWithReason:(QuitReason)reason;
@end

@interface GameViewController : UIViewController <GameDelegate>

@property (nonatomic, weak) id <GameViewControllerDelegate> delegate;
@property (nonatomic, strong) Game *game;

@end
