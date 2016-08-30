//
//  MTBatteryLogic.m
//  Letapm
//
//  Created by Gang.Wang on 11/5/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "MTBatteryLogic.h"
#import "sdk_def.h"

#import "NSObject+MTSwizzle.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"
#import "Cmd.pb.h"
#import "LetapmCore.h"

#import <libkern/OSAtomic.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <mach/processor_info.h>
#import <mach/mach_host.h>
#import <zlib.h>
#import <mach/mach.h>
#import <UIKit/UIKit.h>


static float g_firsttotalbattery = -1.0f;

@interface MTBatteryLogic()

@property (nonatomic, assign) BOOL exit;

@property (nonatomic, assign) BOOL currentMinValue;
@property (nonatomic, assign) int count;

@property (nonatomic, strong) NSTimer * timer;

@property (nonatomic, strong) NSMutableArray * batteryArray;


@end

@implementation MTBatteryLogic

+ (MTBatteryLogic *)sharedManager
{
    static MTBatteryLogic *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}

- (id) init {
    self = [super init];
    
    if (self) {
        
        self.currentMinValue = 10000;
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
        
        self.exit = NO;
        
        self.count = 1;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:BATTERY_CYCLE_TIME target:self selector:@selector(timerFun) userInfo:nil repeats:YES];
        
        self.batteryArray = [[NSMutableArray alloc] init];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
//                                                     name:UIApplicationWillResignActiveNotification object:nil];
    }
    
    return self;
}

- (void) startCollecter
{
    [self.timer fire];
}

- (void) stopCollecter
{
    self.exit = YES;
}

//- (void)applicationWillResignActive:(NSNotification *)notificatio
//{
//    LetAPMLOG(@"ResignActive:  Stop Battery Collecte");
//    self.exit = TRUE;
//}

- (void) timerFun
{
    if (![NSThread isMainThread]) {
        return;
    }
    
    if (self.exit) {
        [self.timer invalidate];
        return;
    }
    
    if (self.count > BATTERY_DATA_MAX_COUNT) {
        // 运行超过 30 分钟结束
        LetAPMLOG(@"Finish And Stop Battery Data......");
        [self.timer invalidate];
        return;
    }
    
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    
    UIDeviceBatteryState batteryState = [myDevice batteryState];
    float batteryLever = -1.0;
    batteryLever = [myDevice batteryLevel];
    
    self.count++;
    
    // 如果发现在充电就结束收集
    if (batteryState == UIDeviceBatteryStateCharging)
    {
        LetAPMLOG(@"Charging STOP Battery Data......");
        self.exit = YES;
        return;
    }
    
    batteryLever = batteryLever * 100;
    
    if (g_firsttotalbattery <= 0.0f)
    {
        g_firsttotalbattery = batteryLever;
        self.currentMinValue = batteryLever;
    }
    
    //  起始电量小于2的  不收集
    if (g_firsttotalbattery < 2) {
        self.exit = YES;
        return;
    }
    
    //  确保不会出现电量增大的情况出现
    if (self.currentMinValue < batteryLever) {
        batteryLever = self.currentMinValue;
    }
    else {
        self.currentMinValue = batteryLever;
    }
    
    if (batteryLever < 0 ||
        batteryLever > 100) {
        self.exit = YES;
        return;
    }
    
    BatteryData_BatteryItemData  * batteryItemData = [[[[BatteryData_BatteryItemData builder] setCurrentBattery:(int)batteryLever]
                                                       setTimeSection:self.count] build];
    
    [self.batteryArray addObject:batteryItemData];
    if ([self.batteryArray count] >= BATTERY_REPORT_COUNT)
    {
        BatteryData * battery = [[[[BatteryData builder] setStartBattery:(int)g_firsttotalbattery]
                                  addAllBatterys:(NSArray *)self.batteryArray]
                                 build];
        
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeBatteryData
                                            withCmdData:[battery data]];
        
        [self.batteryArray removeAllObjects];
    }
}

@end
