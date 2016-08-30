//
//  LetAPM.m
//  Letapm
//
//  Created by Gang.Wang on 8/25/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "Let_APM.h"

#import "Letapm.h"
#import "LetapmCore.h"
#import "sdk_def.h"
#import "LetapmDataDefault.h"
#import "LetapmSystem.h"

@implementation LetAPM

/*
 @brief:通过appKey初始化
 */
+(void) initWithAppKey:(NSString *) appKey withAppSecret:(NSString *) appSecret
{
    if (appKey == nil ||
        [appKey length] <= 0) {
        return;
    }
    
    if (appSecret == nil ||
        [appSecret length] <= 0) {
        return;
    }
    
    if ([[LetapmSystem iosVersion] floatValue] < 7.0) {
        return;
    }
    
    [[LetapmCore sharedManager] initWithAppKey:appKey withAppSecret:appSecret];
    
    return;
}

+ (void) showLog:(BOOL) showlog
{
    if ([[LetapmSystem iosVersion] floatValue] < 7.0) {
        return;
    }
    
    [[LetapmDataDefault sharedManager] setShowLog:showlog];
}

+ (NSString *) versionForSDK
{
    return LETAPM_VERSION;
}

@end


#pragma mark - SDK Magic Method

/*
 @brief:重新设置sdk gateway 地址，方便在正式环境和测试环境切换，此方法不公开
 */

#if defined(__cplusplus)
extern "C"{
#endif
    
    extern void setLetAPMSdkServer(const char * server)
    {
        NSString * serverStr = [NSString stringWithCString:server encoding:NSUTF8StringEncoding];
        
        if (serverStr == nil ||
            [serverStr length] <= 0)
        {
            return;
        }
        
        [LetapmDataDefault sharedManager].sdkServer = serverStr;
    }
    
#if defined(__cplusplus)
}
#endif


/*
 @brief: 作用同 setLetAPMSdkServer 此方法，区别是设置 https 地址
 */
#if defined(__cplusplus)
extern "C"{
#endif
    
    extern void setLetAPMHttpsSdkServer(const char * server)
    {
        NSString * serverStr = [NSString stringWithCString:server encoding:NSUTF8StringEncoding];
        
        if (serverStr == nil ||
            [serverStr length] <= 0)
        {
            return;
        }
        
        [LetapmDataDefault sharedManager].sdkHttpsServer = serverStr;
    }
    
#if defined(__cplusplus)
}
#endif


/*
 @brief: 设置方法是否延迟，发方便测试，比如[UIImage imageNamed] 添加延迟，以方便生成相关的内存cpu等测试数据
 */
#if defined(__cplusplus)
extern "C"{
#endif
    
    extern void setLetApmMethodDelay(bool delay)
    {
        if (delay) {
            [LetapmDataDefault sharedManager].DelayMethod = YES;
        } else {
            [LetapmDataDefault sharedManager].DelayMethod = NO;
        }
    }
    
#if defined(__cplusplus)
}
#endif

/*
 @brief: 强制上报battery数据
 */
#if defined(__cplusplus)
extern "C"{
#endif
    
    extern void setCollectionBatteryForce()
    {
        [LetapmDataDefault sharedManager].ForceCollectionBattery = YES;
    }
    
#if defined(__cplusplus)
}
#endif


/*
 @brief: 强制使appkey有效
 */
#if defined(__cplusplus)
extern "C"{
#endif
    extern void setEnableAppkeyForce()
    {
        [LetapmDataDefault sharedManager].ForceEnableAppKey = YES;
    }
    
#if defined(__cplusplus)
}
#endif

/*
 @brief: 强制使appkey有效
 */
#if defined(__cplusplus)
extern "C"{
#endif
    extern void setReportFpsForce()
    {
        [LetapmDataDefault sharedManager].ForceReportFps = YES;
    }
    
#if defined(__cplusplus)
}
#endif



