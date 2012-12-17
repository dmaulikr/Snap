//
//  UIViewController+SnapAdditions.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "UIViewController+SnapAdditions.h"

@implementation UIViewController (SnapAdditions)

- (void)rw_addHideKeyboardGestureRecognizerWithTarget:(UITextField *)textField
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:textField action:@selector(resignFirstResponder)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
}

@end
