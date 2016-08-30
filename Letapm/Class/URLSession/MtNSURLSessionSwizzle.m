//
//  MtNSURLSessionSwizzle.m
//  Letapm
//
//  Created by Gang.Wang on 12/28/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import "MtNSURLSessionSwizzle.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/queue.h>

#import "LetapmCore.h"
#import "LetapmDataDefault.h"
#import "sdk_def.h"
#import "MtRequestData.h"

typedef void (^MtNSURLSessionAsyncCompletion)(id fileURLOrData, NSURLResponse *response, NSError *error);

@interface MtNSURLSessionSwizzle (MtNSURLSessionTaskHelpers)

- (void)MtURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler delegate:(id <NSURLSessionDelegate>)delegate;

- (void)MtURLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler delegate:(id <NSURLSessionDelegate>)delegate;

- (void)MtURLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data delegate:(id <NSURLSessionDelegate>)delegate;

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask delegate:(id <NSURLSessionDelegate>)delegate;

- (void)MtURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error delegate:(id <NSURLSessionDelegate>)delegate;
- (void)MtURLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite delegate:(id <NSURLSessionDelegate>)delegate;
- (void)MtURLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location data:(NSData *)data delegate:(id <NSURLSessionDelegate>)delegate;

- (void)MtURLSessionTaskWillResume:(NSURLSessionTask *)task;

@end



static inline BOOL af_addMethod(Class class, SEL selector, Method method) {
    return class_addMethod(class, selector,  method_getImplementation(method),  method_getTypeEncoding(method));
}

static inline void af_swizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

@interface MtNSURLSessionSwizzle ()

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, strong) NSMutableDictionary *requestStatesForRequestIDs;
@property (nonatomic, strong) NSMutableDictionary *requestDatas;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation MtNSURLSessionSwizzle

#pragma mark - Public Methods

+ (void)setEnabled:(BOOL)enabled
{
    if (enabled) {
        [self injectIntoAllNSURLConnectionDelegateClasses];
    }
    
    [[self sharedObserver] setEnabled:enabled];
}

+ (BOOL)isEnabled
{
    return [[self sharedObserver] isEnabled];
}

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        //        [[NSNotificationCenter defaultCenter] postNotificationName:kFLEXNetworkObserverEnabledStateChangedNotification object:self];
    }
}

//+ (void)load
//{
//    // We don't want to do the swizzling from +load because not all the classes may be loaded at this point.
//    dispatch_async(dispatch_get_main_queue(), ^{
//        //        if ([self shouldEnableOnLaunch]) {
//        [self setEnabled:YES];
//        //        }
//    });
//}

#pragma mark - Statics

+ (instancetype)sharedObserver
{
    static MtNSURLSessionSwizzle *sharedObserver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObserver = [[[self class] alloc] init];
    });
    return sharedObserver;
}

+ (NSString *)nextRequestID
{
    return [[NSUUID UUID] UUIDString];
}

#pragma mark Delegate Injection Convenience Methods

+ (SEL)swizzledSelectorForSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"_mt_letapm_session_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

