//
//  NSData+MTSwizzle.m
//  Letapm
//
//  Created by Gang.Wang on 10/8/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "NSData+MTSwizzle.h"

#import <mach/mach_time.h>
#import "LetapmCore.h"

#import "NSObject+MTSwizzle.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"
#import "MetricLogic.h"

@implementation NSData (MTSwizzle)

+(void)load
{
    return;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [self swizzleSelectorMT:@selector(initWithContentsOfFile:) withSEL:@selector(mtSwizzle_initWithContentsOfFile:)];
////        [self swizzleSelectorMT:@selector(initWithContentsOfURL:) withSEL:@selector(mtSwizzle_initWithContentsOfURL:)];
//    });
}


//+ (BOOL) UninstallMTSwizzle
//{
//    [self swizzleSelectorMT:@selector(mtSwizzle_initWithNibName:bundle:) withSEL:@selector(initWithNibName:bundle:)];
//    [self swizzleSelectorMT:@selector(mtSwizzle_initWithCoder:) withSEL:@selector(initWithCoder:)];
//    
//    return YES;
//}
- (nullable instancetype)mtSwizzle_initWithContentsOfURL:(NSURL *)url
{
    
    if (url &&
        ![url isFileURL])
    {
        return [self mtSwizzle_initWithContentsOfURL:url];
    }
    
    
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
    
    id ret = [self mtSwizzle_initWithContentsOfURL:url];
    
    if (name_uuid != nil &&
        [name_uuid length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name_uuid];
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    
    NSString * filePath = [NSString stringWithFormat:@"%@", url];
   
    LetAPMLOG(@"[NSData initWithContentsOfURL] %@ CASTTIME:%f", filePath, cast);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array]
                                setMethodName:@"initWithContentsOfURL"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread] ]
                            setParams:filePath]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
    
    return ret;
}

- (nullable instancetype)mtSwizzle_initWithContentsOfFile:(NSString *)path
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
    
    id ret = [self mtSwizzle_initWithContentsOfFile:path];
    
    if (name_uuid != nil &&
        [name_uuid length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name_uuid];
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    LetAPMLOG(@"[NSData initWithContentsOfFile] %@ CASTTIME:%f", path, cast);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array]
                                setMethodName:@"initWithContentsOfFile"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread] ]
                            setParams:path]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
    
    return ret;
}

@end
