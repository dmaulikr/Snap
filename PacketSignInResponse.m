//
//  PacketSignInResponse.m
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 Hollance. All rights reserved.
//

#import "PacketSignInResponse.h"
#import "NSData+SnapAdditions.h"

@implementation PacketSignInResponse

+ (id)packetWithPlayerName:(NSString *)name
{
    return [[[self class] alloc] initWithPlayerName:name];
}

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
