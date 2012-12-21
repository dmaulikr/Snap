//
//  PacketSignInResponse.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketSignInResponse.h"

@implementation PacketSignInResponse

+ (id)packetWithPlayerName:(NSString *)name
{
    return [[[self class] alloc] initWithPlayerName:name];
}

+ (id)packetWithData:(NSData *)data
{
    size_t count;
    NSString *playerName = [data rw_stringAtOffset:PACKET_HEADER_SIZE bytesRead:&count];
    return [[self class] packetWithPlayerName:playerName];
}

#pragma mark - Private methods

- (id)initWithPlayerName:(NSString *)name
{
    if (self = [super initWithType:PacketTypeSignInResponse]) {
        _playerName = name;
    }
    
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.playerName];
}

@end
