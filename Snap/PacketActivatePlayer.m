//
//  PacketActivatePlayer.m
//  Snap
//
//  Created by Scott Gardner on 12/26/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketActivatePlayer.h"

@implementation PacketActivatePlayer

+ (id)packetWithPeerID:(NSString *)peerID
{
    return [[self alloc] initWithPeerID:peerID];
}

+ (id)packetWithData:(NSData *)data
{
    size_t count;
    NSString *peerID = [data rw_stringAtOffset:PACKET_HEADER_SIZE bytesRead:&count];
    return [self packetWithPeerID:peerID];
}

#pragma mark - Private methods

- (id)initWithPeerID:(NSString *)peerID
{
    if (self = [super initWithType:PacketTypeActivatePlayer]) {
        self.packetNumber = 0; // Enable packet numbers for this packet type
        _peerID = peerID;
    }
    
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.peerID];
}

@end
