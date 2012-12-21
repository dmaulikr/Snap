//
//  PacketOtherClientQuit.m
//  Snap
//
//  Created by Scott Gardner on 12/20/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketOtherClientQuit.h"

@implementation PacketOtherClientQuit

+ (id)packetWithPeerID:(NSString *)peerID
{
    return [[[self class] alloc] initWithPeerID:peerID];
}

+ (id)packetWithData:(NSData *)data
{
    size_t offset = PACKET_HEADER_SIZE;
    size_t count;
    NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
    return [[self class] packetWithPeerID:peerID];
}

#pragma mark - Private methods

- (id)initWithPeerID:(NSString *)peerID
{
    if (self = [super initWithType:PacketTypeOtherClientQuit]) {
        _peerID = peerID;
    }
    
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.peerID];
}

@end
