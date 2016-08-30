//
//  UIViewController+MtSwizzleEx.m
//  Letapm
//
//  Created by Gang.Wang on 10/6/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "UIViewController+MtSwizzleEx.h"

#import "MtJRSwizzle.h"

#import <mach/mach_time.h>
#import "LetapmCore.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"
#import "MetricLogic.h"

#import "NSObject+MTSwizzle.h"

@implementation UIViewController (MtSwizzleEx)


+(void)load
{
//    return;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        /*
//         init方法不需要添加，添加initWithNibName:bundle:的处理后init方法也包括
//         
//         initWithCoder: 处理后有bug, 处理后会导致viewDidload方法没有正确调用，先关掉此方法
//         */
//        [self swizzleSelectorMT:@selector(initWithNibName:bundle:) withSEL:@selector(mtSwizzle_initWithNibName:bundle:)];
////        [self swizzleSelectorMT:@selector(initWithCoder:) withSEL:@selector(mtSwizzle_initWithCoder:)];
//        
//             [self swizzleSelectorMT:@selector(init) withSEL:@selector(mtSwizzle_init)];
//        
//    });
}



+ (BOOL) UninstallMTSwizzle
{
    [self swizzleSelectorMT:@selector(mtSwizzle_initWithNibName:bundle:) withSEL:@selector(initWithNibName:bundle:)];
//    [self swizzleSelectorMT:@selector(mtSwizzle_initWithCoder:) withSEL:@selector(initWithCoder:)];
    
    return YES;
}

-(instancetype) mtSwizzle_init
{
    id ret = [self mtSwizzle_init];
    
    Class class = [self class];
    
    [self mtSwizzleUIViewController:class];
    
    return ret;
}


-(instancetype) mtSwizzle_initWithCoder:(NSCoder *)aDecoder
{
    id ret = [self mtSwizzle_initWithCoder:aDecoder];
    
    Class class = [self class];
    
    [self mtSwizzleUIViewController:class];
    
    return ret;
}


- (instancetype) mtSwizzle_initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    id ret = [self mtSwizzle_initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    Class class = [self class];
    
    [self mtSwizzleUIViewController:class];
    
    return ret;
}


- (void) mtSwizzleUIViewController:(Class) targClass
{
    [targClass swizzleSelectorMT:@selector(viewDidLoad)
                         withSEL:@selector(mtSwizzle_viewDidLoad)];
    
    [targClass swizzleSelectorMT:@selector(viewWillAppear:)
                         withSEL:@selector(mtSwizzle_viewWillAppear:)];
    
    [targClass swizzleSelectorMT:@selector(viewDidAppear:)
                         withSEL:@selector(mtSwizzle_viewDidAppear:)];

    [targClass swizzleSelectorMT:@selector(viewWillLayoutSubviews)
                         withSEL:@selector(mtSwizzle_viewWillLayoutSubviews)];
    
    [targClass swizzleSelectorMT:@selector(viewDidLayoutSubviews)
                         withSEL:@selector(mtSwizzle_viewDidLayoutSubviews)];
    
    // [self swizzleSelectorMT:@selector(mtSwizzle_didReceiveMemoryWarning) withSEL:@selector(didReceiveMemoryWarning)];
}

- (void) mtSwizzle_viewDidLoad
{
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name = [[MetricLogic sharedManager] gen_a_uuid];
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name withArray:&array];
    }
    
    if ([LetapmDataDefault sharedManager].DelayMethod)
    {
        [LetapmDataDefault delayMethodAdded];
    }
    
    [self mtSwizzle_viewDidLoad];
    
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name];
        
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
 
    LetAPMLOG(@"[%@:%@] CASTTIME:%f, %d", [self class], @"viewDidLoad", cast, (int)[array count]);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] setMethodName:@"viewDidLoad"]
                                setClassName:className]
                               setCastTime:cast]
                              setIsMainThread:[NSThread isMainThread]]
                             setParams:nil]
                            addAllMetricDatas:array ]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData withCmdData:[method data]];
    
}

- (void) mtSwizzle_viewWillAppear:(BOOL)animated
{
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name = [[MetricLogic sharedManager] gen_a_uuid];
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name withArray:&array];
    }
    
    [self mtSwizzle_viewWillAppear:animated];
    
    
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name];
        
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    LetAPMLOG(@"[%@:%@] CASTTIME:%f, %d", [self class], @"viewWillAppear", cast, (int)[array count]);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array ]
                                setMethodName:@"viewWillAppear"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread]]
                            setParams:[NSString stringWithFormat:@"%d", animated]]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
    
}

- (void) mtSwizzle_viewDidAppear:(BOOL)animated
{
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name = [[MetricLogic sharedManager] gen_a_uuid];
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name withArray:&array];
    }
    
    if ([LetapmDataDefault sharedManager].DelayMethod)
    {
        [LetapmDataDefault delayMethodAdded];
    }
    
    [self mtSwizzle_viewDidAppear:animated];
    
    
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name];
        
    }
    
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
 
    LetAPMLOG(@"[%@:%@] CASTTIME:%f, %d", [self class], @"viewDidAppear", cast, (int)[array count]);

    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array ]
                                setMethodName:@"viewDidAppear"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread]]
                            setParams:[NSString stringWithFormat:@"%d", animated]]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
    
}


- (void)mtSwizzle_loadView {
    
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name = [[MetricLogic sharedManager] gen_a_uuid];
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name withArray:&array];
    }
    
    [self mtSwizzle_loadView];
    
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name];
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    LetAPMLOG(@"[%@:%@] CASTTIME:%f, %d", [self class], @"loadView", cast, (int)[array count]);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] setMethodName:@"loadView"]
                                setClassName:className]
                               setCastTime:cast]
                              setIsMainThread:[NSThread isMainThread]]
                             setParams:nil]
                            addAllMetricDatas:array ]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
}

- (void) mtSwizzle_viewWillLayoutSubviews
{
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name = [[MetricLogic sharedManager] gen_a_uuid];
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name withArray:&array];
    }
    
    
    [self mtSwizzle_viewWillLayoutSubviews];
    
    
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name];
        
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    LetAPMLOG(@"[%@:%@] CASTTIME:%f, %d", [self class], @"viewWillLayoutSubviews", cast, (int)[array count]);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array ]
                                setMethodName:@"viewWillLayoutSubviews"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread]]
                            setParams:nil]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
}


- (void) mtSwizzle_viewDidLayoutSubviews
{
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    NSString * name = [[MetricLogic sharedManager] gen_a_uuid];
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] registerCollecter:name withArray:&array];
    }
    
    
    [self mtSwizzle_viewDidLayoutSubviews];
    
    
    if (name != nil &&
        [name length] > 0)
    {
        [[MetricLogic sharedManager] unregisterCollecter:name];
        
    }
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;

    LetAPMLOG(@"[%@:%@] CASTTIME:%f, %d", [self class], @"viewDidLayoutSubviews", cast, (int)[array count]);
    
    NSString * className = [NSString stringWithFormat:@"%@", [self class]];
    
    MethodData * method = [[[[[[[[MethodData builder] addAllMetricDatas:array ]
                                setMethodName:@"viewDidLayoutSubviews"]
                               setClassName:className]
                              setCastTime:cast]
                             setIsMainThread:[NSThread isMainThread]]
                            setParams:nil]
                           build];
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeMethodData
                                        withCmdData:[method data]];
}


- (void)mtSwizzle_didReceiveMemoryWarning {
    [self mtSwizzle_didReceiveMemoryWarning];
}

@end
