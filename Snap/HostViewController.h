//
//  HostViewController.h
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

@class HostViewController;

@protocol HostViewControllerDelegate <NSObject>
- (void)hostViewControllerDidCancel:(HostViewController *)controller;
- (void)hostViewController:(HostViewController *)controller startGameWithSession:(GKSession *)session playerName:(NSString *)name clients:(NSArray *)clients;
- (void)hostViewController:(HostViewController *)controller didEndSessionWithReason:(QuitReason)reason;
@end

@interface HostViewController : UIViewController

@property (nonatomic, weak) id <HostViewControllerDelegate> delegate;

@end
