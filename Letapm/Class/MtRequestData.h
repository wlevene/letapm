//
//  RequestData.h
//  Letapm
//
//  Created by Gang.Wang on 10/6/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MtRequestData : NSObject

@property (nonatomic, strong) NSNumber * startTime;
@property (nonatomic, assign) UInt32 datasize;

@property (nonatomic, assign) UInt32 requestDataSize;
@property (nonatomic, strong) NSURLResponse *response;

@property (nonatomic, assign) BOOL needCopyRecvData;
@property (nonatomic, strong) NSMutableData *recvData;

@end
