//
//  NSURLConnection+Inspected.m
//
//

#import "NSURLConnection+MtInspected.h"
#import "MtJRSwizzle.h"

#import "MtRequestData.h"

#import <mach/mach_time.h>
#import "LetapmCore.h"
#import "LetapmDataDefault.h"
#import "sdk_def.h"

@interface NSURLConnection (MtInspectionDelegates)
+ (NSMutableSet *)inspectedDelegates;
@end

@implementation NSURLConnection (MtInspectionDelegates)

static NSMutableSet *s_delegates = nil;

+ (NSMutableSet *)inspectedDelegates
{
	if (! s_delegates)
		s_delegates = [[NSMutableSet alloc] init];
	return s_delegates;
}

@end

/**
 * NSURLConnection* delegate to handle callbacks first.
 * It will forward the callback to the original delegate after logging.
 */
@interface MtInspectedConnectionDelegate : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableData *received;
@property (nonatomic, strong) id <NSURLConnectionDelegate> actualDelegate;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) MtRequestData * requestData;
@end

@implementation MtInspectedConnectionDelegate
@synthesize received, actualDelegate, response;

- (id) initWithActualDelegate:(id <NSURLConnectionDelegate>)actual
{
	self = [super init];
	if (self) {
		self.received = [[NSMutableData alloc] init];
		[self.received setLength:0];
		self.actualDelegate = actual;
		self.response = nil;
	}
	return self;
}

- (void) cleanup:(NSError *)error
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	if (self.response)
		[userInfo setObject:self.response forKey:@"response"];
	if (self.received.length > 0)
		[userInfo setObject:self.received forKey:@"body"];
	if (error)
		[userInfo setObject:error forKey:@"error"];

	[[NSNotificationCenter defaultCenter] postNotificationName:k_RECEIVED_RESPONSE object:nil userInfo:userInfo];

	self.response = nil;
	self.received = nil;
	self.actualDelegate = nil;
	[[NSURLConnection inspectedDelegates] removeObject:self];
}

// ------------------------------------------------------------------------
//
#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
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
            
//            LetAPMLOG(@"%@ CASTTIME:%f", connection.currentRequest.URL, cast);
        }
        else
        {
//            LetAPMLOG(@"%@ CASTTIME:N/A", connection.currentRequest.URL);
        }

        LetAPMLOG(@"didFailWithError %@ error:%@", connection.currentRequest.URL, error);
        
        HttpError * httpError = nil;
        httpError = [[[[[[HttpError builder] setErrorCode:0]
                        setErrorMessage:@""]
                       setErrorType:0]
                      setResponseContent:@""]
                     build];

        if (self.response == nil &&
            error != nil)
        {
            httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t)[error code]]
                            setErrorMessage:[error description]]
                           setErrorType:HttpErrorTypeHttpErrorTypeNetwork]
                          setHeaderField:@""]
                          setResponseContent:@""] build];
        }

        NSString * url = [NSString stringWithFormat:@"%@", connection.currentRequest.URL];
        if (url == nil ||
            [url length] == 0)
        {
            url = [NSString stringWithFormat:@"%@", connection.originalRequest.URL];
        }

        
        HttpData * httpData = [[[[[[[HttpData builder] setUrl:url]
                                   setCastTime:cast] setError:httpError]
                                 setResponseSize:0]
                                setRequestSize:data.requestDataSize]
                               build];
        
        
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                            withCmdData:[httpData data]];
    }
    
    
	if ([self.actualDelegate respondsToSelector:@selector(connection:didFailWithError:)])
		[self.actualDelegate connection:connection didFailWithError:error];

	[self cleanup:error];
}

