// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/recognized_method.h"

#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

classid_t ElementTypedDataCid(classid_t class_id) {
  ASSERT(class_id >= kFfiPointerCid);
  ASSERT(class_id < kFfiVoidCid);
  ASSERT(class_id != kFfiNativeFunctionCid);
  switch (class_id) {
    case kFfiInt8Cid:
      return kTypedDataInt8ArrayCid;
    case kFfiUint8Cid:
      return kTypedDataUint8ArrayCid;
    case kFfiInt16Cid:
      return kTypedDataInt16ArrayCid;
    case kFfiUint16Cid:
      return kTypedDataUint16ArrayCid;
    case kFfiInt32Cid:
      return kTypedDataInt32ArrayCid;
    case kFfiUint32Cid:
      return kTypedDataUint32ArrayCid;
    case kFfiInt64Cid:
      return kTypedDataInt64ArrayCid;
    case kFfiUint64Cid:
      return kTypedDataUint64ArrayCid;
    case kFfiIntPtrCid:
      return target::kWordSize == 4 ? kTypedDataInt32ArrayCid
                                    : kTypedDataInt64ArrayCid;
    case kFfiPointerCid:
      return target::kWordSize == 4 ? kTypedDataUint32ArrayCid
                                    : kTypedDataUint64ArrayCid;
    case kFfiFloatCid:
      return kTypedDataFloat32ArrayCid;
    case kFfiDoubleCid:
      return kTypedDataFloat64ArrayCid;
    default:
      UNREACHABLE();
  }
}

classid_t RecognizedMethodTypeArgCid(MethodRecognizer::Kind kind) {
  switch (kind) {
#define LOAD_STORE(type)                                                       \
  case MethodRecognizer::kFfiLoad##type:                                       \
  case MethodRecognizer::kFfiStore##type:                                      \
    return kFfi##type##Cid;
    CLASS_LIST_FFI_NUMERIC(LOAD_STORE)
    LOAD_STORE(Pointer)
#undef LOAD_STORE
    default:
      UNREACHABLE();
  }
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
