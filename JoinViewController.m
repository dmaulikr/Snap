//
//  JoinViewController.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import "JoinViewController.h"
#import "MatchmakingClient.h"
#import "PeerCell.h"

@interface JoinViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, MatchmakingClientDelegate>
@property (nonatomic, weak) IBOutlet UILabel *headingLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *waitLabel;

// This outlet property is marked strong because it is a top-level additional view in xib; this is not necessary for the first view because it is retained via self.view
@property (nonatomic, strong) IBOutlet UIView *waitView;

@property (nonatomic, strong) MatchmakingClient *matchmakingClient;
@property (nonatomic, assign) QuitReason quitReason;
@end

@implementation JoinViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.headingLabel.font = [UIFont rw_snapFontWithSize:24.0f];
    self.nameLabel.font = [UIFont rw_snapFontWithSize:16.0f];
    self.nameTextField.font = [UIFont rw_snapFontWithSize:20.0f];
    self.statusLabel.font = [UIFont rw_snapFontWithSize:16.0f];
    self.waitLabel.font = [UIFont rw_snapFontWithSize:18.0f];
    [self rw_addHideKeyboardGestureRecognizerWithTarget:self.nameTextField];
    [self.tableView registerClass:[PeerCell class] forCellReuseIdentifier:@"PeerCell"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.matchmakingClient) {
        self.quitReason = QuitReasonConnectionDropped;
        self.matchmakingClient = [MatchmakingClient new];
        self.matchmakingClient.delegate = self;
        [self.matchmakingClient startSearchingForServersWithSessionID:SESSION_ID];
        self.nameTextField.placeholder = self.matchmakingClient.session.displayName;
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

- (IBAction)exitAction:(id)sender
{
    self.quitReason = QuitReasonUserQuit;
    [self.matchmakingClient disconnectFromServer];
    [self.delegate joinViewControllerDidCancel:self];
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
    if (self.matchmakingClient) {
        return [self.matchmakingClient.availableServers count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell"];
    NSString *peerID = self.matchmakingClient.availableServers[indexPath.row];
    cell.textLabel.text = [self.matchmakingClient.session displayNameForPeer:peerID];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.matchmakingClient) {
        [self.view addSubview:self.waitView];
        NSString *peerID = self.matchmakingClient.availableServers[indexPath.row];
        [self.matchmakingClient connectToServerWithPeerID:peerID];
    }
}

#pragma mark - MatchmakingClientDelegate

- (void)matchmakingClient:(MatchmakingClient *)client serverBecameAvailable:(NSString *)peerID
{
    [self.tableView reloadData];
}

- (void)matchmakingClient:(MatchmakingClient *)client serverBecameUnavailable:(NSString *)peerID
{
    [self.tableView reloadData];
}

- (void)matchmakingClient:(MatchmakingClient *)client didDisconnectFromServer:(NSString *)peerID
{
    self.matchmakingClient.delegate = nil;
    self.matchmakingClient = nil;
    [self.tableView reloadData];
    [self.delegate joinViewController:self didDisconnectWithReason:self.quitReason];
}

- (void)matchmakingClientNoNetwork:(MatchmakingClient *)client
{
    self.quitReason = QuitReasonNoNetwork;
}

@end
