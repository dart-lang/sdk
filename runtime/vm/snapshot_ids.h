// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SNAPSHOT_IDS_H_
#define VM_SNAPSHOT_IDS_H_

#include "vm/raw_object.h"

namespace dart {

// Index for predefined singleton objects used in a snapshot.
enum {
  kNullObject = 0,
  kSentinelObject,
  kEmptyArrayObject,
  kTrueValue,
  kFalseValue,
  kClassIdsOffset = kFalseValue,

  // The class ids of predefined classes are included in this list
  // at an offset of kClassIdsOffset.

  kObjectType = (kNumPredefinedCids + kClassIdsOffset),
  kNullType,
  kDynamicType,
  kVoidType,
  kFunctionType,
  kNumberType,
  kDoubleInterface,
  kIntInterface,
  kBoolInterface,
  kStringInterface,
  kListInterface,
  kByteArrayInterface,

  kInstanceObjectId,
  kMaxPredefinedObjectIds,
  kInvalidIndex = -1,
};

}  // namespace dart

#endif  // VM_SNAPSHOT_IDS_H_
