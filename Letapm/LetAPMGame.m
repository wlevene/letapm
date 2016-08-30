//
//  LetAPMGame.m
//  Letapm
//
//  Created by Gang.Wang on 12/2/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "LetAPMGame.h"

#import "MTFPSLogic.h"
#import "LetAPMCMethodPlugin.h"

#import "Letapm.h"





@implementation LetAPMGame

+ (void) setFPS:(NSUInteger) fps
{
    if (fps <= 0) {
        return;
    }

    if (fps > 100)
    {
        return;
    }
    
    if ([NSThread isMainThread]) {
        [[MTFPSLogic sharedManager] setFps:fps];
    }    
}

@end


#if defined(__cplusplus)
extern "C"{
#endif
    
    void letapmSetFps(int fps)
    {
        [LetAPMGame setFPS:fps];
    }
    
#if defined(__cplusplus)
}
#endif


#if defined(__cplusplus)
extern "C"{
#endif
    
    void letapmShowLog(bool show)
    {
        [LetAPM showLog:show == true ? YES : NO];
    }
    
#if defined(__cplusplus)
}
#endif



#if defined(__cplusplus)
extern "C"{
#endif
    
    void letapmInit(const char * appkey)
    {
        NSString * appkeyStr = [NSString stringWithCString:appkey encoding:NSUTF8StringEncoding];
        
        if (appkeyStr == nil ||
            [appkeyStr length] <= 0)
        {
            return;
        }
        
        
        [LetAPM initWithAppKey:appkeyStr withAppSecret:appkeyStr];
    }
        
#if defined(__cplusplus)
}
#endif