/// All swizzled delegate methods should make use of this guard.
/// This will prevent duplicated sniffing when the original implementation calls up to a superclass implementation which we've also swizzled.
/// The superclass implementation (and implementations in classes above that) will be executed without inteference if called from the original implementation.
+ (void)sniffWithoutDuplicationForObject:(NSObject *)object selector:(SEL)selector sniffingBlock:(void (^)(void))sniffingBlock originalImplementationBlock:(void (^)(void))originalImplementationBlock
{
    // If we don't have an object to detect nested calls on, just run the original implmentation and bail.
    // This case can happen if someone besides the URL loading system calls the delegate methods directly.
    // See https://github.com/Flipboard/FLEX/issues/61 for an example.
    if (!object) {
        originalImplementationBlock();
        return;
    }
    
    const void *key = selector;
    
    // Don't run the sniffing block if we're inside a nested call
    if (!objc_getAssociatedObject(object, key)) {
        sniffingBlock();
    }
    
    // Mark that we're calling through to the original so we can detect nested calls
    objc_setAssociatedObject(object, key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    originalImplementationBlock();
    objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls
{
    if ([cls instancesRespondToSelector:selector]) {
        unsigned int numMethods = 0;
        Method *methods = class_copyMethodList(cls, &numMethods);
        
        BOOL implementsSelector = NO;
        for (int index = 0; index < numMethods; index++) {
            SEL methodSelector = method_getName(methods[index]);
            if (selector == methodSelector) {
                implementsSelector = YES;
                break;
            }
        }
        
        free(methods);
        
        if (!implementsSelector) {
            return YES;
        }
    }
    
    return NO;
}

+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)class withBlock:(id)block swizzledSelector:(SEL)swizzledSelector
{
    // This method is only intended for swizzling methods that are know to exist on the class.
    // Bail if that isn't the case.
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    if (!originalMethod) {
        return;
    }
    
    IMP implementation = imp_implementationWithBlock(block);
    class_addMethod(class, swizzledSelector, implementation, method_getTypeEncoding(originalMethod));
    Method newMethod = class_getInstanceMethod(class, swizzledSelector);
    method_exchangeImplementations(originalMethod, newMethod);
}

+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock
{
    if ([self instanceRespondsButDoesNotImplementSelector:selector class:cls]) {
        return;
    }
    
    IMP implementation = imp_implementationWithBlock((id)([cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock));
    
    Method oldMethod = class_getInstanceMethod(cls, selector);
    if (oldMethod) {
        class_addMethod(cls, swizzledSelector, implementation, methodDescription.types);
        
        Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
        
        method_exchangeImplementations(oldMethod, newMethod);
    } else {
        class_addMethod(cls, selector, implementation, methodDescription.types);
    }
}

#pragma mark - Delegate Injection

+ (void)injectIntoAllNSURLConnectionDelegateClasses
{
    // Only allow swizzling once.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Swizzle any classes that implement one of these selectors.
        const SEL selectors[] = {
            @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:),
            @selector(URLSession:dataTask:didReceiveData:),
            @selector(URLSession:dataTask:didReceiveResponse:completionHandler:),
            @selector(URLSession:task:didCompleteWithError:),
            @selector(URLSession:dataTask:didBecomeDownloadTask:delegate:),
            @selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:),
            @selector(URLSession:downloadTask:didFinishDownloadingToURL:)
        };
        
        const int numSelectors = sizeof(selectors) / sizeof(SEL);
        
        Class *classes = NULL;
        int numClasses = objc_getClassList(NULL, 0);
        
        if (numClasses > 0) {
            classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            for (NSInteger classIndex = 0; classIndex < numClasses; ++classIndex) {
                Class class = classes[classIndex];
                
                if (class == [MtNSURLSessionSwizzle class]) {
                    continue;
                }
                
                // Use the runtime API rather than the methods on NSObject to avoid sending messages to
                // classes we're not interested in swizzling. Otherwise we hit +initialize on all classes.
                // NOTE: calling class_getInstanceMethod() DOES send +initialize to the class. That's why we iterate through the method list.
                unsigned int methodCount = 0;
                Method *methods = class_copyMethodList(class, &methodCount);
                BOOL matchingSelectorFound = NO;
                for (unsigned int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
                    for (int selectorIndex = 0; selectorIndex < numSelectors; ++selectorIndex) {
                        if (method_getName(methods[methodIndex]) == selectors[selectorIndex]) {
                            [self injectIntoDelegateClass:class];
                            matchingSelectorFound = YES;
                            break;
                        }
                    }
                    
                    if (matchingSelectorFound) {
                        break;
                    }
                }
                
                free(methods);
            }
            
            free(classes);
        }
        
        [self injectIntoNSURLSessionTaskResume];
        
        [self injectIntoNSURLSessionAsyncDataAndDownloadTaskMethods];
        [self injectIntoNSURLSessionAsyncUploadTaskMethods];
    });
}

+ (void)injectIntoDelegateClass:(Class)cls
{
    // Sessions
    [self injectTaskWillPerformHTTPRedirectionIntoDelegateClass:cls];
    [self injectTaskDidReceiveDataIntoDelegateClass:cls];
    [self injectTaskDidReceiveResponseIntoDelegateClass:cls];
    [self injectTaskDidCompleteWithErrorIntoDelegateClass:cls];
    [self injectRespondsToSelectorIntoDelegateClass:cls];
    
    // Data tasks
    [self injectDataTaskDidBecomeDownloadTaskIntoDelegateClass:cls];
    
    // Download tasks
    [self injectDownloadTaskDidWriteDataIntoDelegateClass:cls];
    [self injectDownloadTaskDidFinishDownloadingIntoDelegateClass:cls];
}

+ (void)injectIntoNSURLSessionTaskResume
{
    [self swizzleResume];
}

