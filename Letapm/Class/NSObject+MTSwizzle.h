//
//  NSObject+MTSwizzle.h
//  MTSwizzle Probe
//
//  Created by Gang.Wang on 5/27/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MTSwizzle)

+ (BOOL) swizzleSelectorMT:(SEL)origSelector
                 withSEL:(SEL) swizzledSelector;

+ (BOOL) swizzleClassMethodMt:(Class) c  withOrig:(SEL) orig  withSEL:(SEL) newSel;

@end