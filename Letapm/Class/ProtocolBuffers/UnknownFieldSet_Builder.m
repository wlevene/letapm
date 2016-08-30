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

#import "UnknownFieldSet_Builder.h"

#import "CodedInputStream.h"
#import "Field.h"
#import "MutableField.h"
#import "UnknownFieldSet.h"
#import "WireFormat.h"

@interface BatPBUnknownFieldSet_Builder ()
@property (retain) NSMutableDictionary* fields;
@property int32_t lastFieldNumber;
@property (retain) BatPBMutableField* lastField;
@end


@implementation BatPBUnknownFieldSet_Builder

@synthesize fields;
@synthesize lastFieldNumber;
@synthesize lastField;


- (void) dealloc {
  self.fields = nil;
  self.lastFieldNumber = 0;
  self.lastField = nil;

  [super dealloc];
}


- (id) init {
  if ((self = [super init])) {
    self.fields = [NSMutableDictionary dictionary];
  }
  return self;
}


+ (BatPBUnknownFieldSet_Builder*) createBuilder:(BatPBUnknownFieldSet*) unknownFields {
  BatPBUnknownFieldSet_Builder* builder = [[[BatPBUnknownFieldSet_Builder alloc] init] autorelease];
  [builder mergeUnknownFields:unknownFields];
  return builder;
}


/**
 * Add a field to the {@code PBUnknownFieldSet}.  If a field with the same
 * number already exists, it is removed.
 */
- (BatPBUnknownFieldSet_Builder*) addField:(BatPBField*) field forNumber:(int32_t) number {
  if (number == 0) {
    @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"" userInfo:nil];
  }
  if (lastField != nil && lastFieldNumber == number) {
    // Discard this.
    self.lastField = nil;
    lastFieldNumber = 0;
  }
  [fields setObject:field forKey:[NSNumber numberWithInt:number]];
  return self;
}


/**
 * Get a field builder for the given field number which includes any
 * values that already exist.
 */
- (BatPBMutableField*) getFieldBuilder:(int32_t) number {
  if (lastField != nil) {
    if (number == lastFieldNumber) {
      return lastField;
    }
    // Note:  addField() will reset lastField and lastFieldNumber.
    [self addField:lastField forNumber:lastFieldNumber];
  }
  if (number == 0) {
    return nil;
  } else {
    BatPBField* existing = [fields objectForKey:[NSNumber numberWithInt:number]];
    lastFieldNumber = number;
    self.lastField = [BatPBMutableField field];
    if (existing != nil) {
      [lastField mergeFromField:existing];
    }
    return lastField;
  }
}


- (BatPBUnknownFieldSet*) build {
  [self getFieldBuilder:0];  // Force lastField to be built.
  BatPBUnknownFieldSet* result;
  if (fields.count == 0) {
    result = [BatPBUnknownFieldSet defaultInstance];
  } else {
    result = [BatPBUnknownFieldSet setWithFields:fields];
  }
  self.fields = nil;
  return result;
}

