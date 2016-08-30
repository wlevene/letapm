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

#import "Message_Builder.h"

@class BatPBField;
@class BatPBMutableField;

@interface BatPBUnknownFieldSet_Builder : NSObject <BatPBMessage_Builder> {
@private
  NSMutableDictionary* fields;

  // Optimization:  We keep around a builder for the last field that was
  //   modified so that we can efficiently add to it multiple times in a
  //   row (important when parsing an unknown repeated field).
  int32_t lastFieldNumber;

  BatPBMutableField* lastField;
}

+ (BatPBUnknownFieldSet_Builder*) createBuilder:(BatPBUnknownFieldSet*) unknownFields;

- (BatPBUnknownFieldSet*) build;
- (BatPBUnknownFieldSet_Builder*) mergeUnknownFields:(BatPBUnknownFieldSet*) other;

- (BatPBUnknownFieldSet_Builder*) mergeFromCodedInputStream:(BatPBCodedInputStream*) input;
- (BatPBUnknownFieldSet_Builder*) mergeFromData:(NSData*) data;
- (BatPBUnknownFieldSet_Builder*) mergeFromInputStream:(NSInputStream*) input;
- (BatPBUnknownFieldSet_Builder*) mergeDelimitedFromInputStream:(NSInputStream*) input;

- (BatPBUnknownFieldSet_Builder*) mergeVarintField:(int32_t) number value:(int32_t) value;

- (BOOL) mergeFieldFrom:(int32_t) tag input:(BatPBCodedInputStream*) input;

- (BatPBUnknownFieldSet_Builder*) addField:(BatPBField*) field forNumber:(int32_t) number;

- (BatPBUnknownFieldSet_Builder*) clear;
- (BatPBUnknownFieldSet_Builder*) mergeField:(BatPBField*) field forNumber:(int32_t) number;

@end
