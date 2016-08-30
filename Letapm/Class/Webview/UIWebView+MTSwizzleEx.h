//
//  UIWebView+MTSwizzleEx.h
//  Letapm
//
//  Created by Gang.Wang on 10/9/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (MTSwizzleEx)

+ (void) setInspectionMt:(BOOL)enabled;
+ (BOOL) inspectionMtEnabled;

@end
