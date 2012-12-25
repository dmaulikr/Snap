//
//  PacketDealCards.h
//  Snap
//
//  Created by Scott Gardner on 12/25/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Packet.h"

@interface PacketDealCards : Packet

@property (nonatomic, copy) NSDictionary *cards;
@property (nonatomic, copy) NSString *startingPeerID;

+ (id)packetWithCards:(NSDictionary *)cards startingWithPlayerPeerID:(NSString *)playerPeerID;

@end
