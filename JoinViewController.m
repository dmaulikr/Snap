//
//  JoinViewController.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "JoinViewController.h"

@interface JoinViewController ()
@property (nonatomic, weak) IBOutlet UILabel *headingLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *waitLabel;

// strong because top-level additional view in xib; not necessary for first view because it is retained via self.view
@property (nonatomic, strong) IBOutlet UIView *waitView;
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
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
