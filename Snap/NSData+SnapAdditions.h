//
//  NSData+SnapAdditions.h
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SnapAdditions)

@end

@interface NSMutableData (SnapAdditions)

- (void)rw_appendInt8:(char)value;
- (void)rw_appendInt16:(short)value;
- (void)rw_appendInt32:(int)value;
- (void)rw_appendString:(NSString *)string;

@end
