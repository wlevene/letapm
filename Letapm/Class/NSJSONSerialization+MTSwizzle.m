//
//  NSJSONSerialization+MTSwizzle.m
//  Letapm
//
//  Created by Gang.Wang on 10/8/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "NSJSONSerialization+MTSwizzle.h"

#import <mach/mach_time.h>
#import "LetapmCore.h"

#import "NSObject+MTSwizzle.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"
#import "MetricLogic.h"

@implementation NSJSONSerialization (MTSwizzle)

+ (void) load
{
    return;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [self swizzleClassMethodMt:[self class] withOrig:@selector(JSONObjectWithData:options:error:) withSEL:@selector(mtSwizzle_JSONObjectWithData:options:error:)];
//    });
}

//+ (BOOL) UninstallMTSwizzle
//{
//    [NSJSONSerialization swizzleSelectorMT:@selector(mtSwizzle_JSONObjectWithData:options:error:) withSEL:@selector(JSONObjectWithData:options:error:)];
//    return YES;
//}
//

+ (nullable id) mtSwizzle_JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error
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
    
    id ret = [self mtSwizzle_JSONObjectWithData:data options:opt error:error];
    
    if (name_uuid != nil &&
        [name_uuid length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name_uuid];
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    LetAPMLOG(@"[NSJSONSerialization JSONObjectWithData] CASTTIME:%f", cast);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array]
                                setMethodName:@"JSONObjectWithData"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread] ]
                            setParams:[[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding] ]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
    
    return ret;
}


@end
