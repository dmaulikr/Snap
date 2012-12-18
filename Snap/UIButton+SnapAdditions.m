//
//  UIButton+SnapAdditions.m
//  Snap
//
//  Created by Scott Gardner on 12/17/12.
//  Copyright (c) 2012 Scott Gardner. All rights reserved.
//

#import "UIButton+SnapAdditions.h"

@implementation UIButton (SnapAdditions)

- (void)rw_applySnapStyle
{
    self.titleLabel.font = [UIFont rw_snapFontWithSize:20.0f];
    UIImage *buttonImage = [[UIImage imageNamed:@"Button"] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    [self setBackgroundImage:buttonImage forState:UIControlStateNormal];
    UIImage *pressedButtonImage = [[UIImage imageNamed:@"ButtonPressed"] stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    [self setBackgroundImage:pressedButtonImage forState:UIControlStateHighlighted];
}

@end
