//
//  BatCore.m
//  SwizzleDemo
//
//  Created by Gang.Wang on 5/28/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "LetapmCore.h"

#import "SocketMTSwizzle.h"

#import "LetapmDataDefault.h"
#import "ReachabilityLetapm.h"

#import "LetapmSystem.h"
#import <UIKit/UIKit.h>

#import "Letapm_OpenUDID.h"

#import "UIImage+MTSwizzle.h"
#import "UIViewController+MtSwizzleEx.h"
#import "sdk_def.h"

#import "MetricLogic.h"

#import "MtGCDAsyncSocket.h"
#import "NSURLConnection+MtInspected.h"

#import "UIWebView+MTSwizzleEx.h"

#import "MTBatteryLogic.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#import <MTFPSLogic.h>
#import "MtNSURLSessionSwizzle.h"


@interface LetapmCore ()<NSURLConnectionDelegate>

@property (nonatomic, strong) NSMutableArray * needSendQueue;
@property (nonatomic, assign) BOOL vailedAppKey;

@property (nonatomic, retain) ReachabilityLetapm * internetReachability;
@property (nonatomic, assign) BOOL exited;

@property (nonatomic, strong) NSString * appkey;
@property (nonatomic, strong) NSString * appsecret;

@property (nonatomic, strong) NSString * abimeServerIP;
@property (nonatomic, assign) int abimePort;

@property (nonatomic, strong) NSString * sessionID;
@property (nonatomic, assign) BOOL bInited;
@property (nonatomic, assign) BOOL pauseSend;

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) AppNetWorkStatus * net;

@property (nonatomic, strong) MtGCDAsyncSocket * asyncSocket;

@property (nonatomic, strong) NSMutableData * sdkServerData;

@property (nonatomic, assign) BOOL firstWatchSocket;

@end

@implementation LetapmCore

+ (LetapmCore *)sharedManager
{
    static LetapmCore *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}

-(NSString *) gen_uuid
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    
    CFRelease(uuid_string_ref);
    return uuid;
}

