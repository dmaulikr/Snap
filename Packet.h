//
//  Packet.h
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

/*
 All messages have the following format:
 [S][N][A][P]   [0][0][0][0]    [0][0]          ...
 4-byte header  4-byte packet   2-byte packet   Other data
 0x534E4150     number          type            (payload)
 
 'SNAP' is a four-character code, aka "fourcc"
 */

#import <Foundation/Foundation.h>

typedef enum {
    PacketTypeSignInRequest = 0x64, // Server to client
    PacketTypeSignInResponse,       // Client to server
    
    PacketTypeServerReady,          // Server to client
    PacketTypeClientReady,          // Client to server
    
    PacketTypeDealCards,           // Server to client
    PacketTypeClientDealtCards,     // Client to server
    
    PacketTypeActivatePlayer,       // Server to client
    PacketTypeClientTurnedCard,     // Client to server
    
    PacketTypePlayerShouldSnap,     // Client to server
    PacketTypePlayerCalledSnap,     // Server to client
    
    PacketTypeOtherClientQuit,      // Server to client
    PacketTypeServerQuit,           // Server to client
    PacketTypeClientQuite           // Client to server
} PacketType;

@interface Packet : NSObject

@property (nonatomic, assign) PacketType packetType;

+ (id)packetWithType:(PacketType)packetType;
+ (id)packetWithData:(NSData *)data;
- (id)initWithType:(PacketType)packetType;
- (NSData *)data;

@end
