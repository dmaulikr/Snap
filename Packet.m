//
//  Packet.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "Packet.h"
#import "PacketSignInResponse.h"
#import "NSData+SnapAdditions.h"

const size_t PACKET_HEADER_SIZE = 10;

@implementation Packet

+ (id)packetWithType:(PacketType)packetType
{
    return [[[self class] alloc] initWithType:packetType];
}

+ (id)packetWithData:(NSData *)data
{
    // [data length] returns the number of bytes
    if ([data length] < PACKET_HEADER_SIZE) {
        NSLog(@"Error: packet too small");
        return nil;
    }
    
    if ([data rw_int32AtOffset:0] != 'SNAP') {
        NSLog(@"Error: packet has invalid header");
        return nil;
    }
    
//    int packetNumber = [data rw_int32AtOffset:4]; // For future use
    PacketType packetType = [data rw_int16AtOffset:8];
    Packet *packet;
    
    switch (packetType) {
        case PacketTypeSignInRequest:
            packet = [Packet packetWithType:packetType];
            break;
            
        case PacketTypeSignInResponse:
            packet = [PacketSignInResponse packetWithData:data];
            break;
            
        default:
            NSLog(@"Error: packet has invalid type");
            break;
    }
    
    return packet;
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
    [self addPayloadToData:data];
    return data;
}

#pragma mark - Private methods

- (void)addPayloadToData:(NSMutableData *)data
{
    // Meant for subclass use; base class does nothing
}

@end
