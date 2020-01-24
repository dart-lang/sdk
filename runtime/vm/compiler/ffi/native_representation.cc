// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_representation.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/runtime_api.h"
#include "vm/object.h"

namespace dart {

namespace compiler {

namespace ffi {

static const size_t kSizeUnknown = 0;

static const intptr_t kNumElementSizes = kFfiVoidCid - kFfiPointerCid + 1;

static const size_t element_size_table[kNumElementSizes] = {
    target::kWordSize,  // kFfiPointerCid
    kSizeUnknown,       // kFfiNativeFunctionCid
    1,                  // kFfiInt8Cid
    2,                  // kFfiInt16Cid
    4,                  // kFfiInt32Cid
    8,                  // kFfiInt64Cid
    1,                  // kFfiUint8Cid
    2,                  // kFfiUint16Cid
    4,                  // kFfiUint32Cid
    8,                  // kFfiUint64Cid
    target::kWordSize,  // kFfiIntPtrCid
    4,                  // kFfiFloatCid
    8,                  // kFfiDoubleCid
    kSizeUnknown,       // kFfiVoidCid
};

size_t ElementSizeInBytes(intptr_t class_id) {
  ASSERT(class_id != kFfiNativeFunctionCid);
  ASSERT(class_id != kFfiVoidCid);
  if (!RawObject::IsFfiTypeClassId(class_id)) {
    // subtype of Pointer
    class_id = kFfiPointerCid;
  }
  intptr_t index = class_id - kFfiPointerCid;
  return element_size_table[index];
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
