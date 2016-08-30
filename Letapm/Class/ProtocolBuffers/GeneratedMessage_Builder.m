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

#import "GeneratedMessage_Builder.h"

#import "GeneratedMessage.h"
#import "Message.h"
#import "Message_Builder.h"
#import "UnknownFieldSet.h"
#import "UnknownFieldSet_Builder.h"


@interface BatPBGeneratedMessage ()
@property (retain) BatPBUnknownFieldSet* unknownFields;
@end


@implementation BatPBGeneratedMessage_Builder

/**
 * Get the message being built.  We don't just pass this to the
 * constructor because it becomes null when build() is called.
 */
- (BatPBGeneratedMessage*) internalGetResult {
  @throw [NSException exceptionWithName:@"ImproperSubclassing" reason:@"" userInfo:nil];
}


- (void) checkInitialized {
  BatPBGeneratedMessage* result = self.internalGetResult;
  if (result != nil && !result.isInitialized) {
    @throw [NSException exceptionWithName:@"UninitializedMessage" reason:@"" userInfo:nil];
  }
}


- (BatPBUnknownFieldSet*) unknownFields {
  return self.internalGetResult.unknownFields;
}


- (id<BatPBMessage_Builder>) setUnknownFields:(BatPBUnknownFieldSet*) unknownFields {
  self.internalGetResult.unknownFields = unknownFields;
  return self;
}


- (id<BatPBMessage_Builder>) mergeUnknownFields:(BatPBUnknownFieldSet*) unknownFields {
  BatPBGeneratedMessage* result = self.internalGetResult;
  result.unknownFields =
  [[[BatPBUnknownFieldSet builderWithUnknownFields:result.unknownFields]
    mergeUnknownFields:unknownFields] build];
  return self;
}


- (BOOL) isInitialized {
  return self.internalGetResult.isInitialized;
}


/**
 * Called by subclasses to parse an unknown field.
 * @return {@code YES} unless the tag is an end-group tag.
 */
- (BOOL) parseUnknownField:(BatPBCodedInputStream*) input
             unknownFields:(BatPBUnknownFieldSet_Builder*) unknownFields
         extensionRegistry:(BatPBExtensionRegistry*) extensionRegistry
                       tag:(int32_t) tag {
  return [unknownFields mergeFieldFrom:tag input:input];
}


- (void) checkInitializedParsed {
  BatPBGeneratedMessage* result = self.internalGetResult;
  if (result != nil && !result.isInitialized) {
    @throw [NSException exceptionWithName:@"InvalidProtocolBuffer" reason:@"" userInfo:nil];
  }
}

@end
