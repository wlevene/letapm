//
//  BatCore.h
//  SwizzleDemo
//
//  Created by Gang.Wang on 5/28/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Cmd.pb.h"

@interface LetapmCore : NSObject

- (void) initWithAppKey:(NSString *) appKey withAppSecret:(NSString *) appSecret;

+ (LetapmCore *)sharedManager;

- (void) sendProtocolWithCmd:(CmdType) cmd withCmdData:(NSData *) cmdData;
- (void) sendData:(NSData *) cmdData;

@end
