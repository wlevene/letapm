//
//  MTBatteryLogic.h
//  Letapm
//
//  Created by Gang.Wang on 11/5/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTBatteryLogic : NSObject

+ (MTBatteryLogic *)sharedManager;

- (void) startCollecter;

- (void) stopCollecter;

@end
