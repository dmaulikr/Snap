//
//  PacketOtherClientQuit.h
//  Snap
//
//  Created by Scott Gardner on 12/20/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Packet.h"

@interface PacketOtherClientQuit : Packet

@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, strong) NSDictionary *cards;

+ (id)packetWithPeerID:(NSString *)peerID cards:(NSDictionary *)cards;

@end
