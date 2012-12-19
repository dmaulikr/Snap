//
//  JoinViewController.h
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JoinViewController;

@protocol JoinViewControllerDelegate <NSObject>
- (void)joinViewControllerDidCancel:(JoinViewController *)controller;
- (void)joinViewController:(JoinViewController *)controller startGameWithSession:(GKSession *)session playerName:(NSString *)name server:(NSString *)peerID;
- (void)joinViewController:(JoinViewController *)controller didDisconnectWithReason:(QuitReason)reason;
@end

@interface JoinViewController : UIViewController

@property (nonatomic, weak) id <JoinViewControllerDelegate> delegate;

@end
