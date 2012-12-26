//
//  Packet.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Packet.h"
#import "PacketSignInResponse.h"
#import "PacketServerReady.h"
#import "PacketActivatePlayer.h"
#import "PacketOtherClientQuit.h"
#import "PacketDealCards.h"
#import "Card.h"

@implementation Packet

+ (id)packetWithType:(PacketType)packetType
{
    return [[self alloc] initWithType:packetType];
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
        case PacketTypeClientReady:
        case PacketTypeClientDealtCards:
        case PacketTypeServerQuit:
        case PacketTypeClientQuit:
            packet = [Packet packetWithType:packetType];
            break;
            
        case PacketTypeSignInResponse:
            packet = [PacketSignInResponse packetWithData:data];
            break;
            
        case PacketTypeServerReady:
            packet = [PacketServerReady packetWithData:data];
            break;
            
        case PacketTypeDealCards:
            packet = [PacketDealCards packetWithData:data];
            break;
            
        case PacketTypeActivatePlayer:
            packet = [PacketActivatePlayer packetWithData:data];
            break;
            
        case PacketTypeOtherClientQuit:
            packet = [PacketOtherClientQuit packetWithData:data];
            break;
            
        default:
            NSLog(@"Error: packet has invalid type");
            break;
    }
    
    return packet;
}

+ (NSDictionary *)cardsFromData:(NSData *)data atOffset:(size_t)offset
{
    size_t count;
    NSMutableDictionary *cards = [NSMutableDictionary dictionaryWithCapacity:4];
    
    while (offset < [data length]) {
        NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
        offset += count;
        int numberOfCards = [data rw_int8AtOffset:offset];
        offset++;
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:numberOfCards];
        
        for (int i = 0; i < numberOfCards; i++) {
            int suit = [data rw_int8AtOffset:offset];
            offset++;
            int value = [data rw_int8AtOffset:offset];
            offset++;
            Card *card = [[Card alloc] initWithSuit:suit value:value];
            array[i] = card;
        }
        
        cards[peerID] = array;
    }
    
    return cards;
}

- (id)initWithType:(PacketType)packetType
{
    if (self = [super init]) {
        _packetType = packetType;
    }
    
    return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, type = %d", [super description], self.packetType];
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

- (void)addCards:(NSDictionary *)cards toPayload:(NSMutableData *)data
{
    [cards enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *array, BOOL *stop) {
        int arrayCount = [array count];
        [data rw_appendString:key];
        [data rw_appendInt8:arrayCount];
        
        for (int i = 0; i < arrayCount; i++) {
            Card *card = array[i];
            [data rw_appendInt8:card.suit];
            [data rw_appendInt8:card.value];
        }
    }];
}

#pragma mark - Private methods

- (void)addPayloadToData:(NSMutableData *)data
{
    // Meant for subclass use; base class does nothing
}

@end
