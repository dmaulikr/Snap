//
//  JoinViewController.h
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JoinViewController;

@protocol JoinViewControllerDelegate <NSObject>
- (void)joinViewControllerDidCancel:(JoinViewController *)controller;
@end

@interface JoinViewController : UIViewController

@property (nonatomic, weak) id <JoinViewControllerDelegate> delegate;

@end
