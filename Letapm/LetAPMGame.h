//
//  ┏┓
//  ┃┃┏━┓┏━━┓┏━┓┏━┓┏━━┓　　┏━┓┏━┓┏━━┓
//  ┃┃┃┻┫┗┓┏┛┃━┃┃┃┃┃┃┃┃┏┓┃┣┫┃┃┃┃┃┃┃
//  ┗┛┗━┛　┗┛　┗┻┛┃┏┛┗┻┻┛┗┛┗━┛┗━┛┗┻┻┛
//                      ┗┛
//
//  LetAPMGame.h
//  Letapm
//
//  Created by Gang.Wang on 12/2/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//


#import <Foundation/Foundation.h>


/*
 @brief: 提供 c 函数的回调函数， 当fps小于指定的值时，会通过此回调给app, app可通过此方法将一段文本附加到此fps信息上报到服务端
         文件内容不能大于1024
 */
typedef char * (*LetApmFpsCallbackGetNote)(int fps);


/*
 @brief:返回文件路径
*/
typedef char * (*UnityiOSScreenShot)();

#if defined(__cplusplus)
extern "C"{
#endif
    
    extern void letapmInit(const char * appkey);
    
    extern void letapmShowLog(bool show);
    
    extern void letapmSetFps(int fps);
    
    extern void letapmRegistFpsCallBack(LetApmFpsCallbackGetNote pGetFpsNoteFun);
    
    extern void letapmRegistScreenShotCallBack(UnityiOSScreenShot pStacktraceFun);
    
#if defined(__cplusplus)
}
#endif












@interface LetAPMGame : NSObject

/*
 @brief:统计游戏的fps值，由游戏实时传入, 传入频率最高为每秒1次，其它不限制
        fps  值为 0 < fps < 100 之间
        此方法一定要在主线程调用，如果在子线程调用会忽略当次统计
 */

+ (void) setFPS:(NSUInteger) fps;

@end
