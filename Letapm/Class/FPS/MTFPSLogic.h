//
//  MTFPSLogic.h
//  Letapm
//
//  Created by Gang.Wang on 12/2/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MTFPSLogic : NSObject


@property (nonatomic, assign) BOOL startCollecterFlag;

@property (nonatomic, assign) BOOL reportNormalFps;

@property (nonatomic, assign) int calamityFpsFlag;

+ (MTFPSLogic *)sharedManager;

- (void) startCollecter;

- (void) setFps:(NSUInteger) fps;

@end
