//
//  Packet.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"
#import "NSData+SnapAdditions.h"

@implementation Packet

+ (id)packetWithType:(PacketType)packetType
{
    return [[[self class] alloc] initWithType:packetType];
}

- (id)initWithType:(PacketType)packetType
{
    if (self = [super init]) {
        _packetType = packetType;
    }
    
    return self;
}

- (NSData *)data
{
    NSMutableData *data = [NSMutableData dataWithCapacity:100];
    [data rw_appendInt32:'SNAP']; // 0x534E4150
    [data rw_appendInt32:0];
    [data rw_appendInt16:self.packetType];
    return data;
}

@end