// ------------------------------------------------------------------------
#pragma mark NSURLConnectionDataDelegate
//
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse
{
	self.response = aResponse;
    
    MtRequestData * mydata = self.requestData;

    if (mydata)
    {
        mydata.response = response;

        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {

            if ([(NSHTTPURLResponse * ) response statusCode] != 200)
            {
                mydata.needCopyRecvData = YES;
            }
        }
    }
    

	if ([self.actualDelegate respondsToSelector:@selector(connection:didReceiveResponse:)]) {
		id <NSURLConnectionDataDelegate> actual = (id <NSURLConnectionDataDelegate>)self.actualDelegate;
		[actual connection:connection didReceiveResponse:response];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.received appendData:data];
    
    MtRequestData * mydata = self.requestData;

    if (mydata)
    {
        if (mydata.recvData == nil) {
            mydata.recvData = [[NSMutableData alloc] init];
        }

        if (mydata.needCopyRecvData) {
           [mydata.recvData appendData:data];
        }

        mydata.datasize += sizeof(data);
        
    }

	if ([self.actualDelegate respondsToSelector:@selector(connection:didReceiveData:)]) {
		id <NSURLConnectionDataDelegate> actual = (id <NSURLConnectionDataDelegate>)self.actualDelegate;
		[actual connection:connection didReceiveData:data];
	}
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	if ([self.actualDelegate respondsToSelector:@selector(connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
		id <NSURLConnectionDataDelegate> actual = (id <NSURLConnectionDataDelegate>)self.actualDelegate;
		[actual connection:connection didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
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
            
            LetAPMLOG(@"%@ CASTTIME:%lf", connection.currentRequest.URL, cast);
        }
        else
        {
            LetAPMLOG(@"%@ CASTTIME:N/A", connection.currentRequest.URL);
        }

        HttpError * httpError = nil;

        httpError = [[[[[[HttpError builder] setErrorCode:0] setErrorMessage:@""] setErrorType:0] setResponseContent:@""] build];

//        NSURLResponse * response = data.response;
        NSInteger statusCode = -1;

        NSHTTPURLResponse * httpurlResponse = nil;

        if (data.response && [data.response isKindOfClass:[NSHTTPURLResponse class]])
        {
            httpurlResponse = (NSHTTPURLResponse *)data.response;
            statusCode = [httpurlResponse statusCode];
        }            
        
        NSString * url = [NSString stringWithFormat:@"%@", connection.currentRequest.URL];
        if (url == nil ||
            [url length] == 0)
        {
            url = [NSString stringWithFormat:@"%@", connection.originalRequest.URL];
        }
        

        if (statusCode != 200) {

             httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t) statusCode]
                              setErrorMessage:@""]
                             setHeaderField:[NSString stringWithFormat:@"%@", [httpurlResponse allHeaderFields]] ]
                            setErrorType:HttpErrorTypeHttpErrorTypeHttp]
                           setResponseContent:[[NSString alloc] initWithData:data.recvData encoding:NSUTF8StringEncoding] ]
                          build];
        }

        HttpData * httpData = [[[[[[[HttpData builder] setUrl:url]
                                   setCastTime:cast]
                                  setError:httpError]
                                 setResponseSize:data.datasize]
                                setRequestSize:data.requestDataSize]
                               build];
        
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                            withCmdData:[httpData data]];
        
    }

	if ([self.actualDelegate respondsToSelector:@selector(connectionDidFinishLoading:)]) {
		id <NSURLConnectionDataDelegate> actual = (id <NSURLConnectionDataDelegate>)self.actualDelegate;
		[actual connectionDidFinishLoading:connection];
	}

	[self cleanup:nil];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	self.response = redirectResponse; // replace the response object with redirected one.

    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

    MtRequestData * data = [[MtRequestData alloc] init];

    data.startTime = [NSNumber numberWithDouble:start];
    data.datasize = 0;

    data.requestDataSize = sizeof(request.HTTPBody);
        
    self.requestData = data;

    

	if ([self.actualDelegate respondsToSelector:@selector(connection:willSendRequest:redirectResponse:)]) {
		id <NSURLConnectionDataDelegate> actual = (id <NSURLConnectionDataDelegate>)self.actualDelegate;
		return [actual connection:connection willSendRequest:request redirectResponse:redirectResponse];
	}
	return request;
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
	if ([self.actualDelegate respondsToSelector:@selector(connection:needNewBodyStream:)]) {
		id <NSURLConnectionDataDelegate> actual = (id <NSURLConnectionDataDelegate>)self.actualDelegate;
		return [actual connection:connection needNewBodyStream:request];
	}
	return nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	if ([self.actualDelegate respondsToSelector:@selector(connection:willCacheResponse:)]) {
		id <NSURLConnectionDataDelegate> actual = (id <NSURLConnectionDataDelegate>)self.actualDelegate;
		return [actual connection:connection willCacheResponse:cachedResponse];
	}
	return cachedResponse;
}

@end


@implementation NSURLConnection (MtInspected)

// ------------------------------------------------------------------------
#pragma mark -
#pragma mark Class method swizzling
//

#define postSendingRequestNotification

//#define postSendingRequestNotification [[NSNotificationCenter defaultCenter] postNotificationName:k_SENDING_REQUEST object:nil userInfo:[NSDictionary dictionaryWithObject:request forKey:@"request"]]

