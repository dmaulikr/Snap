//
//  PacketPlayerShouldSnap.m
//  Snap
//
//  Created by Scott Gardner on 12/27/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketPlayerShouldSnap.h"

@implementation PacketPlayerShouldSnap

// TODO: It is not necessary to send the peer ID because we already know the peer ID of the sender of a message

+ (id)packetWithPeerID:(NSString *)peerID
{
	return [[self alloc] initWithPeerID:peerID];
}

#pragma mark - Private

+ (id)packetWithData:(NSData *)data
{
	size_t count;
	NSString *peerID = [data rw_stringAtOffset:PACKET_HEADER_SIZE bytesRead:&count];
	return [self packetWithPeerID:peerID];
}

- (id)initWithPeerID:(NSString *)peerID
{
	if ((self = [super initWithType:PacketTypePlayerShouldSnap])) {
		self.peerID = peerID;
        self.sendReliably = NO;
	}
    
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendString:self.peerID];
}

@end
