//
//  SocketMTSwizzle.m
//  SwizzleDemo
//
//  Created by Gang.Wang on 5/30/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "SocketMTSwizzle.h"

#import <mach/mach_time.h>
//#import "fishhook.h"
#import <dlfcn.h>
#import <CFNetwork/CFNetwork.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
#import "LetapmCore.h"

#import "LetapmDataDefault.h"
#import "sdk_def.h"

/*
 int	accept(int, struct sockaddr * __restrict, socklen_t * __restrict)
 __DARWIN_ALIAS_C(accept);
 int	bind(int, const struct sockaddr *, socklen_t) __DARWIN_ALIAS(bind);
 int	connect(int, const struct sockaddr *, socklen_t) __DARWIN_ALIAS_C( connect);
 int	getpeername(int, struct sockaddr * __restrict, socklen_t * __restrict)
 __DARWIN_ALIAS(getpeername);
 int	getsockname(int, struct sockaddr * __restrict, socklen_t * __restrict)
 __DARWIN_ALIAS(getsockname);
 int	getsockopt(int, int, int, void * __restrict, socklen_t * __restrict);
 int	listen(int, int) __DARWIN_ALIAS(listen);
 ssize_t	recv(int, void *, size_t, int) __DARWIN_ALIAS_C(recv);
 ssize_t	recvfrom(int, void *, size_t, int, struct sockaddr * __restrict,
 socklen_t * __restrict) __DARWIN_ALIAS_C(recvfrom);
 ssize_t	recvmsg(int, struct msghdr *, int) __DARWIN_ALIAS_C(recvmsg);
 ssize_t	send(int, const void *, size_t, int) __DARWIN_ALIAS_C(send);
 ssize_t	sendmsg(int, const struct msghdr *, int) __DARWIN_ALIAS_C(sendmsg);
 ssize_t	sendto(int, const void *, size_t,
 int, const struct sockaddr *, socklen_t) __DARWIN_ALIAS_C(sendto);
 int	setsockopt(int, int, int, const void *, socklen_t);
 int	shutdown(int, int);
 int	sockatmark(int) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
 int	socket(int, int, int);
 int	socketpair(int, int, int, int *) __DARWIN_ALIAS(socketpair);
 */

static NSMutableDictionary * sockfd_addr;

static CFSocketRef (*orig_CFSocketCreate)(CFAllocatorRef allocator, SInt32 protocolFamily, SInt32 socketType, SInt32 protocol, CFOptionFlags callBackTypes, CFSocketCallBack callout, const CFSocketContext *context);

static int (* orig_connect)(int, const struct sockaddr *, socklen_t);

static ssize_t (* orig_recv)(int , void * , size_t , int );
static ssize_t (* orig_recvfrom)(int, void *, size_t, int, struct sockaddr * __restrict,
                                 socklen_t * __restrict);

static ssize_t (* orig_send)(int, const void *, size_t, int);
static ssize_t (* orig_sendto)(int, const void *, size_t,
                               int, const struct sockaddr *, socklen_t);

static int (* orig_shutdown)(int, int);
static int (* orig_close)(int);



void save_original_symbols_bat() {
    orig_CFSocketCreate = dlsym(RTLD_DEFAULT, "CFSocketCreate");
    orig_connect = dlsym(RTLD_DEFAULT, "connect");
    
    orig_recv = dlsym(RTLD_DEFAULT, "recv");
    orig_recvfrom = dlsym(RTLD_DEFAULT, "recvfrom");
    
    orig_send = dlsym(RTLD_DEFAULT, "send");
    orig_sendto = dlsym(RTLD_DEFAULT, "sendto");
    
//    orig_shutdown = dlsym(RTLD_DEFAULT, "shutdown");
//    orig_close = dlsym(RTLD_DEFAULT, "close");
}

int batClose(int fd)
{
    
    uint64_t start = mach_absolute_time ();
    
    int ret = orig_close(fd);
    
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    
    double cast = (double)elapsed/NSEC_PER_MSEC;

    
    if (ret < 0)
    {
        if (IsShowLog) {
            NSLog(@"[BatSDK] recv error:%d %@", errno, [NSString stringWithUTF8String:strerror(errno)]);
        }
        
    }
    
    
    NSString * remoteAddr = [sockfd_addr objectForKey:[NSNumber numberWithInt:fd]];
    
    if (IsShowLog) {
        NSLog(@"[BatSDK] %d shutdown:%@ CastTime:%f",[NSThread isMainThread], remoteAddr,  cast);
    }
    
    
    return ret;
}


int batShutdown(int sockfd, int how)
{
    time_t start_time,end_time;
    start_time = clock();
    
    int ret = orig_shutdown(sockfd, how);
    
    end_time = clock();
    
    double cost_time;
    cost_time = (double)(end_time-start_time)/CLOCKS_PER_SEC;
    
    
    if (ret < 0)
    {
        if (IsShowLog) {
            NSLog(@"[BatSDK] recv error:%d %@", errno, [NSString stringWithUTF8String:strerror(errno)]);

        }
    }
    
    
    NSString * remoteAddr = [sockfd_addr objectForKey:[NSNumber numberWithInt:sockfd]];
    
    if (IsShowLog) {
        NSLog(@"[BatSDK] %d shutdown:%@ CastTime:%f",[NSThread isMainThread], remoteAddr,  cost_time);
    }
    
    
    
    return ret;
}


