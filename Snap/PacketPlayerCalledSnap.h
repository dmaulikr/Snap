//
//  PacketPlayerCalledSnap.h
//  Snap
//
//  Created by Scott Gardner on 12/27/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "Packet.h"

@interface PacketPlayerCalledSnap : Packet

@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, assign) SnapType snapType;
@property (nonatomic, copy) NSSet *matchingPeerIDs;

+ (id)packetWithPeerID:(NSString *)peerID snapType:(SnapType)snapType matchingPeerIDs:(NSSet *)matchingPeerIDs;

@end
