//
//  PacketPlayerCalledSnap.m
//  Snap
//
//  Created by Scott Gardner on 12/27/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

#import "PacketPlayerCalledSnap.h"

@implementation PacketPlayerCalledSnap

+ (id)packetWithPeerID:(NSString *)peerID snapType:(SnapType)snapType matchingPeerIDs:(NSSet *)matchingPeerIDs
{
    return [[self alloc] initWithPeerID:peerID snapType:snapType matchingPeerIDs:matchingPeerIDs];
}

- (id)initWithPeerID:(NSString *)peerID snapType:(SnapType)snapType matchingPeerIDs:(NSSet *)matchingPeerIDs
{
    if (self = [super initWithType:PacketTypePlayerCalledSnap]) {
        _peerID = peerID;
        _snapType = snapType;
        _matchingPeerIDs = matchingPeerIDs;
    }
    
    return self;
}

#pragma mark - Private

+ (id)packetWithData:(NSData *)data
{
    size_t offset = PACKET_HEADER_SIZE;
    size_t count;
    NSString *peerID = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    SnapType snapType = [data rw_int8AtOffset:offset];
    NSMutableSet *matchingPeerIDs = nil;
    
    if (snapType == SnapTypeCorrect) {
        matchingPeerIDs = [NSMutableSet setWithCapacity:4];
        
        while (offset < [data length]) {
            NSString *matchingPeerID = [data rw_stringAtOffset:offset bytesRead:&count];
            offset += count;
            [matchingPeerIDs addObject:matchingPeerID];
        }
    }
    
    return [self packetWithPeerID:peerID snapType:snapType matchingPeerIDs:matchingPeerIDs];
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.peerID];
    [data rw_appendInt8:self.snapType];
    
    [self.matchingPeerIDs enumerateObjectsUsingBlock:^(NSString *peerID, BOOL *stop) {
        [data rw_appendString:peerID];
    }];
}

@end