+ (NSData *)mtinspected_sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    BOOL useDefaultError = YES;
    
    if (!error) {
        useDefaultError = NO;
    }
    
    NSError * connectError = nil;
    NSURLResponse * connectResponse = nil;
    
    NSData *responseData = nil;
    
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
 
    if (useDefaultError) {
        
        if (!response) {
            responseData = [NSURLConnection mtinspected_sendSynchronousRequest:request
                                                             returningResponse:&connectResponse
                                                                    error:error];
        } else {
            responseData = [NSURLConnection mtinspected_sendSynchronousRequest:request
                                                             returningResponse:response
                                                                         error:error];
        }
        
    } else {
        if (!response) {
            responseData = [NSURLConnection mtinspected_sendSynchronousRequest:request
                                                             returningResponse:&connectResponse
                                                                         error:&connectError];
        } else {
            responseData = [NSURLConnection mtinspected_sendSynchronousRequest:request
                                                             returningResponse:response
                                                                         error:&connectError];
        }

    }
    

    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
    double cast = (end - start) * 1000;
    
    int32_t requestBodySize = sizeof(request.HTTPBody);
    
    
    HttpError * httpError = nil;
    
    httpError = [[[[[[[HttpError builder] setErrorCode:0] setErrorMessage:@""] setErrorType:0] setResponseContent:@""] setHeaderField:@""] build];
    
    BOOL setHttpError = NO;
    if (useDefaultError && error && [(*error) code]) {
        httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t)[(*error) code]]
                         setErrorMessage:[(*error) description]]
                        setErrorType:HttpErrorTypeHttpErrorTypeNetwork]
                       setResponseContent:@""]
                      setHeaderField:@""] build];
        setHttpError = YES;

    }
    
    if (!useDefaultError && connectError && [connectError code]) {
        httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t)[connectError code]]
                         setErrorMessage:[connectError description]]
                        setErrorType:HttpErrorTypeHttpErrorTypeNetwork]
                       setResponseContent:@""]
                      setHeaderField:@""] build];
        
        setHttpError = YES;
    }
    
    if (!setHttpError)
    {
        if (!response) {
            LetAPMLOG(@"response:%@", connectResponse);
        } else {
            LetAPMLOG(@"response:%@", [(*response) description]);
        }
        
        
        NSInteger statusCode = -1;
        
        NSHTTPURLResponse * httpurlResponse = nil;
    
        if (!response) {
            if ([connectResponse isKindOfClass:[NSHTTPURLResponse class]])
            {
                httpurlResponse = (NSHTTPURLResponse *)connectResponse;
            }
            
        } else {
            if ([(*response) isKindOfClass:[NSHTTPURLResponse class]])
            {
                httpurlResponse = (NSHTTPURLResponse *)(*response);
            }
        }
        
        statusCode = [httpurlResponse statusCode];
        
        if (statusCode != 200) {
            httpError = [[[[[[[HttpError builder] setErrorCode:(int32_t) statusCode]
                             setErrorMessage:@""]
                            setHeaderField:[NSString stringWithFormat:@"%@", [httpurlResponse allHeaderFields]] ]
                           setErrorType:HttpErrorTypeHttpErrorTypeHttp]
                          setResponseContent:[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] ]
                         build];
            
            setHttpError = YES;
            
        }
    }
    
    BOOL isError = setHttpError;
    
    HttpData * httpData = [[[[[[[HttpData builder] setUrl:[request.URL absoluteString]]
                               setCastTime:cast] setError:httpError]
                             setResponseSize: !isError ? sizeof(responseData) : 0]
                            setRequestSize: !isError?requestBodySize : 0]
                           build];
    
    
    [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                        withCmdData:[httpData data]];
    
    
    return responseData;


//	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
//	if (*response)
//		[userInfo setObject:*response forKey:@"response"];
//	if (responseData && responseData.length > 0)
//		[userInfo setObject:responseData forKey:@"body"];
//	if (*error)
//		[userInfo setObject:*error forKey:@"error"];
//
//	[[NSNotificationCenter defaultCenter] postNotificationName:k_RECEIVED_RESPONSE object:nil userInfo:userInfo];

}

+ (NSURLConnection *)mtinspected_connectionWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate
{
	// connectionWithRequest:delegate calls initWithRequest:delegate internally, so no need to proxy the delegate.
	return [NSURLConnection mtinspected_connectionWithRequest:request delegate:delegate];
}

