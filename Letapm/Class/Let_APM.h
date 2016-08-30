//
//  ┏┓
//  ┃┃┏━┓┏━━┓┏━┓┏━┓┏━━┓　　┏━┓┏━┓┏━━┓
//  ┃┃┃┻┫┗┓┏┛┃━┃┃┃┃┃┃┃┃┏┓┃┣┫┃┃┃┃┃┃┃
//  ┗┛┗━┛　┗┛　┗┻┛┃┏┛┗┻┻┛┗┛┗━┛┗━┛┗┻┻┛
//                      ┗┛
//  LetAPM.h
//  Letapm
//
//  Created by Gang.Wang on 8/25/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//  0.1.7
//  LetAPM 支持 ios7和ios7之后的系统

#import <Foundation/Foundation.h>

@interface LetAPM : NSObject

/*
 @brief:通过appKey初始化
        目前使用的时候 appkey & appSecret 的值均需要传入 appkey 即可
 */
+ (void) initWithAppKey:(NSString *) appKey withAppSecret:(NSString *) appSecret;

/*
 @brief:是否输出日志
 */
+ (void) showLog:(BOOL) showlog;

/*
 @brief:获取sdk版本号
 */
+ (NSString *) versionForSDK;

@end
