//
//  Player.h
//  Snap
//
//  Created by Scott Gardner on 12/19/12.
//  Copyright (c) 2012 inyago LLC. All rights reserved.
//

typedef enum {
    PlayerPositionBottom, // The user
    PlayerPositionLeft,
    PlayerPositionTop,
    PlayerPositionRight
} PlayerPosition;

@interface Player : NSObject

@property (nonatomic, assign) PlayerPosition position;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *peerID;
@property (nonatomic, assign) int gamesWon;

@property (nonatomic, assign) BOOL receivedResponse;

@end
