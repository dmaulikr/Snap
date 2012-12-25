//
//  PacketDealCards.m
//  Snap
//
//  Created by Scott Gardner on 12/25/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketDealCards.h"

@implementation PacketDealCards

+ (id)packetWithCards:(NSDictionary *)cards startingWithPlayerPeerID:(NSString *)playerPeerID
{
    return [[[self class] alloc] initWithCards:cards startingWithPlayerPeerID:playerPeerID];
}

#pragma mark - Private methods

+ (id)packetWithData:(NSData *)data
{
    size_t offset = PACKET_HEADER_SIZE;
    size_t count;
    NSString *startingPeerID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    NSDictionary *cards = [[self class] cardsFromData:data atOffset:offset];
    return  [[self class] packetWithCards:cards startingWithPlayerPeerID:startingPeerID];
}

- (id)initWithCards:(NSDictionary *)cards startingWithPlayerPeerID:(NSString *)playerPeerID
{
    if (self = [super initWithType:PacketTypeDealCards]) {
        _cards = cards;
        _startingPeerID = playerPeerID;
    }
    
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.startingPeerID];
    [self addCards:self.cards toPayload:data];
}



@end
