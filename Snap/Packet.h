//
//  Packet.h
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

/*
 All messages have the following format:
 [S][N][A][P]   [0][0][0][0]    [0][0]          ...
 4-byte header  4-byte packet   2-byte packet   Other data
 0x534E4150     number          type            (payload)
 
 'SNAP' is a four-character code, aka "fourcc"
 */

@interface Packet : NSObject

@property (nonatomic, assign) PacketType packetType;
@property (nonatomic, assign) int packetNumber;
@property (nonatomic, assign) BOOL sendReliably;

+ (id)packetWithType:(PacketType)packetType;
+ (id)packetWithData:(NSData *)data;
+ (NSMutableDictionary *)cardsFromData:(NSData *)data atOffset:(size_t)offset;
- (id)initWithType:(PacketType)packetType;
- (NSData *)data;
- (void)addCards:(NSDictionary *)cards toPayload:(NSMutableData *)data;

@end
