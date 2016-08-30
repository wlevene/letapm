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

#import "UnknownFieldSet.h"

#import "CodedInputStream.h"
#import "CodedOutputStream.h"
#import "Field.h"
#import "UnknownFieldSet_Builder.h"

@interface BatPBUnknownFieldSet()
@property (retain) NSDictionary* fields;
@end


@implementation BatPBUnknownFieldSet

static BatPBUnknownFieldSet* defaultInstance = nil;

+ (void) initialize {
  if (self == [BatPBUnknownFieldSet class]) {
    defaultInstance = [[BatPBUnknownFieldSet setWithFields:[NSMutableDictionary dictionary]] retain];
  }
}


@synthesize fields;

- (void) dealloc {
  self.fields = nil;

  [super dealloc];
}


+ (BatPBUnknownFieldSet*) defaultInstance {
  return defaultInstance;
}


- (id) initWithFields:(NSMutableDictionary*) fields_ {
  if ((self = [super init])) {
    self.fields = fields_;
  }

  return self;
}


+ (BatPBUnknownFieldSet*) setWithFields:(NSMutableDictionary*) fields {
  return [[[BatPBUnknownFieldSet alloc] initWithFields:fields] autorelease];
}


- (BOOL) hasField:(int32_t) number {
  return [fields objectForKey:[NSNumber numberWithInt:number]] != nil;
}


- (BatPBField*) getField:(int32_t) number {
  BatPBField* result = [fields objectForKey:[NSNumber numberWithInt:number]];
  return (result == nil) ? [BatPBField defaultInstance] : result;
}


- (void) writeToCodedOutputStream:(BatPBCodedOutputStream*) output {
  NSArray* sortedKeys = [fields.allKeys sortedArrayUsingSelector:@selector(compare:)];
  for (NSNumber* number in sortedKeys) {
    BatPBField* value = [fields objectForKey:number];
    [value writeTo:number.intValue output:output];
  }
}


- (void) writeToOutputStream:(NSOutputStream*) output {
  BatPBCodedOutputStream* codedOutput = [BatPBCodedOutputStream streamWithOutputStream:output];
  [self writeToCodedOutputStream:codedOutput];
  [codedOutput flush];
}


- (void) writeDescriptionTo:(NSMutableString*) output
                 withIndent:(NSString *)indent {
  NSArray* sortedKeys = [fields.allKeys sortedArrayUsingSelector:@selector(compare:)];
  for (NSNumber* number in sortedKeys) {
    BatPBField* value = [fields objectForKey:number];
    [value writeDescriptionFor:number.intValue to:output withIndent:indent];
  }
}


+ (BatPBUnknownFieldSet*) parseFromCodedInputStream:(BatPBCodedInputStream*) input {
  return [[[BatPBUnknownFieldSet builder] mergeFromCodedInputStream:input] build];
}


+ (BatPBUnknownFieldSet*) parseFromData:(NSData*) data {
  return [[[BatPBUnknownFieldSet builder] mergeFromData:data] build];
}


+ (BatPBUnknownFieldSet*) parseFromInputStream:(NSInputStream*) input {
  return [[[BatPBUnknownFieldSet builder] mergeFromInputStream:input] build];
}


+ (BatPBUnknownFieldSet_Builder*) builder {
  return [[[BatPBUnknownFieldSet_Builder alloc] init] autorelease];
}


+ (BatPBUnknownFieldSet_Builder*) builderWithUnknownFields:(BatPBUnknownFieldSet*) copyFrom {
  return [[BatPBUnknownFieldSet builder] mergeUnknownFields:copyFrom];
}


/** Get the number of bytes required to encode this set. */
- (int32_t) serializedSize {
  int32_t result = 0;
  for (NSNumber* number in fields) {
    result += [[fields objectForKey:number] getSerializedSize:number.intValue];
  }
  return result;
}

/**
 * Serializes the set and writes it to {@code output} using
 * {@code MessageSet} wire format.
 */
- (void) writeAsMessageSetTo:(BatPBCodedOutputStream*) output {
  for (NSNumber* number in fields) {
    [[fields objectForKey:number] writeAsMessageSetExtensionTo:number.intValue output:output];
  }
}


/**
 * Get the number of bytes required to encode this set using
 * {@code MessageSet} wire format.
 */
- (int32_t) serializedSizeAsMessageSet {
  int32_t result = 0;
  for (NSNumber* number in fields) {
    result += [[fields objectForKey:number] getSerializedSizeAsMessageSetExtension:number.intValue];
  }
  return result;
}


/**
 * Serializes the message to a {@code ByteString} and returns it. This is
 * just a trivial wrapper around {@link #writeTo(PBCodedOutputStream)}.
 */
- (NSData*) data {
  NSMutableData* data = [NSMutableData dataWithLength:self.serializedSize];
  BatPBCodedOutputStream* output = [BatPBCodedOutputStream streamWithData:data];

  [self writeToCodedOutputStream:output];
  return data;
}

@end
