//
//  BatDataDefault.m
//  SwizzleDemo
//
//  Created by Gang.Wang on 6/1/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "LetapmDataDefault.h"
#import "LetapmCore.h"
#import "sdk_def.h"

@interface LetapmDataDefault ()

@property (nonatomic, strong) NSString * StorePath;
@property (nonatomic, assign) int saveIndex;
@property (nonatomic, assign) int sendIndex;

@end


@implementation LetapmDataDefault

+ (LetapmDataDefault *)sharedManager
{
    static LetapmDataDefault *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}


- (id) init
{
    self = [super init];
    if (self) {
        return self;
//        self.sendIndex = 0;
//        self.saveIndex = 0;
//        
//        self.StorePath = [NSHomeDirectory() stringByAppendingPathComponent:@"bat_q"];
//        [[NSFileManager defaultManager] createDirectoryAtPath:self.StorePath withIntermediateDirectories:YES attributes:nil error:nil];
//        NSLog(@"%@", self.StorePath);
//        
//        [self scanStoreAndSendIndex:self.StorePath];
//        
//        
//        
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//            for (;;)
//            {
//                sleep(1 * 60);
//                [self resetStoreAndSendIndexIfCan:self.StorePath];
//            }
//            
//        });
        
    }
    
    return self;
}

- (void) saveData:(NSData *)data
{
    if (!data) {
        return;
    }
    
    NSString * saveFileName = [self.StorePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.q", self.saveIndex++]];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [data writeToFile:saveFileName atomically:YES];
               
    });
}


- (void) clearOldFile
{
    
}

+ (void) delayMethodAdded
{
    sleep(METHOD_DELAY);
}

- (void) startSendTask
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        for (;;)
        {
            NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.StorePath error:nil];
            if (fileList == nil ||
                [fileList count] <= 0)
            {
                sleep(5);
                continue;
            }

            [self scanNeedSendFiles];
        }
    });
}


- (void) scanNeedSendFiles
{
    NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.StorePath error:nil];
    
    for (NSString * path in fileList) {
        
        BOOL isDir = NO;
        
        [[NSFileManager defaultManager] fileExistsAtPath:[self.StorePath stringByAppendingPathComponent:path] isDirectory:(&isDir)];
        
        if(isDir)
        {
            continue;
        }
        
        if ([[path pathExtension] isEqual:@"q"])
        {
            NSData * data = [NSData dataWithContentsOfFile:[self.StorePath stringByAppendingPathComponent:path]];
            if (data)
            {
                [[LetapmCore sharedManager] sendData:data];
            }
        }
    }
}


- (void) scanStoreAndSendIndex:(NSString *) folder_path
{
    NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder_path error:nil];
    
    for (NSString * path in fileList) {
       
        BOOL isDir = NO;
        
        
        [[NSFileManager defaultManager] fileExistsAtPath:[folder_path stringByAppendingPathComponent:path] isDirectory:(&isDir)];
        
        if(isDir)
        {
            continue;
        }
        
        if ([[path pathExtension] isEqual:@"q"])
        {
            NSString * fileName = [[path lastPathComponent] componentsSeparatedByString:@"."][0];
            
            int i = [fileName intValue];
            
            if (self.saveIndex < i)
            {
                self.saveIndex = i;
            }
            
            if (self.sendIndex > i)
            {
                self.sendIndex = i;
            }
        }
    }
}

- (void) resetStoreAndSendIndexIfCan:(NSString *) folder_path
{
    NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder_path error:nil];
    if (fileList == nil ||
        [fileList count] <= 0)
    {
        self.saveIndex = 0;
        self.sendIndex = 0;
    }
}

@end
