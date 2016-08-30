//
//  NSObject+MTSwizzle.m
//  MTSwizzle Probe
//
//  Created by Gang.Wang on 5/27/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "NSObject+MTSwizzle.h"
#import <objc/runtime.h>

@implementation NSObject (MTSwizzle)

+ (BOOL) swizzleSelectorMT:(SEL)origSelector
               withSEL:(SEL) swizzledSelector {
    
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, origSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    
    BOOL didAddMethod = class_addMethod(class, origSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod)
    {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod),method_getTypeEncoding(originalMethod));
    }
    else
    {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    return YES;
}


+ (BOOL) swizzleClassMethodMt:(Class) c  withOrig:(SEL) orig  withSEL:(SEL) newSel
{
    
    Method origMethod = class_getClassMethod(c, orig);
    Method newMethod = class_getClassMethod(c, newSel);
    
    c = object_getClass((id)c);
    
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
    return YES;
}

@end
