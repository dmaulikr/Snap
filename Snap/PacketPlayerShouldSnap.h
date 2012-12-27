//
//  PacketPlayerShouldSnap.h
//  Snap
//
//  Created by Scott Gardner on 12/27/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Packet.h"

@interface PacketPlayerShouldSnap : Packet

@property (nonatomic, copy) NSString *peerID;

+ (id)packetWithPeerID:(NSString *)peerID;

@end
