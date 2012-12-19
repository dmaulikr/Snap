//
//  GameViewController.m
//  Snap
//
//  Created by Scott Gardner on 12/18/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "GameViewController.h"

@interface GameViewController () <UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *centerLabel;
@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.centerLabel.font = [UIFont rw_snapFontWithSize:18.0f];
}

- (void)dealloc
{
    #ifdef DEBUG
    NSLog(@"dealloc %@", self);
    #endif
}

#pragma mark - IBActions

- (IBAction)exitAction:(id)sender
{
    [self.game quitGameWithReason:QuitReasonUserQuit];
}

#pragma mark - GameDelegate

- (void)game:(Game *)game didQuitWithReason:(QuitReason)reason
{
    [self.delegate gameViewController:self didQuitWithReason:reason];
}

- (void)gameWaitingForServerReady:(Game *)game
{
    self.centerLabel.text = @"Waiting for game to start...";
}

- (void)gameWaitingForClientsReady:(Game *)game
{
    self.centerLabel.text = @"Waiting for other players...";
}

@end
