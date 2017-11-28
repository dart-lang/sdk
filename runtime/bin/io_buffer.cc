// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/io_buffer.h"

namespace dart {
namespace bin {

Dart_Handle IOBuffer::Allocate(intptr_t size, uint8_t** buffer) {
  uint8_t* data = Allocate(size);
  if (data == NULL) {
    return Dart_Null();
  }
  Dart_Handle result =
      Dart_NewExternalTypedData(Dart_TypedData_kUint8, data, size);
  Dart_NewWeakPersistentHandle(result, data, size, IOBuffer::Finalizer);

  if (Dart_IsError(result)) {
    Free(data);
    Dart_PropagateError(result);
  }
  if (buffer != NULL) {
    *buffer = data;
  }
  return result;
}

uint8_t* IOBuffer::Allocate(intptr_t size) {
  return reinterpret_cast<uint8_t*>(malloc(size));
}

}  // namespace bin
}  // namespace dart
