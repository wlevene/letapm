//
//  BatDataDefault.h
//  SwizzleDemo
//
//  Created by Gang.Wang on 6/1/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LetapmDataDefault : NSObject

+ (LetapmDataDefault *)sharedManager;

@property (nonatomic, assign) BOOL showLog;
@property (nonatomic, assign) BOOL DelayMethod;

@property (nonatomic, assign) BOOL ForceEnableAppKey;
@property (nonatomic, assign) BOOL ForceCollectionBattery;

@property (nonatomic, assign) BOOL ForceReportFps;

@property (nonatomic, strong) NSString * sdkServer;
@property (nonatomic, strong) NSString * sdkHttpsServer;


- (void) saveData:(NSData *) data;

- (void) startSendTask;

- (void) clearOldFile;

+ (void) delayMethodAdded;

@end
