//
//  MtNSURLSessionSwizzle.h
//  Letapm
//
//  Created by Gang.Wang on 12/28/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//


/*
 @interface _AFURLSessionTaskSwizzling : NSObject
 
 @end
 
 @implementation _AFURLSessionTaskSwizzling
 
 + (void)load {
 关掉此方法
 */

#import <Foundation/Foundation.h>

#import "MtRequestState.h"

@interface MtNSURLSessionSwizzle : NSObject

+ (void)setEnabled:(BOOL)enabled;
+ (BOOL)isEnabled;

@end