+ (void)swizzleResume{
    /**
     WARNING: Trouble Ahead
     https://github.com/AFNetworking/AFNetworking/pull/2702
     */
    
    /*
     如果 APP 使用了 AFNETWORKING 库，此库会有hook住所有NSURLSESSION的功能，如果AFNETWORKING比LETAPM
     初始化早的话会导致letapm 无法hook 住 resume 方法， 所以此处会监听afnetworking的resume消息来获得resume
     在被调用时的通知
     */
    NSString * resultAFNetworkingMessage = @"com.alamofire.networking.nsurlsessiontask.resume";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(afnetworkingResumeObserverMt:)
                                                 name:resultAFNetworkingMessage object:nil];
    
    if (NSClassFromString(@"NSURLSessionTask")) {
        /**
         iOS 7 and iOS 8 differ in NSURLSessionTask implementation, which makes the next bit of code a bit tricky.
         Many Unit Tests have been built to validate as much of this behavior has possible.
         Here is what we know:
         - NSURLSessionTasks are implemented with class clusters, meaning the class you request from the API isn't actually the type of class you will get back.
         - Simply referencing `[NSURLSessionTask class]` will not work. You need to ask an `NSURLSession` to actually create an object, and grab the class from there.
         - On iOS 7, `localDataTask` is a `__NSCFLocalDataTask`, which inherits from `__NSCFLocalSessionTask`, which inherits from `__NSCFURLSessionTask`.
         - On iOS 8, `localDataTask` is a `__NSCFLocalDataTask`, which inherits from `__NSCFLocalSessionTask`, which inherits from `NSURLSessionTask`.
         - On iOS 7, `__NSCFLocalSessionTask` and `__NSCFURLSessionTask` are the only two classes that have their own implementations of `resume` and `suspend`, and `__NSCFLocalSessionTask` DOES NOT CALL SUPER. This means both classes need to be swizzled.
         - On iOS 8, `NSURLSessionTask` is the only class that implements `resume` and `suspend`. This means this is the only class that needs to be swizzled.
         - Because `NSURLSessionTask` is not involved in the class hierarchy for every version of iOS, its easier to add the swizzled methods to a dummy class and manage them there.
         
         Some Assumptions:
         - No implementations of `resume` or `suspend` call super. If this were to change in a future version of iOS, we'd need to handle it.
         - No background task classes override `resume` or `suspend`
         
         The current solution:
         1) Grab an instance of `__NSCFLocalDataTask` by asking an instance of `NSURLSession` for a data task.
         2) Grab a pointer to the original implementation of `af_resume`
         3) Check to see if the current class has an implementation of resume. If so, continue to step 4.
         4) Grab the super class of the current class.
         5) Grab a pointer for the current class to the current implementation of `resume`.
         6) Grab a pointer for the super class to the current implementation of `resume`.
         7) If the current class implementation of `resume` is not equal to the super class implementation of `resume` AND the current implementation of `resume` is not equal to the original implementation of `af_resume`, THEN swizzle the methods
         8) Set the current class to the super class, and repeat steps 3-8
         */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
        NSURLSessionDataTask *localDataTask = [[NSURLSession sessionWithConfiguration:nil] dataTaskWithURL:nil];
#pragma clang diagnostic pop
        IMP originalAFResumeIMP = method_getImplementation(class_getInstanceMethod([MtNSURLSessionSwizzle class], @selector(af_resume)));
        Class currentClass = [localDataTask class];
        
        IMP classResumeIMP11 = method_getImplementation(class_getInstanceMethod(currentClass, @selector(resume)));
        if (classResumeIMP11) {
            
        }
        
        while (class_getInstanceMethod(currentClass, @selector(resume))) {
            Class superClass = [currentClass superclass];
            IMP classResumeIMP = method_getImplementation(class_getInstanceMethod(currentClass, @selector(resume)));
            IMP superclassResumeIMP = method_getImplementation(class_getInstanceMethod(superClass, @selector(resume)));
            if (classResumeIMP != superclassResumeIMP &&
                originalAFResumeIMP != classResumeIMP) {
                [self swizzleResumeAndSuspendMethodForClass:currentClass];
            }
            currentClass = [currentClass superclass];
        }
        
        [localDataTask cancel];
    }
}



+ (void)swizzleResumeAndSuspendMethodForClass:(Class)class {
    
//    NSLog(@"%@", class);
    Method afResumeMethod = class_getInstanceMethod(self, @selector(af_resume));
    
    af_addMethod(class, @selector(af_resume), afResumeMethod);
    
    af_swizzleSelector(class, @selector(resume), @selector(af_resume));
}

- (void)af_resume {
    
    if ([self isKindOfClass:[NSURLSessionTask class]]) {
        [[MtNSURLSessionSwizzle sharedObserver] MtURLSessionTaskWillResume:(NSURLSessionTask *) self];
    }
    
    [self af_resume];
}


+ (void) afnetworkingResumeObserverMt:(NSNotification*)notification
{
    [[MtNSURLSessionSwizzle sharedObserver] MtURLSessionTaskWillResume:(NSURLSessionTask *) notification.object];
}


