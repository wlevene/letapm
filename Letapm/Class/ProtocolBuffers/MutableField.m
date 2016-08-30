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

#import "MutableField.h"

#import "Field.h"
#import "BatPBArray.h"

@implementation BatPBMutableField

- (void)dealloc {
	[super dealloc];
}

+ (BatPBMutableField *)field {
	return [[[BatPBMutableField alloc] init] autorelease];
}

- (BatPBMutableField *)clear {
	[_varintArray release];		_varintArray = nil;
	[_fixed32Array release];	_fixed32Array = nil;
	[_fixed64Array release];	_fixed64Array = nil;
	[_lengthDelimitedArray release];	_lengthDelimitedArray = nil;
	[_groupArray release];		_groupArray = nil;

	return self;
}

- (BatPBMutableField *)mergeFromField:(BatPBField *)other {
	if (other.varintArray.count > 0) {
		if (_varintArray == nil) {
			_varintArray = [other.varintArray copy];
		} else {
			[_varintArray appendArray:other.varintArray];
		}
	}

	if (other.fixed32Array.count > 0) {
		if (_fixed32Array == nil) {
			_fixed32Array = [other.fixed32Array copy];
		} else {
			[_fixed32Array appendArray:other.fixed32Array];
		}
	}

	if (other.fixed64Array.count > 0) {
		if (_fixed64Array == nil) {
			_fixed64Array = [other.fixed64Array copy];
		} else {
			[_fixed64Array appendArray:other.fixed64Array];
		}
	}

	if (other.lengthDelimitedArray.count > 0) {
		if (_lengthDelimitedArray == nil) {
			_lengthDelimitedArray = [other.lengthDelimitedArray copy];
		} else {
			[_lengthDelimitedArray appendArray:other.lengthDelimitedArray];
		}
	}

	if (other.groupArray.count > 0) {
		if (_groupArray == nil) {
			_groupArray = [other.groupArray copy];
		} else {
			[_groupArray appendArray:other.groupArray];
		}
	}

	return self;
}

- (BatPBMutableField *)addVarint:(int64_t)value {
	if (_varintArray == nil) {
		_varintArray = [[BatPBAppendableArray alloc] initWithValueType:PBArrayValueTypeInt64];
	}
	[_varintArray addInt64:value];

	return self;
}

- (BatPBMutableField *)addFixed32:(int32_t)value {
	if (_fixed32Array == nil) {
		_fixed32Array = [[BatPBAppendableArray alloc] initWithValueType:PBArrayValueTypeInt32];
	}
	[_fixed32Array addInt32:value];

	return self;
}

- (BatPBMutableField *)addFixed64:(int64_t)value {
	if (_fixed64Array == nil) {
		_fixed64Array = [[BatPBAppendableArray alloc] initWithValueType:PBArrayValueTypeInt64];
	}
	[_fixed64Array addInt64:value];

	return self;
}

- (BatPBMutableField *)addLengthDelimited:(NSData *)value {
	if (_lengthDelimitedArray == nil) {
		_lengthDelimitedArray = [[BatPBAppendableArray alloc] initWithValueType:PBArrayValueTypeObject];
	}
	[_lengthDelimitedArray addObject:value];

	return self;
}

- (BatPBMutableField *)addGroup:(BatPBUnknownFieldSet *)value {
	if (_groupArray == nil) {
		_groupArray = [[BatPBAppendableArray alloc] initWithValueType:PBArrayValueTypeObject];
	}
	[_groupArray addObject:value];

	return self;
}

@end