ssize_t	batRecv(int sockfd, void * p, size_t s, int j)
{
    uint64_t start = mach_absolute_time ();
    
    ssize_t ret = orig_recv(sockfd, p, s, j);
    
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    
    double cast = (double)elapsed/NSEC_PER_MSEC;
    
    MTRemoteAddr * remoteAddr = [sockfd_addr objectForKey:[NSNumber numberWithInt:sockfd]];
    
    if (remoteAddr.remoteIP == nil ||
        [remoteAddr.remoteIP length] <= 0)
    {
        return ret;
    }
    
    SocketSendRecvData * sendRecvData = nil;
    
    if (ret < 0)
    {
        if (errno != EINTR && errno != EWOULDBLOCK && errno != EAGAIN) {
            
        }
        else
        {
            if (IsShowLog) {
                NSLog(@"[BatSDK] recv error:%d %@", errno,  [NSString stringWithUTF8String:strerror(errno)]);
            }
            
            sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:errno] setErronMesage:[NSString stringWithUTF8String:strerror(errno)]] setMethodName:@"recv"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;

        }
    }
    else
    {
        sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:0] setErronMesage:@""] setMethodName:@"recv"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;
    }
    
    if (sendRecvData)
    {
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeSocketSendrecvData withCmdData:[sendRecvData data]];
    }
    
     if (IsShowLog) {
         NSLog(@"[BatSDK] %d Recv:%@ Size:%d CastTime:%f",[NSThread isMainThread], remoteAddr, (int)s, cast);
     }
    
    
    
    return ret;
}

ssize_t	batRecvfrom(int sockfd, void * p, size_t s, int j, struct sockaddr * __restrict addr,
                    socklen_t * __restrict socklen)
{
    uint64_t start = mach_absolute_time ();
    
    ssize_t ret = orig_recvfrom(sockfd, p, s, j, addr, socklen);
    
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    
    double cast = (double)elapsed/NSEC_PER_MSEC;
    
    MTRemoteAddr * remoteAddr = [sockfd_addr objectForKey:[NSNumber numberWithInt:sockfd]];
    
    if (remoteAddr.remoteIP == nil ||
        [remoteAddr.remoteIP length] <= 0)
    {
        return ret;
    }
    
    SocketSendRecvData * sendRecvData = nil;

    if(ret < 0)
    {
        if(errno != EINTR && errno != EAGAIN)//这里
        {
            if (IsShowLog) {
                NSLog(@"[BatSDK] recvfrom error:%d %@", errno, [NSString stringWithUTF8String:strerror(errno)]);
            }
            
            sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:errno] setErronMesage:[NSString stringWithUTF8String:strerror(errno)]] setMethodName:@"recvfrom"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;

        }
        
    }
    else
    {
        sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:0] setErronMesage:@""] setMethodName:@"recvfrom"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;
    }
    
    if (sendRecvData)
    {
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeSocketSendrecvData withCmdData:[sendRecvData data]];
    }
    
    if (IsShowLog) {
        NSLog(@"[BatSDK] %d Recvfrom:%@ Size:%d CastTime:%f", [NSThread isMainThread], remoteAddr, (int)s, cast);

    }
    
    
    return ret;
}

ssize_t	batSend(int sockfd, void * p, size_t s, int j)
{
    
    uint64_t start = mach_absolute_time ();
    
    ssize_t ret = orig_send(sockfd, p, s, j);
    
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    
    double cast = (double)elapsed/NSEC_PER_MSEC;
    
    MTRemoteAddr * remoteAddr = [sockfd_addr objectForKey:[NSNumber numberWithInt:sockfd]];
    
    if (remoteAddr.remoteIP == nil ||
        [remoteAddr.remoteIP length] <= 0)
    {
        return ret;
    }
    
    SocketSendRecvData * sendRecvData = nil;

    
    //    (r == -1 && (errno == EINTR || errno == EAGAIN))
    if(ret < 0)
    {
        if(errno != EINTR && errno != EAGAIN)//这里
        {
            if (IsShowLog) {
                NSLog(@"[BatSDK] send error:%d %@", errno,  [NSString stringWithUTF8String:strerror(errno)]);

            }
                         sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:errno] setErronMesage:[NSString stringWithUTF8String:strerror(errno)]] setMethodName:@"send"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;
        }
        
    }
    else
    {
        sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:0] setErronMesage:@""] setMethodName:@"send"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;
    }
    
    if (sendRecvData)
    {
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeSocketSendrecvData withCmdData:[sendRecvData data]];
    }
    
    if (IsShowLog) {
        NSLog(@"[BatSDK] %d Send:%@ Size:%d CastTime:%f", [NSThread isMainThread], remoteAddr, (int)s, cast);
    }
    
    return ret;
}