+ (void)injectIntoNSURLSessionAsyncDataAndDownloadTaskMethods
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSURLSession class];
        
        // The method signatures here are close enough that we can use the same logic to inject into all of them.
        const SEL selectors[] = {
            //            @selector(dataTaskWithHTTPGetRequest:completionHandler:),
            @selector(dataTaskWithRequest:completionHandler:),
            @selector(dataTaskWithURL:completionHandler:),
            @selector(downloadTaskWithRequest:completionHandler:),
            @selector(downloadTaskWithResumeData:completionHandler:),
            @selector(downloadTaskWithURL:completionHandler:)
        };
        
        const int numSelectors = sizeof(selectors) / sizeof(SEL);
        
        for (int selectorIndex = 0; selectorIndex < numSelectors; selectorIndex++) {
            SEL selector = selectors[selectorIndex];
            SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
            
            if ([self instanceRespondsButDoesNotImplementSelector:selector class:class]) {
                // iOS 7 does not implement these methods on NSURLSession. We actually want to
                // swizzle __NSCFURLSession, which we can get from the class of the shared session
                class = [[NSURLSession sharedSession] class];
            }
            
            NSURLSessionTask *(^asyncDataOrDownloadSwizzleBlock)(Class, id, MtNSURLSessionAsyncCompletion) = ^NSURLSessionTask *(Class slf, id argument, MtNSURLSessionAsyncCompletion completion) {
                NSURLSessionTask *task = nil;
                // If completion block was not provided sender expect to receive delegated methods or does not
                // interested in callback at all. In this case we should just call original method implementation
                // with nil completion block.
                if ([MtNSURLSessionSwizzle isEnabled] && completion) {
                    NSString *requestID = [self nextRequestID];
                    NSString *mechanism = [self mechansimFromClassMethod:selector onClass:class];
                    MtNSURLSessionAsyncCompletion completionWrapper = [self asyncCompletionWrapperForRequestID:requestID mechanism:mechanism completion:completion];
                    task = ((id(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, argument, completionWrapper);
                    [self setRequestID:requestID forConnectionOrTask:task];
                } else {
                    task = ((id(*)(id, SEL, id, id))objc_msgSend)(slf, swizzledSelector, argument, completion);
                }
                return task;
            };
            
            [self replaceImplementationOfKnownSelector:selector onClass:class withBlock:asyncDataOrDownloadSwizzleBlock swizzledSelector:swizzledSelector];
        }
    });
}

+ (void)injectIntoNSURLSessionAsyncUploadTaskMethods
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [NSURLSession class];
        
        // The method signatures here are close enough that we can use the same logic to inject into both of them.
        // Note that they have 3 arguments, so we can't easily combine with the data and download method above.
        const SEL selectors[] = {
            @selector(uploadTaskWithRequest:fromData:completionHandler:),
            @selector(uploadTaskWithRequest:fromFile:completionHandler:)
        };
        
        const int numSelectors = sizeof(selectors) / sizeof(SEL);
        
        for (int selectorIndex = 0; selectorIndex < numSelectors; selectorIndex++) {
            SEL selector = selectors[selectorIndex];
            SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
            
            if ([self instanceRespondsButDoesNotImplementSelector:selector class:class]) {
                // iOS 7 does not implement these methods on NSURLSession. We actually want to
                // swizzle __NSCFURLSession, which we can get from the class of the shared session
                class = [[NSURLSession sharedSession] class];
            }
            
            NSURLSessionUploadTask *(^asyncUploadTaskSwizzleBlock)(Class, NSURLRequest *, id, MtNSURLSessionAsyncCompletion) = ^NSURLSessionUploadTask *(Class slf, NSURLRequest *request, id argument, MtNSURLSessionAsyncCompletion completion) {
                NSURLSessionUploadTask *task = nil;
                if ([MtNSURLSessionSwizzle isEnabled]) {
                    NSString *requestID = [self nextRequestID];
                    NSString *mechanism = [self mechansimFromClassMethod:selector onClass:class];
                    MtNSURLSessionAsyncCompletion completionWrapper = [self asyncCompletionWrapperForRequestID:requestID mechanism:mechanism completion:completion];
                    task = ((id(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, request, argument, completionWrapper);
                    [self setRequestID:requestID forConnectionOrTask:task];
                } else {
                    task = ((id(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, request, argument, completion);
                }
                return task;
            };
            
            [self replaceImplementationOfKnownSelector:selector onClass:class withBlock:asyncUploadTaskSwizzleBlock swizzledSelector:swizzledSelector];
        }
    });
}

+ (NSString *)mechansimFromClassMethod:(SEL)selector onClass:(Class)class
{
    return [NSString stringWithFormat:@"+[%@ %@]", NSStringFromClass(class), NSStringFromSelector(selector)];
}

+ (void)injectTaskWillPerformHTTPRedirectionIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionWillPerformHTTPRedirectionBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *));
    
    NSURLSessionWillPerformHTTPRedirectionBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *)) {
        [[MtNSURLSessionSwizzle sharedObserver] MtURLSession:session task:task willPerformHTTPRedirection:response newRequest:newRequest completionHandler:completionHandler delegate:slf];
    };
    
    NSURLSessionWillPerformHTTPRedirectionBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSHTTPURLResponse *response, NSURLRequest *newRequest, void(^completionHandler)(NSURLRequest *)) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, response, newRequest, completionHandler);
        } originalImplementationBlock:^{
            ((id(*)(id, SEL, id, id, id, id, void(^)()))objc_msgSend)(slf, swizzledSelector, session, task, response, newRequest, completionHandler);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

+ (void)injectTaskDidReceiveDataIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:dataTask:didReceiveData:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveDataBlock)(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
    
    NSURLSessionDidReceiveDataBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        [[MtNSURLSessionSwizzle sharedObserver] MtURLSession:session dataTask:dataTask didReceiveData:data delegate:slf];
    };
    
    NSURLSessionDidReceiveDataBlock implementationBlock = ^(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, dataTask, data);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, dataTask, data);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

