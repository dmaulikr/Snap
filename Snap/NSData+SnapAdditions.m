//
//  NSData+SnapAdditions.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "NSData+SnapAdditions.h"

@implementation NSData (SnapAdditions)

@end

@implementation NSMutableData (SnapAdditions)

/*
 About htons() and htonl():
 These functions are called on value to ensure it is always transmitted in "network byte order," which happens
 to be big endian. However, the current processors are x86 and ARM CPUs which use little endian. We could send
 value as-is, but what if a new model iPhone comes out that uses a different byte ordering, and then the byte
 ordering one device sends to another could be different and thus incompatible? To plan ahead for this
 possibility, we decide on one specific byte ordering: big endian (ideal for network programming).
 
 int value = 0x11223344
 
 [11][22][33][44]   [44][33][22][11]
 Big endian         Little endian
 (network order)
 */

- (void)rw_appendInt8:(char)value
{
    [self appendBytes:&value length:1];
}

- (void)rw_appendInt16:(short)value
{
    value = htons(value);
    [self appendBytes:&value length:2];
}

- (void)rw_appendInt32:(int)value
{
    value = htonl(value);
    [self appendBytes:&value length:4];
}

- (void)rw_appendString:(NSString *)string
{
    const char *cString = [string UTF8String];
    [self appendBytes:cString length:strlen(cString) + 1]; // +1 for UTF8String's nill-termination byte
}

@end
