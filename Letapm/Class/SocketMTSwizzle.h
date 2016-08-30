//
//  SocketMTSwizzle.h
//  SwizzleDemo
//
//  Created by Gang.Wang on 5/30/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketMTSwizzle : NSObject

@end


@interface MTRemoteAddr : NSObject

@property (nonatomic, retain) NSString * remoteIP;
@property (nonatomic, assign) int32_t port;

@end