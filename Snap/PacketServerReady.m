//
//  PacketServerReady.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketServerReady.h"
#import "Player.h"

@implementation PacketServerReady

+ (id)packetWithPlayers:(NSMutableDictionary *)players
{
    return [[[self class] alloc] initWithPlayers:players];
}

#pragma mark - Private methods

- (id)initWithPlayers:(NSMutableDictionary *)players
{
    if (self = [super initWithType:PacketTypeServerReady]) {
        _players = players;
    }
    
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendInt8:[self.players count]];
    
    [self.players enumerateKeysAndObjectsUsingBlock:^(id key, Player *player, BOOL *stop) {
        [data rw_appendString:player.peerID];
        [data rw_appendString:player.name];
        [data rw_appendInt8:player.position];
    }];
}

+ (id)packetWithData:(NSData *)data
{
    NSMutableDictionary *players = [NSMutableDictionary dictionaryWithCapacity:4];
    size_t offset = PACKET_HEADER_SIZE;
    size_t count;
    int numberOfPlayers = [data rw_int8AtOffset:offset];
    offset++;
    
    for (int i = 0; i < numberOfPlayers; i++) {
        NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
        offset += count;
        
        NSString *name = [data rw_stringAtOffset:offset bytesRead:&count];
        offset += count;
        
        PlayerPosition position = [data rw_int8AtOffset:offset];
        offset++;
        
        Player *player = [Player new];
        player.peerID = peerID;
        player.name = name;
        player.position = position;
        players[player.peerID] = player;
    }
    
    return [[self class] packetWithPlayers:players];
}

@end
