// Protocol Buffers for Objective C
//
// Copyright 2010 Booyah Inc.
// Copyright 2008 Cyrus Najmabadi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "AbstractMessage_Builder.h"

#import "CodedInputStream.h"
#import "ExtensionRegistry.h"
#import "Message_Builder.h"
#import "UnknownFieldSet.h"
#import "UnknownFieldSet_Builder.h"

@implementation BatPBAbstractMessage_Builder

- (id<BatPBMessage_Builder>) clone {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<BatPBMessage_Builder>) clear {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<BatPBMessage_Builder>) mergeFromCodedInputStream:(BatPBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[BatPBExtensionRegistry emptyRegistry]];
}


- (id<BatPBMessage_Builder>) mergeFromCodedInputStream:(BatPBCodedInputStream*) input
                                  extensionRegistry:(BatPBExtensionRegistry*) extensionRegistry {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<BatPBMessage_Builder>) mergeUnknownFields:(BatPBUnknownFieldSet*) unknownFields {
  BatPBUnknownFieldSet* merged =
  [[[BatPBUnknownFieldSet builderWithUnknownFields:self.unknownFields]
    mergeUnknownFields:unknownFields] build];

  [self setUnknownFields:merged];
  return self;
}


- (id<BatPBMessage_Builder>) mergeFromData:(NSData*) data {
  BatPBCodedInputStream* input = [BatPBCodedInputStream streamWithData:data];
  [self mergeFromCodedInputStream:input];
  [input checkLastTagWas:0];
  return self;
}


- (id<BatPBMessage_Builder>) mergeFromData:(NSData*) data
                      extensionRegistry:(BatPBExtensionRegistry*) extensionRegistry {
  BatPBCodedInputStream* input = [BatPBCodedInputStream streamWithData:data];
  [self mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
  [input checkLastTagWas:0];
  return self;
}


- (id<BatPBMessage_Builder>) mergeFromInputStream:(NSInputStream*) input {
  BatPBCodedInputStream* codedInput = [BatPBCodedInputStream streamWithInputStream:input];
  [self mergeFromCodedInputStream:codedInput];
  [codedInput checkLastTagWas:0];
  return self;
}


- (id<BatPBMessage_Builder>) mergeFromInputStream:(NSInputStream*) input
                             extensionRegistry:(BatPBExtensionRegistry*) extensionRegistry {
  BatPBCodedInputStream* codedInput = [BatPBCodedInputStream streamWithInputStream:input];
  [self mergeFromCodedInputStream:codedInput extensionRegistry:extensionRegistry];
  [codedInput checkLastTagWas:0];
  return self;
}

- (id<BatPBMessage_Builder>) mergeDelimitedFromInputStream:(NSInputStream*) input
{
    u_int8_t firstByte;
    if ([input read:&firstByte maxLength:1] != 1) {
        return nil;
    }

    int size = [BatPBCodedInputStream readRawVarint32:firstByte withInputStream:input];
    NSMutableData *data = [NSMutableData dataWithLength:size];
    [input read:[data mutableBytes] maxLength:size];
    return [self mergeFromData:data];
}

- (id<BatPBMessage>) build {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<BatPBMessage>) buildPartial {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (BOOL) isInitialized {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<BatPBMessage>) defaultInstance {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (BatPBUnknownFieldSet*) unknownFields {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (id<BatPBMessage_Builder>) setUnknownFields:(BatPBUnknownFieldSet*) unknownFields {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}

@end
