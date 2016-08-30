//
//  MtLetAPMRequestState.h
//  Letapm
//
//  Created by Gang.Wang on 12/28/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MtRequestData;

@interface MtRequestState : NSObject

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, strong) NSMutableData *dataAccumulator;
@property (nonatomic, strong) MtRequestData *requestData;

@end