+ (void)injectDataTaskDidBecomeDownloadTaskIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:dataTask:didBecomeDownloadTask:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidBecomeDownloadTaskBlock)(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask);
    
    NSURLSessionDidBecomeDownloadTaskBlock undefinedBlock = ^(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask) {
        [[MtNSURLSessionSwizzle sharedObserver] URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask delegate:slf];
    };
    
    NSURLSessionDidBecomeDownloadTaskBlock implementationBlock = ^(id <NSURLSessionDataDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, dataTask, downloadTask);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, dataTask, downloadTask);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectTaskDidReceiveResponseIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:dataTask:didReceiveResponse:completionHandler:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDidReceiveResponseBlock)(id <NSURLSessionDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition));
    
    NSURLSessionDidReceiveResponseBlock undefinedBlock = ^(id <NSURLSessionDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition)) {
        [[MtNSURLSessionSwizzle sharedObserver] MtURLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler delegate:slf];
    };
    
    NSURLSessionDidReceiveResponseBlock implementationBlock = ^(id <NSURLSessionDelegate> slf, NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response, void(^completionHandler)(NSURLSessionResponseDisposition disposition)) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, dataTask, response, completionHandler);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id, void(^)()))objc_msgSend)(slf, swizzledSelector, session, dataTask, response, completionHandler);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

+ (void)injectTaskDidCompleteWithErrorIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionTaskDidCompleteWithErrorBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error);
    
    NSURLSessionTaskDidCompleteWithErrorBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        [[MtNSURLSessionSwizzle sharedObserver] MtURLSession:session task:task didCompleteWithError:error delegate:slf];
    };
    
    NSURLSessionTaskDidCompleteWithErrorBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, error);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, task, error);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

