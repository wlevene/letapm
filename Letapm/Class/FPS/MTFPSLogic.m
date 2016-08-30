//
//  MTFPSLogic.m
//  Letapm
//
//  Created by Gang.Wang on 12/2/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "MTFPSLogic.h"

#import "sdk_def.h"

#import "NSObject+MTSwizzle.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"
#import "Cmd.pb.h"
#import "LetapmCore.h"
#import "LetAPMCMethodPlugin.h"

#import <UIKit/UIKit.h>


UnityiOSScreenShot g_pUnityScreenShotFun = NULL;

LetApmFpsCallbackGetNote g_pGetFpsNoteFun = NULL;

#if defined(__cplusplus)
extern "C"{
#endif
    extern void letapmRegistFpsCallBack(LetApmFpsCallbackGetNote pGetFpsNoteFun)
    {
        if (pGetFpsNoteFun == NULL)
        {
            return;
        }
        
        g_pGetFpsNoteFun = pGetFpsNoteFun;
    }
    
#if defined(__cplusplus)
}
#endif


#if defined(__cplusplus)
extern "C"{
#endif
    extern void letapmRegistScreenShotCallBack(UnityiOSScreenShot pFun)
    {
        if (pFun == NULL)
        {
            return;
        }
        
        g_pUnityScreenShotFun = pFun;
    }
    
#if defined(__cplusplus)
}
#endif


@interface MTFPSLogic()

@property (nonatomic, strong) NSDate * startTime;
@property (nonatomic, assign) BOOL collecterFinish;

@property (atomic, strong) NSMutableArray * fpsPool;
@end

@implementation MTFPSLogic

+ (MTFPSLogic *)sharedManager
{
    static MTFPSLogic *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
        sharedAccountManagerInstance.reportNormalFps = FALSE;
        sharedAccountManagerInstance.collecterFinish = FALSE;
        sharedAccountManagerInstance.startTime = [NSDate date];
        sharedAccountManagerInstance.fpsPool = [[NSMutableArray alloc] init];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
//                                                     name:UIApplicationWillResignActiveNotification object:nil];
    });
    return sharedAccountManagerInstance;
}


//- (void)applicationWillResignActive:(NSNotification *)notificatio
//{
//    LetAPMLOG(@"ResignActive:  Stop Fps Collecte");
//    self.collecterFinish = TRUE;
//}

- (void) startCollecter
{
    self.startCollecterFlag = YES;
}


- (void) setFps:(NSUInteger) fps
{
    LetAPMLOG(@"xxxxx : fps : %d  %d", (int) fps, self.calamityFpsFlag);
    // 收集到足够的fps后就不再收集
    if (self.self.collecterFinish) {
        return;
    }
    
    if (![NSThread isMainThread])
    {
        return;
    }
    
    if (fps <= 0) {
        return;
    }
    
    if (fps > 100)
    {
        return;
    }
    
    if (!self.startCollecterFlag) {
        return;
    }
    
    NSDate * date = [NSDate date];
    
    NSTimeInterval time = [date timeIntervalSinceDate:self.startTime];
    
    if (time > 30 * 60) {
        self.collecterFinish = YES;
//        LetAPMLOG(@"已运完成，不再收集fps")
        return;
    }
    
    int i_fps = (int) fps;
 
    NSData * snapshotData = nil;
    FpsData * fpsData = nil;
    
    NSString * note = nil;
    
    if (i_fps < self.calamityFpsFlag) {
        
        // call callback fun get note ...
        
        if (g_pGetFpsNoteFun != NULL) {
            note = [NSString stringWithCString:g_pGetFpsNoteFun(i_fps) encoding:NSUTF8StringEncoding];
            
            if (note != nil &&
                [note length] > FPS_NOTE_MAX_LENGHT)
            {
                note = [note substringToIndex:FPS_NOTE_MAX_LENGHT];
            }
            
            LetAPMLOG(@"fps get note:%@", note);
        }
                 
        UIImage * snapshot = [self unity3dSnapshot];
        if (snapshot) {
            // 使用jpg文件，.8的压缩比率，以减少size
            snapshotData = UIImageJPEGRepresentation(snapshot, .8f);
        }
    }
    
    [self.fpsPool addObject:[FpsData builder]];
    
    
    fpsData = [[[[[[FpsData builder] setFps:i_fps]
                  setNote:note]
                 setSnapShot:snapshotData]
                setTimeSection:(int)time]
               build];
    
    
    
    if (self.reportNormalFps) {
        
        // normal 模式下，上报到normal，并将fps calamity上报到calamity
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeFpsData
                                            withCmdData:[fpsData data]];
    }
        
    if (i_fps < self.calamityFpsFlag) {
        LetAPMLOG(@"fps: CalamityData");
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeFpsCalamityData
                                                withCmdData:[fpsData data]];
    }
}

- (UIImage *) windowSnapshot
{
    UIWindow *screenWindow = [[UIApplication sharedApplication] keyWindow];
    UIGraphicsBeginImageContext(screenWindow.frame.size);
    [screenWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}

- (UIImage *) unity3dSnapshot
{
    LetAPMLOG(@"=========== unity3dSnapshot");

    if (!g_pUnityScreenShotFun) {
        LetAPMLOG(@"ssssssss =======");
        return nil;
    }
    
    NSString * filePath = [NSString stringWithCString:g_pUnityScreenShotFun() encoding:NSUTF8StringEncoding];
    
//    UIImage * image = [UIImage imageWithData:[NSData dataWithBytes:<#(nullable const void *)#> length:<#(NSUInteger)#>]]
    
//    BOOL writeFinished = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil];
//    
//    int count = 0;
//    while (!writeFinished) {
//        writeFinished = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil];
//        LetAPMLOG(@"COUNT:%d", count++);
//    }
    
//    [NSThread sleepForTimeInterval:2];
//    // 存储在Documents目录下
//    UIImage * image = [UIImage imageWithContentsOfFile:filePath];
    
//    NSError * err = nil;
//    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&err];
    
    
    LetAPMLOG(@"=========== IMAGE PATH %@", filePath)
    return nil;
}

@end

