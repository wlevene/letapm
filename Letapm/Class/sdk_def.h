//
//  sdk_def.h
//  SwizzleDemo
//
//  Created by Gang.Wang on 6/16/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#ifndef SwizzleDemo_sdk_def_h
#define SwizzleDemo_sdk_def_h

#import "update.h"

#define SDKServer       @"http://www.letapm.com:6840/shake"
#define SDKServerHttps  @"https://www.letapm.com:6839/shake"


//#define SDKTEST_Server       @"http://127.0.0.1:6840/shake"

#define ProtocVersion     1



#define SOCKET_CONNECT_TIMEOUT  60
#define SOCKET_READ_TIMEOUT     -1
#define SOCKET_WRITE_TIMEOUT    -1


#define SOCKET_QUEUE_MAX_LEN    1000

#define METRICData_RATE         100 // 单位: ms

#define METHOD_DELAY            5   // 单位:s


// 多久收集一次
#define BATTERY_CYCLE_TIME      1 * 60 // 单位:s
// 最多收集多少条数据
#define BATTERY_DATA_MAX_COUNT  30
// 每多少条上报一次
#define BATTERY_REPORT_COUNT    5


// 将fps小于此值时，就截图，此值可由服务指定
#define FPS_SNAPSHOT_VALUE      12
#define FPS_NOTE_MAX_LENGHT     1024




#define IsShowLog               [[LetapmDataDefault sharedManager] showLog]
#define LetAPMLOG(s, ...)       if (IsShowLog) { NSLog(@"[LetAPM] %s(%d): %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__]); }
#define LetAPMLOGEx(s, ...)     // if (IsShowLog) { NSLog(@"[LetAPM] %s(%d): %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__]); }

#endif
