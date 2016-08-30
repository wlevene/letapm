//
//  MetricLogic.h
//  BatSdk
//
//  Created by Gang.Wang on 7/31/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MetricLogic : NSObject

@property (nonatomic, assign) BOOL stop;

@property (nonatomic, assign) BOOL waitStart;
@property (nonatomic, strong) NSMutableDictionary * collecters;

@property (nonatomic, strong) NSLock * collecterLock;



+ (MetricLogic *)sharedManager;

- (BOOL) startCollectThread;

- (void) registerCollecter:(NSString *) name withArray:(NSMutableArray **) array;
- (void) unregisterCollecter:(NSString *) name ;

- (BOOL) exitCollectThread;

- (NSString *) gen_a_uuid;

@end