// Used for overriding AFNetworking behavior
+ (void)injectRespondsToSelectorIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(respondsToSelector:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    //Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    Method method = class_getInstanceMethod(cls, selector);
    struct objc_method_description methodDescription = *method_getDescription(method);
    
    typedef void (^NSURLSessionTaskDelegate)(id slf, SEL sel);
    
    BOOL (^undefinedBlock)(id <NSURLSessionTaskDelegate>, SEL) = ^(id slf, SEL sel) {
        return YES;
    };
    
    BOOL (^implementationBlock)(id <NSURLSessionTaskDelegate>, SEL) = ^(id <NSURLSessionTaskDelegate> slf, SEL sel) {
        if (sel == @selector(URLSession:dataTask:didReceiveResponse:completionHandler:)) {
            return undefinedBlock(slf, sel);
        }
        return ((BOOL(*)(id, SEL, SEL))objc_msgSend)(slf, swizzledSelector, sel);
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}


+ (void)injectDownloadTaskDidFinishDownloadingIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:downloadTask:didFinishDownloadingToURL:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDownloadDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDownloadTaskDidFinishDownloadingBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, NSURL *location);
    
    NSURLSessionDownloadTaskDidFinishDownloadingBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, NSURL *location) {
        NSData *data = [NSData dataWithContentsOfFile:location.relativePath];
        [[MtNSURLSessionSwizzle sharedObserver] MtURLSession:session task:task didFinishDownloadingToURL:location data:data delegate:slf];
    };
    
    NSURLSessionDownloadTaskDidFinishDownloadingBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, NSURL *location) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, location);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, id))objc_msgSend)(slf, swizzledSelector, session, task, location);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectDownloadTaskDidWriteDataIntoDelegateClass:(Class)cls
{
    SEL selector = @selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    Protocol *protocol = @protocol(NSURLSessionDownloadDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    
    typedef void (^NSURLSessionDownloadTaskDidWriteDataBlock)(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
    
    NSURLSessionDownloadTaskDidWriteDataBlock undefinedBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        [[MtNSURLSessionSwizzle sharedObserver] MtURLSession:session downloadTask:task didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite delegate:slf];
    };
    
    NSURLSessionDownloadTaskDidWriteDataBlock implementationBlock = ^(id <NSURLSessionTaskDelegate> slf, NSURLSession *session, NSURLSessionDownloadTask *task, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        [self sniffWithoutDuplicationForObject:session selector:selector sniffingBlock:^{
            undefinedBlock(slf, session, task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        } originalImplementationBlock:^{
            ((void(*)(id, SEL, id, id, int64_t, int64_t, int64_t))objc_msgSend)(slf, swizzledSelector, session, task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }];
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}

static char const * const kMtLetAPMRequestIDKey = "kMtLetAPMRequestIDKey";

+ (NSString *)requestIDForConnectionOrTask:(id)connectionOrTask
{
    NSString *requestID = objc_getAssociatedObject(connectionOrTask, kMtLetAPMRequestIDKey);
    if (!requestID) {
        requestID = [self nextRequestID];
        [self setRequestID:requestID forConnectionOrTask:connectionOrTask];
    }
    return requestID;
}

+ (void)setRequestID:(NSString *)requestID forConnectionOrTask:(id)connectionOrTask
{
    objc_setAssociatedObject(connectionOrTask, kMtLetAPMRequestIDKey, requestID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        self.requestStatesForRequestIDs = [[NSMutableDictionary alloc] init];
        self.requestDatas = [[NSMutableDictionary alloc] init];
        self.queue = dispatch_queue_create("com.letapm.mt_session_queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Private Methods

- (void)performBlock:(dispatch_block_t)block
{
    if (self.isEnabled) {
        dispatch_async(_queue, block);
    }
}

- (MtRequestState *)requestStateForRequestID:(NSString *)requestID
{
    MtRequestState *requestState = [self.requestStatesForRequestIDs objectForKey:requestID];
    if (!requestState) {
        requestState = [[MtRequestState alloc] init];
        [self.requestStatesForRequestIDs setObject:requestState forKey:requestID];
    }
    return requestState;
}

- (void)removeRequestStateForRequestID:(NSString *)requestID
{
    [self.requestStatesForRequestIDs removeObjectForKey:requestID];
}

#pragma mark - asyncCompletion

+ (MtNSURLSessionAsyncCompletion)asyncCompletionWrapperForRequestID:(NSString *)requestID mechanism:(NSString *)mechanism completion:(MtNSURLSessionAsyncCompletion)completion
{
    MtNSURLSessionAsyncCompletion completionWrapper = ^(id fileURLOrData, NSURLResponse *response, NSError *error) {
        
        MtRequestState *requestState = [[MtNSURLSessionSwizzle sharedObserver] requestStateForRequestID:requestID];
        
        NSData *data = requestState.dataAccumulator;
        if ([fileURLOrData isKindOfClass:[NSURL class]]) {
//            data = [NSData dataWithContentsOfURL:fileURLOrData];
        } else if ([fileURLOrData isKindOfClass:[NSData class]]) {
            data = fileURLOrData;
        }
 
        // Call through to the original completion handler
        
        MtRequestData * reqeustData = requestState.requestData;
        
        if (reqeustData) {
            
            NSNumber * number = reqeustData.startTime;
            
            double cast = 0;
            if (number)
            {
                double start = [number doubleValue];
                NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
                cast = (end - start) * 1000;
            }

            int32_t requestBodySize = sizeof(requestState.request.HTTPBody);
            
            HttpError * httpError = nil;
            
            httpError = [[[[[[HttpError builder] setErrorCode:0] setErrorMessage:@""] setErrorType:0] setResponseContent:@""] build];
            
            if (response == nil && error != nil)
            {
                httpError = [[[[[[HttpError builder] setErrorCode:(int32_t)[error code]]
                                setErrorMessage:[error description]]
                               setErrorType:HttpErrorTypeHttpErrorTypeNetwork]
                              setResponseContent:@""] build];
            }
            else
            {
                NSInteger statusCode = -1;
                
                NSHTTPURLResponse * httpurlResponse = nil;
                if ([response isKindOfClass:[NSHTTPURLResponse class]])
                {
                    httpurlResponse = (NSHTTPURLResponse *)response;
                    statusCode = [httpurlResponse statusCode];
                    
                }
                
                if (statusCode != 200) {
                    httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t) statusCode]
                                     setErrorMessage:@""]
                                    setHeaderField:[NSString stringWithFormat:@"%@", [httpurlResponse allHeaderFields]] ]
                                   setErrorType:HttpErrorTypeHttpErrorTypeHttp]
                                  setResponseContent:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ]
                                 build];
                }
            }
            
            HttpData * httpData = [[[[[[[HttpData builder] setUrl:[requestState.request.URL absoluteString]]
                                       setCastTime:cast]
                                      setError:httpError]
                                     setResponseSize: error == nil ? sizeof(data) : 0]
                                    setRequestSize: error==nil?requestBodySize : 0]
                                   build];
            
            LetAPMLOG(@"%@, %f, %d, %@", [requestState.request.URL absoluteString], cast, (int32_t)[data length], error);
            [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                                withCmdData:[httpData data]];
        }
        
        if (completion) {
            completion(fileURLOrData, response, error);
        }
    };
    return completionWrapper;
}


@end


@implementation MtNSURLSessionSwizzle (MtNSURLSessionTaskHelpers)

- (void)MtURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler delegate:(id<NSURLSessionDelegate>)delegate
{
//    [self performBlock:^{
//        NSString *requestID = [[self class] requestIDForConnectionOrTask:task];
        //        [[FLEXNetworkRecorder defaultRecorder] recordRequestWillBeSentWithRequestID:requestID request:request redirectResponse:response];
//    }];
}

