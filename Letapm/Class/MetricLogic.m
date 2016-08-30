//
//  MetricLogic.m
//  BatSdk
//
//  Created by Gang.Wang on 7/31/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "MetricLogic.h"

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

static double g_latestCollectTime = 0;
static double g_latestTotalCpuTime = 0;
static double g_firsttotalbattery = -1.0;

static bool getCpuUsage(double* retUsage){
    kern_return_t kr;
    thread_array_t         threadList;
    mach_msg_type_number_t threadCount;
    thread_info_data_t     thInfo;
    mach_msg_type_number_t threadInfoCount;
    thread_basic_info_t thBasicInfo;
    
    double currentTime = CACurrentMediaTime();
    double interval = currentTime - g_latestCollectTime;
    long sec = 0;
    long usec = 0;
    double totalCpuTime = 0;
    
    if (retUsage == NULL) {
        return false;
    }
    *retUsage = 0;
    
    kr = task_threads(mach_task_self(), &threadList, &threadCount);
    if (kr != KERN_SUCCESS) {
        return false;
    }
    
    for (int i = 0; i < threadCount; i++)
    {
        threadInfoCount = THREAD_INFO_MAX;
        kr = thread_info(threadList[i], THREAD_BASIC_INFO, (thread_info_t)thInfo, &threadInfoCount);
        if (kr != KERN_SUCCESS) {
            if(threadList)
                vm_deallocate(mach_task_self(), (vm_offset_t)threadList, threadCount * sizeof(thread_t));
            return false;
        }
        thBasicInfo = (thread_basic_info_t)thInfo;
        if (!(thBasicInfo->flags & TH_FLAGS_IDLE)) {
            sec = sec + thBasicInfo->user_time.seconds + thBasicInfo->system_time.seconds;
            usec = usec + thBasicInfo->system_time.microseconds + thBasicInfo->system_time.microseconds;
        }
    }
    
    totalCpuTime = sec + (double) usec / 1000000;
    if(interval != 0)
        *retUsage = (totalCpuTime - g_latestTotalCpuTime) / interval * 100;
    
    g_latestTotalCpuTime = totalCpuTime;
    if(threadList)
        vm_deallocate(mach_task_self(), (vm_offset_t)threadList, threadCount * sizeof(thread_t));
    return true;
}

// retResident 当前使用的 物理内存 ~== rss
static bool getMemoryUsage(double* retVirtual, double* retResident){
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    
    if (retVirtual == NULL || retResident == NULL) {
        return false;
    }
    *retVirtual = 0;
    *retResident = 0;
    
    kern_return_t kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kr != KERN_SUCCESS) {
        return false;
    }
    *retVirtual = (double)info.virtual_size / (1024 * 1024);
    *retResident = (double)info.resident_size / (1024 * 1024);
    return true;
}

static bool getBatteryLevel(double* batteryLevel, UIDeviceBatteryState* state){
    if (batteryLevel == NULL || state == NULL) {
        return false;
    }
    *batteryLevel = [UIDevice currentDevice].batteryLevel;
    *state = [UIDevice currentDevice].batteryState;
    return true;
}


// 可用
static bool getGlobalFreeMemory(double *retFree){
    vm_statistics_data_t vm_stat;
    mach_msg_type_number_t host_size = sizeof(vm_stat) / sizeof(natural_t);
    vm_size_t pagesize;
    kern_return_t err;
    
    if (retFree == NULL) {
        return false;
    }
    *retFree = 0;
    
    err = host_page_size(mach_host_self(), &pagesize);
    if(err != KERN_SUCCESS)
    {
        return false;
    }
    
    err = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if(err != KERN_SUCCESS)
    {
        return false;
    }
    
    *retFree = (double)vm_stat.free_count * pagesize / 1024 / 1024;
    return true;
}

@implementation MetricLogic

+ (MetricLogic *)sharedManager
{
    static MetricLogic *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}

