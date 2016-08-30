//
//  MTSystem.h
//  SwizzleDemo
//
//  Created by Gang.Wang on 6/4/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LetapmSystem : NSObject

+ (NSString*) getDeviceVersion;
+ (NSString*) getDeviceCode;

+ (NSString *) platformString;

+ (NSString *) iosVersion;

+ (NSString *) deviceModel;

+ (NSString *) systemName;

+ (NSString *) VersionValue;
+ (NSString *) BuildValue;

+ (NSString *) projectName;

+ (NSString *) boundId;

@end
