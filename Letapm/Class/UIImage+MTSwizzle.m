//
//  UIImage+MTSwizzle.m
//  SwizzleDemo
//
//  Created by Gang.Wang on 6/5/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "UIImage+MTSwizzle.h"

#import <mach/mach_time.h>
#import "LetapmCore.h"

#import "NSObject+MTSwizzle.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"
#import "MetricLogic.h"

@implementation UIImage (MTSwizzle)
//
//+(void)load
//{
////    return;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [self swizzleClassMethodMt:[self class] withOrig:@selector(imageNamed:) withSEL:@selector(mtSwizzle_imageNamed:)];
//        
//        [self swizzleClassMethodMt:[self class] withOrig:@selector(imageWithContentsOfFile:) withSEL:@selector(mtSwizzle_imageWithContentsOfFile:)];
//        
//    });
//}

//+ (BOOL) UninstallMTSwizzle
//{
//    [UIViewController swizzleSelectorMT:@selector(mtSwizzle_imageNamed:) withSEL:@selector(imageNamed:)];
//    return YES;
//}
//

+ (nullable UIImage *) mtSwizzle_imageWithContentsOfFile:(NSString *)path
{
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name_uuid = [[MetricLogic sharedManager] gen_a_uuid];
    if (name_uuid != nil &&
        [name_uuid length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name_uuid withArray:&array];
    }
    
    if ([LetapmDataDefault sharedManager].DelayMethod)
    {
        [LetapmDataDefault delayMethodAdded];
    }
    
    
    UIImage * ret = [self mtSwizzle_imageWithContentsOfFile:path];
    
    if (name_uuid != nil &&
        [name_uuid length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name_uuid];
    }
    
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    LetAPMLOG(@"[UIImage imageWithContentsOfFile:%@] CASTTIME:%f %d", path, cast, (int)[array count]);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array]
                                setMethodName:@"imageWithContentsOfFile"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread] ]
                            setParams:path ]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
    
    return ret;
}

+ (UIImage *) mtSwizzle_imageNamed:(NSString *)name {
    
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name_uuid = [[MetricLogic sharedManager] gen_a_uuid];
    if (name_uuid != nil &&
        [name_uuid length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name_uuid withArray:&array];
    }
    
    
    if ([LetapmDataDefault sharedManager].DelayMethod)
    {
        [LetapmDataDefault delayMethodAdded];
    }
    
    UIImage * ret = [self mtSwizzle_imageNamed:name];
    
    if (name_uuid != nil &&
        [name_uuid length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name_uuid];
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    LetAPMLOG(@"[UIImage imageNamed:%@] CASTTIME:%lf %d", name, cast, (int)[array count]);
    
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array]
                                setMethodName:@"imageNamed"] setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread] ]
                            setParams:name ]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
    
    return ret;
}


@end
