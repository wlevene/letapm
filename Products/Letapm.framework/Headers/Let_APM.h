//
//  LetAPM.h
//  Letapm
//
//  Created by Gang.Wang on 8/25/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LetAPM : NSObject

/*
 @brief:通过appKey初始化
 */
+(void) initWithAppKey:(NSString *) appKey withAppSecret:(NSString *) appSecret;

+ (void) showLog:(BOOL) showlog;

@end
