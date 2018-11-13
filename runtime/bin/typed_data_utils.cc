// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/typed_data_utils.h"
#include "platform/assert.h"

namespace dart {
namespace bin {

TypedDataScope::TypedDataScope(Dart_Handle data) : data_handle_(data) {
  Dart_Handle result;
  result = Dart_TypedDataAcquireData(data, &type_, &data_, &length_);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
}

void TypedDataScope::Release() {
  if (data_handle_ == NULL) {
    return;
  }
  Dart_Handle result = Dart_TypedDataReleaseData(data_handle_);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  data_handle_ = NULL;
  data_ = NULL;
  length_ = 0;
  type_ = Dart_TypedData_kInvalid;
}

intptr_t TypedDataScope::size_in_bytes() const {
  switch (type_) {
    case Dart_TypedData_kByteData:
    case Dart_TypedData_kInt8:
    case Dart_TypedData_kUint8:
    case Dart_TypedData_kUint8Clamped:
      return length_;
    case Dart_TypedData_kInt16:
    case Dart_TypedData_kUint16:
      return length_ * 2;
    case Dart_TypedData_kInt32:
    case Dart_TypedData_kUint32:
    case Dart_TypedData_kFloat32:
      return length_ * 4;
    case Dart_TypedData_kInt64:
    case Dart_TypedData_kUint64:
    case Dart_TypedData_kFloat64:
      return length_ * 8;
    case Dart_TypedData_kFloat32x4:
      return length_ * 16;
    default:
      UNREACHABLE();
  }
}

const char* TypedDataScope::GetScopedCString() const {
  char* buf = reinterpret_cast<char*>(Dart_ScopeAllocate(size_in_bytes()));
  strncpy(buf, GetCString(), size_in_bytes());
  return buf;
}

}  // namespace bin
}  // namespace dart