ssize_t batSendto(int sockfd, const void * p, size_t s ,
                  int j, const struct sockaddr * addr, socklen_t socklen)
{
    
    uint64_t start = mach_absolute_time ();
    
    ssize_t ret = orig_sendto(sockfd, p, s, j, addr, socklen);
    
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    
    double cast = (double)elapsed/NSEC_PER_MSEC;
    
    MTRemoteAddr * remoteAddr = [sockfd_addr objectForKey:[NSNumber numberWithInt:sockfd]];
    
    if (remoteAddr.remoteIP == nil ||
        [remoteAddr.remoteIP length] <= 0)
    {
        return ret;
    }
    
    SocketSendRecvData * sendRecvData = nil;
    if(ret < 0)
    {
        if(errno != EINTR && errno != EAGAIN)//这里
        {
            if (IsShowLog) {
                NSLog(@"[BatSDK] sendto error:%d %@", errno, [NSString stringWithUTF8String:strerror(errno)]);
            }
            
            
           sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:errno] setErronMesage:[NSString stringWithUTF8String:strerror(errno)]] setMethodName:@"sendto"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;
            
        }
    }
    else
    {
        sendRecvData = [[[[[[[[[SocketSendRecvData builder] setCastTime:cast] setErrnoCode:0] setErronMesage:@""] setMethodName:@"sendto"] setRemoteIp:remoteAddr.remoteIP] setRemotePort:remoteAddr.port] setDataSize:(int32_t)s] build] ;
    }
    
    if (sendRecvData)
    {
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeSocketSendrecvData withCmdData:[sendRecvData data]];
    }
    
    if (IsShowLog) {
        NSLog(@"[BatSDK] %d SendTo:%@ Size:%d CastTime:%f", [NSThread isMainThread], remoteAddr, (int)s, cast);
    }
    
    return ret;
}


int	batConnect(int sockfd, const struct sockaddr * serv_addr, socklen_t addrlen)
{
    if (sockfd_addr == nil)
    {
        sockfd_addr = [[NSMutableDictionary alloc] init];
    }
    
    struct sockaddr_in sin;
    memcpy(&sin, serv_addr, sizeof(sin));
    
    
//    NSString * addrStr = [NSString stringWithFormat:@"%@:%d", [NSString stringWithUTF8String:inet_ntoa(sin.sin_addr)],
//                          ntohs(sin.sin_port)];
    
    MTRemoteAddr * remoteAddr = [[MTRemoteAddr alloc] init];
    remoteAddr.remoteIP = [NSString stringWithUTF8String:inet_ntoa(sin.sin_addr)];
    remoteAddr.port = ntohs(sin.sin_port);
    
    [sockfd_addr setObject:remoteAddr forKey:[NSNumber numberWithInt:sockfd]];
    
    
    uint64_t start = mach_absolute_time ();
    
    int ret = orig_connect(sockfd, serv_addr, addrlen);
    
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;
    
    double cast = (double)elapsed/NSEC_PER_MSEC;
    
    
    SocketConnect * socketConn = nil;
    
    NSString * errorMsg = nil;
    
    if (ret != 0)
    {
        if (errno == EINPROGRESS)
        {
            if (IsShowLog) {
                NSLog(@"[BatSDK] socket is connecting...");
            }
            
        }
        else
        {
            errorMsg = [NSString stringWithUTF8String:strerror(errno)];
             if (IsShowLog) {
                 NSLog(@"[BatSDK] connect error:%d %@",errno,  errorMsg);
             }
            
            
            socketConn = [[[[[[[SocketConnect builder] setRemoteIp:[NSString stringWithUTF8String:inet_ntoa(sin.sin_addr)]] setRemotePort:ntohs(sin.sin_port)] setCastTime:cast] setErrnoCode:errno] setErronMesage:errorMsg] build];
        }
    }
    else
    {
        if (IsShowLog) {
            NSLog(@"[BatSDK] connect success!");
        }
        socketConn = [[[[[[[SocketConnect builder] setRemoteIp:[NSString stringWithUTF8String:inet_ntoa(sin.sin_addr)]] setRemotePort:ntohs(sin.sin_port)] setCastTime:cast] setErrnoCode:0] setErronMesage:@"connect success!"] build];
    }
    
    if (IsShowLog) {
        NSLog(@"[BatSDK] %d %@:%d CastTime:%f", [NSThread isMainThread], [NSString stringWithUTF8String:inet_ntoa(sin.sin_addr)],
          ntohs(sin.sin_port), cast);
    }
    
    
    if (socketConn) {
        
        [[LetapmCore sharedManager] sendProtocolWithCmd:CmdTypeSocketConnect withCmdData:[socketConn data]];
    }
    
    
    
    return ret;
}

@implementation SocketMTSwizzle


- (id) init
{
    self = [super init];
    if (self)
    {
        save_original_symbols_bat();
        rebind_symbols((struct rebinding[5]){
            /*{"shutdown", batShutdown},*/
            {"connect", batConnect},
            {"recv", batRecv},
            {"recvfrom", batRecvfrom},
            {"send", batSend},
            {"sendto", batSendto},
            /*{"close", batClose}*/}, 5);
        
    }
    return self;
}


@end

@implementation MTRemoteAddr
@end

