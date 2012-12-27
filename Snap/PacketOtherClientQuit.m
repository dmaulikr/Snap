//
//  PacketOtherClientQuit.m
//  Snap
//
//  Created by Scott Gardner on 12/20/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketOtherClientQuit.h"

@implementation PacketOtherClientQuit

+ (id)packetWithPeerID:(NSString *)peerID cards:(NSDictionary *)cards
{
    return [[self alloc] initWithPeerID:peerID cards:cards];
}

+ (id)packetWithData:(NSData *)data
{
    size_t offset = PACKET_HEADER_SIZE;
    size_t count;
    NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    NSDictionary *cards = [self cardsFromData:data atOffset:offset];
    return [self packetWithPeerID:peerID cards:cards];
}

#pragma mark - Private methods

- (id)initWithPeerID:(NSString *)peerID cards:(NSDictionary *)cards
{
    if (self = [super initWithType:PacketTypeOtherClientQuit]) {
        _peerID = peerID;
        _cards = cards;
    }
    
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.peerID];
    [self addCards:self.cards toPayload:data];
}

@end
