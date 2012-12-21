//
//  HostViewController.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import "HostViewController.h"
#import "MatchmakingServer.h"
#import "PeerCell.h"

@interface HostViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, MatchmakingServerDelegate>
@property (nonatomic, weak) IBOutlet UILabel *headingLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *startButton;

@property (nonatomic, strong) MatchmakingServer *matchmakingServer;
@property (nonatomic, assign) QuitReason quitReason;
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
    [self.tableView registerClass:[PeerCell class] forCellReuseIdentifier:@"PeerCell"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.matchmakingServer) {
        self.matchmakingServer = [MatchmakingServer new];
        self.matchmakingServer.delegate = self;
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
    if (self.matchmakingServer && [self.matchmakingServer.connectedClients count]) {
        NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([name length] == 0) {
            name = self.matchmakingServer.session.displayName;
            [self.matchmakingServer stopAcceptingConnections];
            [self.delegate hostViewController:self startGameWithSession:self.matchmakingServer.session playerName:name clients:self.matchmakingServer.connectedClients];
        }
    }
}

- (IBAction)exitAction:(id)sender
{
    self.quitReason = QuitReasonUserQuit;
    [self.matchmakingServer endSession];
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
    if (self.matchmakingServer) {
        return [self.matchmakingServer.connectedClients count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell"];
    NSString *peerID = self.matchmakingServer.connectedClients[indexPath.row];
    cell.textLabel.text = [self.matchmakingServer.session displayNameForPeer:peerID];
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - MatchmakingServerDelegate

- (void)matchmakingServer:(MatchmakingServer *)server clientDidConnect:(NSString *)peerID
{
    [self.tableView reloadData];
}

- (void)matchmakingServer:(MatchmakingServer *)server clientDidDisconnect:(NSString *)peerID
{
    [self.tableView reloadData];
}

- (void)matchmakingServerNoNetwork:(MatchmakingServer *)server
{
    self.quitReason = QuitReasonNoNetwork;
}

- (void)matchmakingServerSessionDidEnd:(MatchmakingServer *)server
{
    self.matchmakingServer.delegate = nil;
    self.matchmakingServer = nil;
    [self.tableView reloadData];
    [self.delegate hostViewController:self didEndSessionWithReason:self.quitReason];
}

@end
