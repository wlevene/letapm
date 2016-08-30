//
//  UIWebView+MTSwizzleEx.m
//  Letapm
//
//  Created by Gang.Wang on 10/9/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "UIWebView+MTSwizzleEx.h"

#import "MtJRSwizzle.h"
#import "MtRequestData.h"

#import <mach/mach_time.h>
#import "LetapmCore.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"



@interface UIWebView (MtInspectionDelegates)

+ (NSMutableSet *)inspectedDelegates;

@end

@implementation UIWebView (MtInspectionDelegates)

static NSMutableSet *s_delegates = nil;

+ (NSMutableSet *)inspectedDelegates
{
    if (! s_delegates)
        s_delegates = [[NSMutableSet alloc] init];
    return s_delegates;
}

@end


@interface MtWebViewInspectedConnectionDelegate : NSObject <UIWebViewDelegate>
@property (nonatomic, strong) NSURLRequest * request;
@property (nonatomic, strong) id <UIWebViewDelegate> actualDelegate;
@property (nonatomic, strong) MtRequestData * requestData;
@end

@implementation MtWebViewInspectedConnectionDelegate

- (id) initWithActualDelegate:(id <UIWebViewDelegate>)actual
{
    self = [super init];
    if (self) {
        self.actualDelegate = actual;
    }
    return self;
}

- (void) cleanup:(NSError *)error
{
//    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
//    if (self.response)
//        [userInfo setObject:self.response forKey:@"response"];
//    if (self.received.length > 0)
//        [userInfo setObject:self.received forKey:@"body"];
//    if (error)
//        [userInfo setObject:error forKey:@"error"];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:k_RECEIVED_RESPONSE object:nil userInfo:userInfo];
    
//    self.response = nil;
//    self.received = nil;
    self.actualDelegate = nil;
    [[UIWebView inspectedDelegates] removeObject:self];
}

// ------------------------------------------------------------------------
//
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    self.request = request;
    
    if ([self.actualDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        id <UIWebViewDelegate> actual = (id <UIWebViewDelegate>)self.actualDelegate;
        return [actual webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    MtRequestData * data = [[MtRequestData alloc] init];
    
    data.startTime = [NSNumber numberWithDouble:start];
    data.datasize = 0;
    
    self.requestData = data;
    
    if ([self.actualDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        id <UIWebViewDelegate> actual = (id <UIWebViewDelegate>)self.actualDelegate;
        [actual webViewDidStartLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error
{
    
    NSString * url = [NSString stringWithFormat:@"%@", self.request.URL];
    if (url == nil ||
        [url length] <= 0)
    {
        url = self.request.URL.absoluteString;
    }
    
    MtRequestData * data = self.requestData;
    
    if (data)
    {
        NSNumber * number = data.startTime;
        
        double cast = 0;
        if (number)
        {
            double start = [number doubleValue];
            NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
            cast = (end - start) * 1000;
            
            LetAPMLOG(@"Webview - %@ CASTTIME:%f", url, cast);
        }
        else
        {
            LetAPMLOG(@"Webview - %@ CASTTIME:N/A", url);
        }
        
        LetAPMLOG(@"didFailWithError %@ error:%@", url, error);
        
        NSString * webViewName = [NSString stringWithFormat:@"%@", [webView class]];
        
        WebViewData * webviewData = [[[[[[[WebViewData builder] setUrl:url] setCastTime:cast] setWebviewName:webViewName] setErrnoCode:(int32_t)[error code]] setErronMesage:[error description]] build];
        
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeWebviewData withCmdData:[webviewData data]];
    }
    
    if ([self.actualDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
    {
        [self.actualDelegate webView:webView didFailLoadWithError:error];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    MtRequestData * data = self.requestData;
    
    if (data)
    {
        NSNumber * number = data.startTime;
        
        double cast = 0;
        if (number)
        {
            double start = [number doubleValue];
            NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
            cast = (end - start) * 1000;
            
            LetAPMLOG(@"webview - %@ CASTTIME:%f", webView.request.URL, (Float64)cast);
        }
        else
        {
            LetAPMLOG(@"webview - %@ CASTTIME:N/A", webView.request.URL);
        }
    
        NSString * url = [NSString stringWithFormat:@"%@", webView.request.URL];
        
        NSString * webViewName = [NSString stringWithFormat:@"%@", [webView class]];
        
        WebViewData * webviewData = [[[[[[[WebViewData builder] setUrl:url]
                                         setCastTime:(Float64)cast]
                                        setWebviewName:webViewName]
                                       setErrnoCode:0]
                                      setErronMesage:@""]
                                     build];
        
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeWebviewData
                                            withCmdData:[webviewData data]];
    }
    
    if ([self.actualDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        id <UIWebViewDelegate> actual = (id <UIWebViewDelegate>)self.actualDelegate;
        [actual webViewDidFinishLoad:webView];
    }
}

@end



@implementation UIWebView (MTSwizzleEx)

// ------------------------------------------------------------------------

+ (void) MtswizzleMethod:(SEL)from to:(SEL)to
{
    NSError *error = nil;
    BOOL swizzled = [UIWebView mtjr_swizzleMethod:from withMethod:to error:&error];
    
    if (!swizzled || error) {
        
        LetAPMLOG(@"Failed in replacing method: %@", error);
    }
}

#pragma mark -
#pragma mark Instance method swizzling


- (void)mtinspected_loadRequest:(NSURLRequest *)request
{
    if (self.delegate ==nil)
    {
        [self setDelegate:nil];
    }
    
//    [[UIWebView inspectedDelegates] addObject:inspectedDelegate];
    
    [self mtinspected_loadRequest:request];
}

- (void)mtinspected_loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
    if (self.delegate ==nil)
    {
        [self setDelegate:nil];
    }
    
    [self mtinspected_loadHTMLString:string baseURL:baseURL];
}

- (void)mtinspected_setDelegate:(id < UIWebViewDelegate >)delegate
{
    MtWebViewInspectedConnectionDelegate *inspectedDelegate = [[MtWebViewInspectedConnectionDelegate alloc] initWithActualDelegate:delegate];
    
    [[UIWebView inspectedDelegates] addObject:inspectedDelegate];
    [self mtinspected_setDelegate:inspectedDelegate];
}



// ------------------------------------------------------------------------
static BOOL s_webview_inspectionEnabled = NO;

+ (void) setInspectionMt:(BOOL)enabled
{
    if (s_webview_inspectionEnabled == enabled)
        return;
    
    s_webview_inspectionEnabled = enabled;
    
#define mtinspected_method(method) mtinspected_##method
#define mtswizzle_method_wrap(method) [UIWebView MtswizzleMethod:@selector(method) to:@selector(mtinspected_method(method))]
    
    mtswizzle_method_wrap(loadRequest:);
    mtswizzle_method_wrap(loadHTMLString:baseURL:);
    mtswizzle_method_wrap(setDelegate:);
    
    
#undef mtswizzle_method_wrap
#undef mtswizzle_class_method_wrap
#undef mtinspected_method
}

+ (BOOL) inspectionMtEnabled
{
    return s_webview_inspectionEnabled;
}

@end