- (void)MtURLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler delegate:(id<NSURLSessionDelegate>)delegate
{
//    [self performBlock:^{
    NSString *requestID = [[self class] requestIDForConnectionOrTask:dataTask];
    MtRequestState *requestState = [self requestStateForRequestID:requestID];
    
    NSMutableData *dataAccumulator = nil;
    if (response.expectedContentLength < 0) {
        dataAccumulator = [[NSMutableData alloc] init];
    } else {
        dataAccumulator = [[NSMutableData alloc] initWithCapacity:(NSUInteger)response.expectedContentLength];
    }
    requestState.dataAccumulator = dataAccumulator;
    
    MtRequestData * mydata = requestState.requestData;
    
    if (!mydata)
    {
        MtRequestData * data = [[MtRequestData alloc] init];
        NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
        
        data.startTime = [NSNumber numberWithDouble:start];
        data.datasize = 0;
        
        data.requestDataSize = sizeof(dataTask.currentRequest.HTTPBody);
        
        mydata = data;
        
        requestState.request = dataTask.currentRequest;
    }
    
    mydata.response = response;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        if ([(NSHTTPURLResponse * ) response statusCode] != 200)
        {
            mydata.needCopyRecvData = YES;
        }
    }
    
    requestState.requestData = mydata;


//        NSString *requestMechanism = [NSString stringWithFormat:@"NSURLSessionDataTask (delegate: %@)", [delegate class]];
        //        [[FLEXNetworkRecorder defaultRecorder] recordMechanism:requestMechanism forRequestID:requestID];
        
        //        [[FLEXNetworkRecorder defaultRecorder] recordResponseReceivedWithRequestID:requestID response:response];
//    }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask delegate:(id<NSURLSessionDelegate>)delegate
{
//    [self performBlock:^{
        // By setting the request ID of the download task to match the data task,
        // it can pick up where the data task left off.
        NSString *requestID = [[self class] requestIDForConnectionOrTask:dataTask];
        [[self class] setRequestID:requestID forConnectionOrTask:downloadTask];
//    }];
}

- (void)MtURLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)r_data delegate:(id<NSURLSessionDelegate>)delegate
{
    // Just to be safe since we're doing this async
    NSData * data = [r_data copy];
//    [self performBlock:^{
        NSString *requestID = [[self class] requestIDForConnectionOrTask:dataTask];
        MtRequestState *requestState = [self requestStateForRequestID:requestID];
    
        [requestState.dataAccumulator appendData:data];
//    }];
}

- (void)MtURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error delegate:(id<NSURLSessionDelegate>)delegate
{
//    [self performBlock:^{
        NSString *requestID = [[self class] requestIDForConnectionOrTask:task];
        MtRequestState *requestState = [self requestStateForRequestID:requestID];
    
        if (error) {
            MtRequestData * requestData = requestState.requestData;
            
            if (requestData)
            {
                NSNumber * number = requestData.startTime;
                
                double cast = 0;
                if (number)
                {
                    double start = [number doubleValue];
                    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
                    cast = (end - start) * 1000;
                }
                
                HttpError * httpError = nil;
                httpError = [[[[[[HttpError builder] setErrorCode:0]
                                setErrorMessage:@""]
                               setErrorType:0]
                              setResponseContent:@""]
                             build];
                
                if (requestData.response == nil &&
                    error != nil)
                {
                    httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t)[error code]]
                                     setErrorMessage:[error description]]
                                    setErrorType:HttpErrorTypeHttpErrorTypeNetwork]
                                   setHeaderField:@""]
                                  setResponseContent:@""] build];
                }
                
                NSString * url = [NSString stringWithFormat:@"%@", requestState.request.URL];
                
                HttpData * httpData = [[[[[[[HttpData builder] setUrl:url]
                                           setCastTime:cast] setError:httpError]
                                         setResponseSize:0]
                                        setRequestSize:requestData.requestDataSize]
                                       build];
                
                LetAPMLOG(@"Session %@ %f, %d %@", url, cast, (int32_t)[requestState.dataAccumulator length], error);
                [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                                    withCmdData:[httpData data]];
            }
        } else {
            // it ok 参见系统函数的说明
            
            NSNumber * number = requestState.requestData.startTime;
            
            double cast = 0;
            if (number)
            {
                double start = [number doubleValue];
                NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
                cast = (end - start) * 1000;
                
            }
            
            HttpError * httpError = nil;
            
            httpError = [[[[[[HttpError builder] setErrorCode:0] setErrorMessage:@""] setErrorType:0] setResponseContent:@""] build];
            
            //        NSURLResponse * response = data.response;
            NSInteger statusCode = -1;
            
            NSHTTPURLResponse * httpurlResponse = nil;
            
            if (requestState.requestData.response && [requestState.requestData.response isKindOfClass:[NSHTTPURLResponse class]])
            {
                httpurlResponse = (NSHTTPURLResponse *)requestState.requestData.response;
                statusCode = [httpurlResponse statusCode];
            }
            
            NSString * url = [NSString stringWithFormat:@"%@", requestState.request.URL];
            
            if (statusCode != 200) {
                
                httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t) statusCode]
                                 setErrorMessage:@""]
                                setHeaderField:[NSString stringWithFormat:@"%@", [httpurlResponse allHeaderFields]] ]
                               setErrorType:HttpErrorTypeHttpErrorTypeHttp]
                              setResponseContent:[[NSString alloc] initWithData:requestState.dataAccumulator encoding:NSUTF8StringEncoding] ]
                             build];
            }
            
            HttpData * httpData = [[[[[[[HttpData builder] setUrl:url]
                                       setCastTime:cast]
                                      setError:httpError]
                                     setResponseSize:(int32_t)[requestState.dataAccumulator length]]
                                    setRequestSize:requestState.requestData.requestDataSize]
                                   build];
            
            LetAPMLOG(@"Session %@ %f, %d %d %@", url, cast, (int32_t)[requestState.dataAccumulator length], (int)statusCode,  requestState.requestData.response);
            [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                                withCmdData:[httpData data]];
        }
        
        [self removeRequestStateForRequestID:requestID];