- (void) initWithAppKey:(NSString *) appKey withAppSecret:(NSString *) appSecret
{
    if (self.bInited) {
        return;
    }
    
    if (appKey == nil ||
        [appKey length] <= 0) {
        [self unInstallBatSDK];

        return ;
    }
    
    if (appSecret == nil ||
        [appSecret length] <= 0) {
        [self unInstallBatSDK];
        return ;
    }
    
    self.firstWatchSocket = YES;
    
    // invocation functions
//    [MtNSURLSessionSwizzle setEnabled:YES];
    [NSURLConnection setInspectionMt:YES];
    [UIWebView setInspectionMt:YES];
    
    self.appkey = appKey;
    self.appsecret = appSecret;
 
//    id socket = [[SocketMTSwizzle alloc] init];
//    if (socket)
//    {
//        // do nothing
//    }
    
    self.sessionID = [self gen_uuid];
    
    self.net = nil;
    
    self.lock = [[NSLock alloc] init];
    
    if ([self.lock tryLock]) {
        self.needSendQueue = [[NSMutableArray alloc] init];
        [self.lock unlock];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    //初始化
    self.internetReachability = [ReachabilityLetapm reachabilityForInternetConnection];
    
    //通知添加到Run Loop
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:_internetReachability];

    
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    self.asyncSocket = [[MtGCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
 
    self.pauseSend = YES;
    
    self.bInited = YES;
    
//    [MetricLogic sharedManager];
    
    NSString * sdkServer = SDKServer;
    if ([LetapmDataDefault sharedManager].sdkServer != nil &&
        [[LetapmDataDefault sharedManager].sdkServer length] > 0)
    {
        sdkServer = [LetapmDataDefault sharedManager].sdkServer;
    }
    
    
    // TODO... ios9默认要求使用https链接
    if ([[LetapmSystem iosVersion] floatValue] >= 9.0 && false)
    {
        sdkServer = SDKServerHttps;
        if ([LetapmDataDefault sharedManager].sdkHttpsServer != nil &&
            [[LetapmDataDefault sharedManager].sdkHttpsServer length] > 0)
        {
            sdkServer = [LetapmDataDefault sharedManager].sdkHttpsServer;
        }
    }
    
    NSString *urlStr = [NSString stringWithFormat:@"%@?appkey=%@&appsecret=%@&v=%@&device=%@",
                        sdkServer,
                        self.appkey,
                        self.appsecret,
                        LETAPM_VERSION,
                        [Letapm_OpenUDID value]];
    
    NSString *newStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:newStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
    
    self.sdkServerData = [[NSMutableData alloc] init];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
#pragma unused(connection)
    
    
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//
//        
//        
//        if (connectionError != nil)
//        {
//            
//            return [self unInstallBatSDK];
//        }
//        
//        if (data == nil) {
//
//            [self unInstallBatSDK];
//            return;
//        }
//        
//        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//        
//        // ret:1  rand:100 svr:x.x.x.x:6842
//        
//        if ([dic objectForKey:@"ret"] == nil) {
//            [self unInstallBatSDK];
//            return;
//        }
//        
//        int ret = [[dic objectForKey:@"ret"] intValue];
//        if (ret != 0) {
//            [self unInstallBatSDK];
//            return;
//        }
//        
//        int randNumber = [[dic objectForKey:@"rand"] intValue];
//        if (randNumber == 0) {
//            [self unInstallBatSDK];
//            return;
//        }
//
//        NSString * addr = [NSString stringWithFormat:@"%@", [dic objectForKey:@"svr"]];
//        
//        if (addr == nil ||
//            [addr length] <= 0)
//        {
//            [self unInstallBatSDK];
//            return;
//        }
//        
//        NSArray * arr = [addr componentsSeparatedByString:@":"];
//        
//        if (arr == nil || [arr count] != 2)
//        {
//            [self unInstallBatSDK];
//            return;
//        }
//        
//        self.abimeServerIP = arr[0];
//        NSString * portstr = arr[1];
//        self.abimePort = [portstr intValue];
//    }];
    
    

    
}

#pragma mark - Start Function

- (void) setLetapmWrokThread
{
    NSThread * watchSocketThread = [[NSThread alloc] initWithTarget:self
                                                           selector:@selector(watchSocketThreadFun)
                                                             object:nil];
    [watchSocketThread start];
    
    NSThread * sendDataThread = [[NSThread alloc] initWithTarget:self
                                                        selector:@selector(sendDataThreadFun)
                                                          object:nil];
    [sendDataThread start];
}



#pragma mark -



- (void) watchSocketThreadFun
{
    // 每 5s 检查一socket状态
    while (true) {
        
        if (self.firstWatchSocket) {
            [NSThread sleepForTimeInterval:5];
        }
        else {
            [NSThread sleepForTimeInterval:10];
        }
        
        if (self.exited) {
            return;
        }
        
        if (self.asyncSocket.isConnected) {
          
            if (!self.asyncSocket.isConnected) {
                LetAPMLOG(@"watchSocketThread isConnected:%d", self.asyncSocket.isConnected);
            }
            
            continue;
        }
        
        if (self.vailedAppKey) {
            
            LetAPMLOG(@"watchSocketThread vailedAppKey:%d", self.vailedAppKey);
            
            continue;
        }
        
        self.firstWatchSocket = NO;
        [self connentSocketToAbime];
    }
}

- (void) sendDataThreadFun
{
    while (YES) {
        
        [NSThread sleepForTimeInterval:0.5];
        
        if (self.exited) {
            return ;
        }
        
        if (self.pauseSend) {
            continue;
        }
        
        if (!self.asyncSocket.isConnected) {
            
            LetAPMLOG(@"sendDataThreadFun !self.connected is false continue it...");
            
            continue;
        }
        
        if (!self.vailedAppKey) {
            [NSThread sleepForTimeInterval:5];
            continue;
        }
        
        if (!self.needSendQueue ||
            [self.needSendQueue count] <= 0)
        {
            continue;
        }
        
        [self.lock lock];
        NSData * data = [[NSData alloc] initWithData:[self.needSendQueue firstObject]];
        
        if (data == nil )
        {
            [self.lock unlock];
            
            continue;
        }
        
        Byte *sendByte = (Byte *)[data bytes];
        if (sendByte == nil )
        {
            [self.lock unlock];
            continue;
        }
        
        NSData * sendData = [[NSData alloc] initWithBytes:sendByte length:[data length]];
        
        if (sendData == nil )
        {
            [self.lock unlock];
            continue;
        }
        
        
        [self.needSendQueue removeObjectAtIndex:0];
        [self.lock unlock];
        [self.asyncSocket writeData:sendData withTimeout:SOCKET_WRITE_TIMEOUT tag:0];
    }
}

- (void) connentSocketToAbime
{
    if (!self.bInited) {
        return;
    }
    
    if (!self.asyncSocket)
    {
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        
        self.asyncSocket = [[MtGCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
        
    }
    
    NSError * error = nil;

    
    if (self.abimeServerIP == nil ||
        [self.abimeServerIP length] <= 0) {
        return;
    }
    
    if (self.abimePort <= 0) {
        return;
    }
    
    
    LetAPMLOG(@"socket to %@:%d", self.abimeServerIP, self.abimePort);
    
    if (![self.asyncSocket connectToHost:self.abimeServerIP
                                  onPort:self.abimePort
                             withTimeout:SOCKET_CONNECT_TIMEOUT
                                   error:&error])
    {

        LetAPMLOG(@"connectToHost Error:%@", error);
    }
    
}

-(void) unInstallBatSDK
{
    if (!self.bInited) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(![self.asyncSocket isDisconnected])
    {
        [self.asyncSocket disconnect];
    }
    
//    [self.lock lock];
//    [self.needSendQueue removeAllObjects];
//    self.needSendQueue = nil;
//    [self.lock unlock];

    
    
    self.exited = YES;
    
    [self clearSocketStatus];
    
//    [NSURLConnection UninstallMTSwizzle];
//    [UIImage UninstallMTSwizzle];
//    [UIViewController UninstallMTSwizzle];
}


- (void) sendData:(NSData *) cmdData
{
    
}

- (void)reachabilityChanged:(NSNotification *)note
{
    ReachabilityLetapm *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[ReachabilityLetapm class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(ReachabilityLetapm *)curReach
{
    
//    AppNetWorkStatus * net = nil;
    
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus) {
        case NotReachable:

            LetAPMLOG(@"当前网络状态不可达");
            
            break;
            
        case ReachableViaWiFi:

            LetAPMLOG(@"当前网络状态为Wifi");
            
            self.net = [[[[AppNetWorkStatus builder] setNetworkName:@"wifi"] setCarrierName:@""]  build];
            break;
            
        case ReachableViaWWAN:

            LetAPMLOG(@"当前网络状态为3G");
            if ([[LetapmSystem iosVersion] floatValue] >= 7.0) {
                self.net = [[[[AppNetWorkStatus builder] setNetworkName:[self carrierStatus]] setCarrierName:[self getMobileOperatorsName]]  build];
            } else {
                self.net = [[[[AppNetWorkStatus builder] setNetworkName:@"3G"] setCarrierName:@""]  build];
            }
            
            break;
    }
    
    if (self.net)
    {
        NSData * sendData = [self.net data];
        [self sendProtocolWithCmd:CmdTypeUpdateNetworkStatus withCmdData:sendData];
    }
}


/**
 *  运营商网络状态
 *
 *  @return 网络状态
 */
- (NSString *) carrierStatus
{
    CTTelephonyNetworkInfo *info=[CTTelephonyNetworkInfo new];
    NSString *status=info.currentRadioAccessTechnology;
    
    if (status == nil || [status length] <= 0) {
        return @"UnKnow";
    }
    
    if([status isEqualToString:CTRadioAccessTechnologyCDMA1x]||[status isEqualToString:CTRadioAccessTechnologyGPRS])
        return @"2G";
    else if([status isEqualToString:CTRadioAccessTechnologyEdge])
        return @"Edge";
    else if([status isEqualToString:CTRadioAccessTechnologyLTE])
        return @"4G";
    else
        return @"3G";
}


//用来辨别设备所使用网络的运营商
- (NSString*)getMobileOperatorsName
{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    if (carrier == nil)
    {
        return @"";
    }
    
    NSString * countryCode = [carrier mobileCountryCode];
    NSString * networkCode = [carrier mobileNetworkCode];
//    switch (code.intValue) {
//        case 00:
//        case 02:
//        case 07:
//            return @"移动";
//        case 01:
//        case 06:
//            return @"联通";
//        case 03:
//        case 05:
//            return @"电信";
//        case 20:
//            return @"铁通";
//            break;
//        default:
//            break;
//    }
    // https://en.wikipedia.org/wiki/Mobile_country_code
    return [NSString stringWithFormat:@"%@:%@", countryCode, networkCode];
}

- (void) sessionToServer
{
    if (!self.bInited) {
        return;
    }
    
    SessionMessage_AppInfo * app = [[[[[SessionMessage_AppInfo builder] setAppVersion:[LetapmSystem VersionValue]] setName:[LetapmSystem projectName]] setPackageId:[LetapmSystem boundId]] build];
 
    if (!app) {
        return;
    }
    
    int width = [[UIScreen mainScreen] currentMode].size.width;
    int height = [[UIScreen mainScreen] currentMode].size.height;
    
    SessionMessage_DeviceInfo * device = [[[[[[[[SessionMessage_DeviceInfo builder] setDeviceId:[Letapm_OpenUDID value]] setDeviceName:[LetapmSystem platformString]] setOsName:[LetapmSystem systemName]] setOsVersion:[LetapmSystem iosVersion]] setRooted:NO] setScreenSize:[NSString stringWithFormat:@"%dx%d", width, height]] build];
    
    if (!device) {
        return;
    }
    
    SessionMessage * session = [[[[[[[SessionMessage builder] setAppkey:self.appkey] setApp:app] setDevice:device] setSessionId:self.sessionID ] setSdkVersion:LETAPM_VERSION ] build];
    
    if (!session) {
        return;
    }
    
    NSData * sendData = [session data];

    LetAPMLOG(@"send session");
    
    [self sendProtocolWithCmdNow:CmdTypeSession withCmdData:sendData];
    
    if (self.net)
    {
        sendData = [self.net data];
        [self sendProtocolWithCmd:CmdTypeUpdateNetworkStatus withCmdData:sendData];
    }
}

-(void) test
{
    [[LetapmDataDefault sharedManager]  startSendTask];
}

- (void) sendProtocolWithCmdNow:(CmdType) cmd withCmdData:(NSData *) cmdData{
    
    if (!self.bInited) {
        return;
    }
    
    if (cmdData == nil)
    {
        return;
    }
    
    int32_t size = CFSwapInt32((int)[cmdData length]);
    
    int16_t v = CFSwapInt16(1);
    int32_t protoID = CFSwapInt32(cmd);
    
    NSMutableData * data = [NSMutableData data];
    [data appendBytes:&size length:sizeof(size)];
    
   
    [data appendBytes:&v length:sizeof(v)];
    [data appendBytes:&protoID length:sizeof(protoID)];
    [data appendData:cmdData];
    
    if (data)
    { 
        Byte *sendByte = (Byte *)[data bytes];
        if (sendByte == nil )
        {
            return;
        }
        
        NSData * sendData = [[NSData alloc] initWithBytes:sendByte length:[data length]];
        
        if (sendData == nil )
        {
            return;
        }
        
        [self.asyncSocket writeData:sendData withTimeout:SOCKET_WRITE_TIMEOUT tag:0];
    }
    
}

- (void) sendProtocolWithCmd:(CmdType) cmd withCmdData:(NSData *) cmdData{
    
    if (!self.bInited) {
        return;
    }
    
    if (cmdData == nil || [cmdData length] <= 0)
    {
        return;
    }
    
    if (self.needSendQueue == nil) {
        
        if ([self.lock tryLock]) {
            self.needSendQueue = [[NSMutableArray alloc] init];
            [self.lock unlock];
        }
    }
    
    int32_t size = CFSwapInt32((int)[cmdData length]);
    int16_t protoVersion = CFSwapInt16(ProtocVersion);
    int32_t protoID = CFSwapInt32(cmd);
    
    NSMutableData * data = [NSMutableData data];
    [data appendBytes:&size length:sizeof(size)];
    [data appendBytes:&protoVersion length:sizeof(protoVersion)];
    [data appendBytes:&protoID length:sizeof(protoID)];
    [data appendData:cmdData];
    
    if (data)
    {
        [self.lock lock];
        
        if (self.needSendQueue.count >= SOCKET_QUEUE_MAX_LEN)
        {
            [self.needSendQueue removeObjectAtIndex:0];
        }
        
        [self.needSendQueue addObject:[NSData dataWithData:data]];
        [self.lock unlock];
    }
    
    return;
}

- (void) clearSocketStatus
{
    self.vailedAppKey = NO;
    self.pauseSend = YES;
}

-(void) handerProtocol:(NSData *) bufCopy
{
    if (bufCopy == nil ||
        [bufCopy length] <= 0 ) {
        return;
    }
    
    int32_t protocolSize = 0;
    NSRange range;
    range.location = 0;
    range.length = 4;
    NSData * protocalSizeBuf = [bufCopy subdataWithRange:range];
    [protocalSizeBuf getBytes:&protocolSize length:sizeof(int32_t)];
    protocolSize = ntohl(protocolSize);
    
    
    int16_t protocolVersion = 0;
    
    range.location = 4;
    range.length = 2;
    NSData * protocalVersionBuf = [bufCopy subdataWithRange:range];
    [protocalVersionBuf getBytes:&protocolVersion length:sizeof(int16_t)];
    protocolVersion = ntohs(protocolVersion);
    
    int32_t protocolID = 0;
    
    range.location = 6;
    range.length = 4;
    NSData * protocalIDBuf = [bufCopy subdataWithRange:range];
    [protocalIDBuf getBytes:&protocolID length:sizeof(int32_t)];
    protocolID = ntohl(protocolID);
    
    LetAPMLOG(@"%d %d %d", protocolSize, protocolVersion, protocolID);
    
    
    range.location = 10;
    range.length = protocolSize;
    MessageReply * reply = [MessageReply parseFromData:[bufCopy subdataWithRange:range]];
    
    
    if (protocolID == CmdTypeSessionreply) {
        if (reply.ret == YES)
        {
            self.vailedAppKey = YES;
            self.pauseSend = NO;
            
            LetAPMLOG(@"reply.message:%@", reply.message);
            
            // {"metric":"1"}
            //            if (![reply.message isEqualToString:@"{\"metric\":\"1\"}"]) {
            //                [[MetricLogic sharedManager] startCollectThread];
            //            } else {
            //                [[MetricLogic sharedManager] stop];
            //            }
        }
        else
        {
            LetAPMLOG(@" app is invailed, close socket");
            
            [self.asyncSocket setDelegate:nil];
            [self.asyncSocket disconnect];
            self.asyncSocket = nil;
        }
    }
    
    LetAPMLOG(@"RecvData:%d %@ %d", reply.ret, reply.message, reply.probability);
    
}


#pragma mark - GCDAsyncSocket

- (void)socket:(MtGCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    
    LetAPMLOG(@"didConnectToHost %@:%d", host, port);

    [self sessionToServer];
    
    [self.asyncSocket readDataWithTimeout:SOCKET_READ_TIMEOUT tag:0];
}


- (void)socket:(MtGCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{

}

- (void)socket:(MtGCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    [self.asyncSocket readDataWithTimeout:SOCKET_READ_TIMEOUT tag:0];
    
    if (self.vailedAppKey)
    {
        return;
    }
    
    NSData * bufCopy = [[NSData alloc] initWithData:data];
    
    if ([bufCopy length] < 10)
    {
        return;
    }
    
    [self handerProtocol:bufCopy];
    
}

- (void)socketDidDisconnect:(MtGCDAsyncSocket *)sock withError:(NSError *)err
{
    LetAPMLOG(@"socketDidDisconnect:%p withError: %@", sock, err);
    
    [self clearSocketStatus];
}

#pragma mark - http
//- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
//
//{
//
//    
//    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
//    
//}

//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
//{
//    static CFArrayRef certs;
//    if (!certs) {
//        
////         NSFileManager *fileManager = [NSFileManager defaultManager];
////         NSArray *fileList = [[NSArray alloc] init];
////        
////        NSString* path = [NSString stringWithFormat:@"%@/Letapm.framework/letapm.bundle/test.png", [[NSBundle mainBundle] bundlePath]];
////        
////          fileList = [fileManager contentsOfDirectoryAtURL:[[NSBundle mainBundle] bundlePath] includingPropertiesForKeys:nil options:nil error:nil];
////        
//        
//        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"cert" ofType:@"pem"];
////        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
//        
//        NSData*certData =[NSData dataWithContentsOfFile:bundlePath];
//        
//        if (certData == nil) {
//            return;
//        }
//        
//        SecCertificateRef rootcert =SecCertificateCreateWithData(kCFAllocatorDefault,CFBridgingRetain(certData));
//        const void *array[1] = { rootcert };
//        certs = CFArrayCreate(NULL, array, 1, &kCFTypeArrayCallBacks);
//        CFRelease(rootcert);    // for completeness, really does not matter
//    }
//    
//    SecTrustRef trust = [[challenge protectionSpace] serverTrust];
//    int err;
//    SecTrustResultType trustResult = 0;
//    err = SecTrustSetAnchorCertificates(trust, certs);
//    if (err == noErr) {
//        err = SecTrustEvaluate(trust,&trustResult);
//    }
//    CFRelease(trust);
//    BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed)||(trustResult == kSecTrustResultConfirm) || (trustResult == kSecTrustResultUnspecified));
//    
//    if (trusted) {
//        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
//    }else{
//        [challenge.sender cancelAuthenticationChallenge:challenge];
//    }
//}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.sdkServerData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
   // TODO...
    if (self.sdkServerData == nil) {
        LetAPMLOG(@"---recved data is nil");

        [self unInstallBatSDK];
        return;
    }
    
    NSError * error = nil;

    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:self.sdkServerData options:NSJSONReadingMutableContainers error:&error];

   
    LetAPMLOG(@"%@", dic);
    
    self.sdkServerData = nil;
    
    if (error != nil) {
        [self unInstallBatSDK];
        return;
    }
    
    // ret:1  rand:100 svr:x.x.x.x:6842

    if ([dic objectForKey:@"ret"] == nil) {
        [self unInstallBatSDK];
        return;
    }

    int ret = [[dic objectForKey:@"ret"] intValue];
    if (ret != 0)
    {
        if (![LetapmDataDefault sharedManager].ForceEnableAppKey)
        {
            [self unInstallBatSDK];
            return;
        }
    }

    int randNumber = [[dic objectForKey:@"rand"] intValue];
    if (randNumber == 0) {
        [self unInstallBatSDK];
        return;
    }
    
    int rand = [self getRandomNumber:0 to:100];
    if (rand > randNumber) {
        [self unInstallBatSDK];
        return;
    }
    
    NSString * addr = [NSString stringWithFormat:@"%@", [dic objectForKey:@"svr"]];

    if (addr == nil ||
        [addr length] <= 0)
    {
        [self unInstallBatSDK];
        return;
    }

    NSArray * arr = [addr componentsSeparatedByString:@":"];

    if (arr == nil || [arr count] != 2)
    {
        [self unInstallBatSDK];
        return;
    }
    
    self.abimeServerIP = arr[0];
    NSString * portstr = arr[1];
    self.abimePort = [portstr intValue];
    
    // 开启功能
    [self setLetapmWrokThread];
    
    id batteryData = [dic objectForKey:@"battery"];
    if (batteryData != nil) {
        BOOL batteryCollecte = [batteryData boolValue];
        
        if ([LetapmDataDefault sharedManager].ForceCollectionBattery ||
            batteryCollecte) {
            LetAPMLOG(@"Open Battery");
            
            [[MTBatteryLogic sharedManager] startCollecter];
        }
        else{
            LetAPMLOG(@"Not Need TO Open Battery");
        }
    }
    
    //  fps 总开关
    id fpsData = [dic objectForKey:@"fps"];
    if (fpsData != nil) {
        
        BOOL reportFps = [fpsData boolValue];
        
        if ([LetapmDataDefault sharedManager].ForceReportFps ||
            reportFps)
        {
            LetAPMLOG(@"Open Normal Fps");
            [[MTFPSLogic sharedManager] startCollecter];
        }
    }
    
    //  正常normal fps 开关
    id normalfpsData = [dic objectForKey:@"normal_fps"];
    if (normalfpsData != nil) {
        
        BOOL reportNormalFps = [normalfpsData boolValue];
        
        if ([LetapmDataDefault sharedManager].ForceReportFps ||
            reportNormalFps)
        {
            LetAPMLOG(@"Open Normal Fps");
            [MTFPSLogic sharedManager].reportNormalFps = YES;
        }
    }
    
    //  获取calmity fps value
    id calamityFps = [dic objectForKey:@"calamity_fps"];
    if (calamityFps != nil) {
        
        [MTFPSLogic sharedManager].calamityFpsFlag = [calamityFps intValue];
        
        if ([MTFPSLogic sharedManager].calamityFpsFlag > 30) {
            [MTFPSLogic sharedManager].calamityFpsFlag = FPS_SNAPSHOT_VALUE;
        }
        
        LetAPMLOG(@" Fps Snapshot: %d", [MTFPSLogic sharedManager].calamityFpsFlag);
    }
}

//请求失败时调用此方法
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    LetAPMLOG(@"didFailWithError error:%@",[error description]);
    
    if (error != nil)
    {
        LetAPMLOG(@"data:%@", [[NSString alloc] initWithData:self.sdkServerData encoding:NSUTF8StringEncoding]) ;
        
//        return [self unInstallBatSDK];
    }
}


-(int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}

@end
