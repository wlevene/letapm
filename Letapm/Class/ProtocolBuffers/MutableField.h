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

#import "Field.h"

@class BatPBUnknownFieldSet;

@interface BatPBMutableField : BatPBField

+ (BatPBMutableField *)field;

- (BatPBMutableField *)mergeFromField:(BatPBField *)other;

- (BatPBMutableField *)clear;
- (BatPBMutableField *)addVarint:(int64_t)value;
- (BatPBMutableField *)addFixed32:(int32_t)value;
- (BatPBMutableField *)addFixed64:(int64_t)value;
- (BatPBMutableField *)addLengthDelimited:(NSData *)value;
- (BatPBMutableField *)addGroup:(BatPBUnknownFieldSet *)value;

@end