+ (void)mtinspected_sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
	postSendingRequestNotification;
     NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    [NSURLConnection mtinspected_sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        
        NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
        double cast = (end - start) * 1000;
        
        LetAPMLOG(@"[NSURLConnection sendAsynchronousRequest] error:%@  [Url:%@]  RecvDataSize:%ld CASTTIME:%f", connectionError, request.URL, (unsigned long)[data length], cast);
        
        int32_t requestBodySize = sizeof(request.HTTPBody);
        
        HttpError * httpError = nil;
        
        httpError = [[[[[[HttpError builder] setErrorCode:0] setErrorMessage:@""] setErrorType:0] setResponseContent:@""] build];
        
        if (response == nil && connectionError != nil)
        {
            httpError = [[[[[[HttpError builder] setErrorCode:(int32_t)[connectionError code]]
                            setErrorMessage:[connectionError description]]
                           setErrorType:HttpErrorTypeHttpErrorTypeNetwork]
                          setResponseContent:@""] build];
        }
        else
        {
            LetAPMLOG(@"response:%@", response);
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
        
        HttpData * httpData = [[[[[[[HttpData builder] setUrl:[request.URL absoluteString]]
                                   setCastTime:cast]
                                  setError:httpError]
                                 setResponseSize: connectionError == nil ? sizeof(data) : 0]
                                setRequestSize: connectionError==nil?requestBodySize : 0]
                               build];
        
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeHttpData
                                            withCmdData:[httpData data]];
        
        handler(response, data, connectionError);
    }];
}

// ------------------------------------------------------------------------
#pragma mark -
#pragma mark Instance method swizzling

- (id)mtinspected_initWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate
{
	postSendingRequestNotification;
	MtInspectedConnectionDelegate *inspectedDelegate = [[MtInspectedConnectionDelegate alloc] initWithActualDelegate:delegate];
    
    if ([NSURLConnection inspectedDelegates] &&
        inspectedDelegate) {
        @try {
            [[NSURLConnection inspectedDelegates] addObject:inspectedDelegate];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        
    } else {
        
    }

	
	return [self mtinspected_initWithRequest:request delegate:inspectedDelegate];
}

- (id)mtinspected_initWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate startImmediately:(BOOL)startImmediately
{
	postSendingRequestNotification;
	MtInspectedConnectionDelegate *inspectedDelegate = [[MtInspectedConnectionDelegate alloc] initWithActualDelegate:delegate];
    
    if ([NSURLConnection inspectedDelegates] &&
        inspectedDelegate) {
        @try {
            [[NSURLConnection inspectedDelegates] addObject:inspectedDelegate];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        
    } else {
        
    }
	
	return [self mtinspected_initWithRequest:request delegate:inspectedDelegate startImmediately:startImmediately];
}
#undef postSendingRequestNotification

// ------------------------------------------------------------------------
#pragma mark -
#pragma mark Method swizzling magics.
+ (void) MtswizzleClassMethod:(SEL)from to:(SEL)to
{
	NSError *error = nil;
	BOOL swizzled = [NSURLConnection mtjr_swizzleClassMethod:from withClassMethod:to error:&error];
	if (!swizzled || error) {
	}
}

+ (void) MtswizzleMethod:(SEL)from to:(SEL)to
{
	NSError *error = nil;
	BOOL swizzled = [NSURLConnection mtjr_swizzleMethod:from withMethod:to error:&error];
	if (!swizzled || error) {
	}
}

static BOOL s_inspectionEnabled = NO;

+ (void) setInspectionMt:(BOOL)enabled
{
	if (s_inspectionEnabled == enabled)
		return;

	s_inspectionEnabled = enabled;

#define mtinspected_method(method) mtinspected_##method
#define mtswizzle_class_method_wrap(method) [NSURLConnection MtswizzleClassMethod:@selector(method) to:@selector(mtinspected_method(method))]
#define mtswizzle_method_wrap(method) [NSURLConnection MtswizzleMethod:@selector(method) to:@selector(mtinspected_method(method))]

	mtswizzle_class_method_wrap(sendSynchronousRequest:returningResponse:error:);
	mtswizzle_class_method_wrap(connectionWithRequest:delegate:);
	mtswizzle_class_method_wrap(sendAsynchronousRequest:queue:completionHandler:);

	mtswizzle_method_wrap(initWithRequest:delegate:);
	mtswizzle_method_wrap(initWithRequest:delegate:startImmediately:);

#undef mtswizzle_method_wrap
#undef mtswizzle_class_method_wrap
#undef mtinspected_method
}

+ (BOOL) inspectionMtEnabled
{
	return s_inspectionEnabled;
}

@end