- (BatPBUnknownFieldSet*) buildPartial {
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

- (BatPBUnknownFieldSet*) clone {
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

- (BOOL) isInitialized {
  return YES;
}

- (BatPBUnknownFieldSet*) defaultInstance {
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

- (BatPBUnknownFieldSet*) unknownFields {
  return [self build];
}

- (id<BatPBMessage_Builder>) setUnknownFields:(BatPBUnknownFieldSet*) unknownFields {
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

/** Check if the given field number is present in the set. */
- (BOOL) hasField:(int32_t) number {
  if (number == 0) {
    @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"" userInfo:nil];
  }

  return number == lastFieldNumber || ([fields objectForKey:[NSNumber numberWithInt:number]] != nil);
}


/**
 * Add a field to the {@code PBUnknownFieldSet}.  If a field with the same
 * number already exists, the two are merged.
 */
- (BatPBUnknownFieldSet_Builder*) mergeField:(BatPBField*) field forNumber:(int32_t) number {
  if (number == 0) {
    @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"" userInfo:nil];
  }
  if ([self hasField:number]) {
    [[self getFieldBuilder:number] mergeFromField:field];
  } else {
    // Optimization:  We could call getFieldBuilder(number).mergeFrom(field)
    // in this case, but that would create a copy of the PBField object.
    // We'd rather reuse the one passed to us, so call addField() instead.
    [self addField:field forNumber:number];
  }

  return self;
}


- (BatPBUnknownFieldSet_Builder*) mergeUnknownFields:(BatPBUnknownFieldSet*) other {
  if (other != [BatPBUnknownFieldSet defaultInstance]) {
    for (NSNumber* number in other.fields) {
      BatPBField* field = [other.fields objectForKey:number];
      [self mergeField:field forNumber:[number intValue]];
    }
  }
  return self;
}


- (BatPBUnknownFieldSet_Builder*) mergeFromData:(NSData*) data {
  BatPBCodedInputStream* input = [BatPBCodedInputStream streamWithData:data];
  [self mergeFromCodedInputStream:input];
  [input checkLastTagWas:0];
  return self;
}


- (BatPBUnknownFieldSet_Builder*) mergeFromData:(NSData*) data extensionRegistry:(BatPBExtensionRegistry*) extensionRegistry {
  BatPBCodedInputStream* input = [BatPBCodedInputStream streamWithData:data];
  [self mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
  [input checkLastTagWas:0];
  return self;
}


- (BatPBUnknownFieldSet_Builder*) mergeFromInputStream:(NSInputStream*) input {
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

- (BatPBUnknownFieldSet_Builder*) mergeFromInputStream:(NSInputStream*) input extensionRegistry:(BatPBExtensionRegistry*) extensionRegistry {
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

- (BatPBUnknownFieldSet_Builder*) mergeDelimitedFromInputStream:(NSInputStream*) input
{
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

- (BatPBUnknownFieldSet_Builder*) mergeVarintField:(int32_t) number value:(int32_t) value {
  if (number == 0) {
    @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"Zero is not a valid field number." userInfo:nil];
  }

  [[self getFieldBuilder:number] addVarint:value];
  return self;
}


/**
 * Parse a single field from {@code input} and merge it into this set.
 * @param tag The field's tag number, which was already parsed.
 * @return {@code NO} if the tag is an engroup tag.
 */
- (BOOL) mergeFieldFrom:(int32_t) tag input:(BatPBCodedInputStream*) input {
  int32_t number = PBWireFormatGetTagFieldNumber(tag);
  switch (PBWireFormatGetTagWireType(tag)) {
    case PBWireFormatVarint:
      [[self getFieldBuilder:number] addVarint:[input readInt64]];
      return YES;
    case PBWireFormatFixed64:
      [[self getFieldBuilder:number] addFixed64:[input readFixed64]];
      return YES;
    case PBWireFormatLengthDelimited:
      [[self getFieldBuilder:number] addLengthDelimited:[input readData]];
      return YES;
    case PBWireFormatStartGroup: {
      BatPBUnknownFieldSet_Builder* subBuilder = [BatPBUnknownFieldSet builder];
      [input readUnknownGroup:number builder:subBuilder];
      [[self getFieldBuilder:number] addGroup:[subBuilder build]];
      return YES;
    }
    case PBWireFormatEndGroup:
      return NO;
    case PBWireFormatFixed32:
      [[self getFieldBuilder:number] addFixed32:[input readFixed32]];
      return YES;
    default:
      @throw [NSException exceptionWithName:@"InvalidProtocolBuffer" reason:@"" userInfo:nil];
  }
}


/**
 * Parse an entire message from {@code input} and merge its fields into
 * this set.
 */
- (BatPBUnknownFieldSet_Builder*) mergeFromCodedInputStream:(BatPBCodedInputStream*) input {
  while (YES) {
    int32_t tag = [input readTag];
    if (tag == 0 || ![self mergeFieldFrom:tag input:input]) {
      break;
    }
  }
  return self;
}

- (BatPBUnknownFieldSet_Builder*) mergeFromCodedInputStream:(BatPBCodedInputStream*) input extensionRegistry:(BatPBExtensionRegistry*) extensionRegistry {
  @throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"" userInfo:nil];
}

- (BatPBUnknownFieldSet_Builder*) clear {
  self.fields = [NSMutableDictionary dictionary];
  self.lastFieldNumber = 0;
  self.lastField = nil;
  return self;
}

@end