- (id) init {
    self = [super init];
    
    if (self) {
        
//        self.waitStart = YES;
//        g_firsttotalbattery = 0;
//        
//        self.collecters = [[NSMutableDictionary alloc] init];
//        self.collecterLock = [[NSLock alloc] init];
//        
//        NSThread * workThread = [[NSThread alloc] initWithTarget:self
//                                                            selector:@selector(workThreadFun)
//                                                              object:nil];
//        [workThread start];
    }
    
    return self;
}



- (void) workThreadFun
{
    while (1 && false) {
        
        float xx = (float) (((float)METRICData_RATE) / ((float)1000));

        [NSThread sleepForTimeInterval:xx];
        
        if (self.stop) {
            break;
        }
        
        if (self.collecters == nil ||
            self.collecters.count <= 0) {
            continue;
        }
        
        [self.collecterLock lock];
        NSArray * keys = [self.collecters allKeys];
        
        if (keys == nil ||
            [keys count] <= 0)
        {
            [self.collecterLock unlock];
            continue;
        }
        
        for (NSString * key in keys) {
            MetricData * data = [self collectMetricDataWithTime:(int32_t)[[self.collecters objectForKey:key] count] * METRICData_RATE];
            [[self.collecters objectForKey:key] addObject:data];
        }
        
        [self.collecterLock unlock];
    }
}


- (BOOL) startCollectThread
{
    self.waitStart = NO;
    return YES;
}

- (BOOL) exitCollectThread
{
    self.stop = YES;
    
    return YES;
}

-(NSString *) gen_a_uuid
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    
    CFRelease(uuid_string_ref);
    return uuid;
}

- (void) registerCollecter:(NSString *) name withArray:(NSMutableArray **) array
{
    
    if (name == nil ||
        [name length] <= 0) {
        return;
    }
    
    if (array == nil) {
        return;
    }
 
    [self.collecterLock lock];
  
    [self.collecters setObject:(*array) forKey:name];
    [self.collecterLock unlock];
    
}

- (void) unregisterCollecter:(NSString *) name
{
    if (name == nil ||
        [name length] <= 0)
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (self.collecters == nil) {
            return;
        }
        
        [self.collecterLock lock];
        
        [self.collecters removeObjectForKey:name];
        
        [self.collecterLock unlock];

    });
}


- (MetricData *) collectMetricDataWithTime:(int32_t) time
{
    MetricData * ret = nil;
    
    double cpuUsage = -1;
    getCpuUsage(&cpuUsage);
    
    double virtualMemorySize = -1, residentMemorySize = -1;
    getMemoryUsage(&virtualMemorySize, &residentMemorySize);
    
    double freeMemory = -1;
    getGlobalFreeMemory(&freeMemory);
    
    double batteryLever = -1.0;
    UIDeviceBatteryState batteryState;
    getBatteryLevel(&batteryLever, &batteryState);
    batteryLever *= 100;
    
    Float32 reportStartBattery = -1.0f;
    Float32 reportCurrentBattery = -1.0f;
    
    if (batteryState == UIDeviceBatteryStateCharging || g_firsttotalbattery < 0) {
        g_firsttotalbattery = batteryLever;
    } else {
        reportStartBattery = g_firsttotalbattery;
        reportCurrentBattery = batteryLever;
    }
    
    
    ret = [[[[[[[[[[MetricData builder] setCpu:cpuUsage]
                 setMetricType:MetricTypeMetricNormal]
                setStartBattery:reportStartBattery]
               setCurrentBattery:reportCurrentBattery]
              setFps:-1]
             setMetricName:@""]
            setMemory:[[[[[[[[MetricData_MetricMemoryData builder]
                             setVss:-1.0f]
                            setUss:-1.0f]
                           setRss:residentMemorySize]
                          setPss:-1.0f]
                         setTotal:-1.0f]
                        setFree:freeMemory]
                       build]]
        setTime:time]
        build];
    
    return ret;
}


- (MetricData *) collectMetricData
{
    return [self collectMetricDataWithTime:0];
}

@end