//    }];
}

- (void)MtURLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite delegate:(id<NSURLSessionDelegate>)delegate
{
//    [self performBlock:^{
    NSString *requestID = [[self class] requestIDForConnectionOrTask:downloadTask];
    MtRequestState *requestState = [self requestStateForRequestID:requestID];
    
    if (!requestState.dataAccumulator /*&& bytesWritten >= 0*/) {
        requestState.dataAccumulator = [[NSMutableData alloc] init];
    }
    
    MtRequestData * mydata = requestState.requestData;
    if (mydata && !mydata.response) {
        
        mydata.response = downloadTask.response;
        
        if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
            
            if ([(NSHTTPURLResponse * ) downloadTask.response statusCode] != 200)
            {
                mydata.needCopyRecvData = YES;
            }
        }
    }
//            NSString *requestMechanism = [NSString stringWithFormat:@"NSURLSessionDownloadTask (delegate: %@)", [delegate class]];
            //            [[FLEXNetworkRecorder defaultRecorder] recordMechanism:requestMechanism forRequestID:requestID];
//    }];
}

- (void)MtURLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location data:(NSData *)r_data delegate:(id<NSURLSessionDelegate>)delegate
{
    NSData * data = [r_data copy];
    NSString *requestID = [[self class] requestIDForConnectionOrTask:downloadTask];
    MtRequestState *requestState = [self requestStateForRequestID:requestID];
    [requestState.dataAccumulator appendData:data];
    
    MtRequestData * requestData = requestState.requestData;
    
    if (requestData)
    {
        NSNumber * number = requestData.startTime;
        
        double cast = 0;
        if (number)
        {
            double start = [number doubleValue];
            NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
            cast = (end - start) * 1000;
            
        }
        
        HttpError * httpError = nil;
        
        httpError = [[[[[[HttpError builder] setErrorCode:0] setErrorMessage:@""] setErrorType:0] setResponseContent:@""] build];
        
        //        NSURLResponse * response = data.response;
        NSInteger statusCode = -1;
        
        NSHTTPURLResponse * httpurlResponse = nil;
        
        if (requestData.response && [requestData.response isKindOfClass:[NSHTTPURLResponse class]])
        {
            httpurlResponse = (NSHTTPURLResponse *)requestData.response;
            statusCode = [httpurlResponse statusCode];
        }
        
        NSString * url = [NSString stringWithFormat:@"%@", requestState.request.URL];
        
        if (statusCode != 200) {
            
            httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t) statusCode]
                             setErrorMessage:@""]
                            setHeaderField:[NSString stringWithFormat:@"%@", [httpurlResponse allHeaderFields]] ]
                           setErrorType:HttpErrorTypeHttpErrorTypeHttp]
                          setResponseContent:[[NSString alloc] initWithData:requestState.dataAccumulator encoding:NSUTF8StringEncoding] ]
                         build];
        }
        
        HttpData * httpData = [[[[[[[HttpData builder] setUrl:url]
                                   setCastTime:cast]
                                  setError:httpError]
                                 setResponseSize:(int32_t)[requestState.dataAccumulator length]]
                                setRequestSize:requestData.requestDataSize]
                               build];
        
        LetAPMLOG(@"Session %@ %f, %d %d %@", url, cast, (int32_t)[requestState.dataAccumulator length], (int)statusCode,  requestData.response);
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                            withCmdData:[httpData data]];
    }
}

- (void)MtURLSessionTaskWillResume:(NSURLSessionTask *)task
{
    NSString *requestID = [[self class] requestIDForConnectionOrTask:task];
    MtRequestState *requestState = [self requestStateForRequestID:requestID];
    if (!requestState.request) {
        requestState.request = task.currentRequest;
        
        NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

        MtRequestData * data = [[MtRequestData alloc] init];
        
        data.startTime = [NSNumber numberWithDouble:start];
        data.datasize = 0;
        
        data.requestDataSize = sizeof(task.currentRequest.HTTPBody);
        
        requestState.requestData = data;
    }
}

@end
