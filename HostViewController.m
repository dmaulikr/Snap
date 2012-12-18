//
//  HostViewController.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "HostViewController.h"
#import "MatchmakingServer.h"

@interface HostViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UILabel *headingLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *startButton;

@property (nonatomic, strong) MatchmakingServer *matchmakingServer;
@end

@implementation HostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.headingLabel.font = [UIFont rw_snapFontWithSize:24.0f];
    self.nameLabel.font = [UIFont rw_snapFontWithSize:16.0f];
    self.nameTextField.font = [UIFont rw_snapFontWithSize:20.0f];
    self.statusLabel.font = [UIFont rw_snapFontWithSize:16.0f];
    [self.startButton rw_applySnapStyle];
    [self rw_addHideKeyboardGestureRecognizerWithTarget:self.nameTextField];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.matchmakingServer) {
        self.matchmakingServer = [MatchmakingServer new];
        self.matchmakingServer.maxClients = 3;
        [self.matchmakingServer startAcceptingConnectionsForSessionID:SESSION_ID];
        self.nameTextField.placeholder = self.matchmakingServer.session.displayName;
        [self.tableView reloadData];
    }
}

- (void)dealloc
{
    #ifdef DEBUG
    NSLog(@"dealloc %@", self);
    #endif
}

#pragma mark - IBActions

- (IBAction)startAction:(id)sender
{
    
}

- (IBAction)exitAction:(id)sender
{
    [self.delegate hostViewControllerDidCancel:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
