//
//  HostViewController.h
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HostViewController;

@protocol HostViewControllerDelegate <NSObject>
- (void)hostViewControllerDidCancel:(HostViewController *)controller;
@end

@interface HostViewController : UIViewController

@property (nonatomic, weak) id <HostViewControllerDelegate> delegate;

@end
