// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/io_buffer.h"

#include "platform/memory_sanitizer.h"

namespace dart {
namespace bin {

Dart_Handle IOBuffer::Allocate(intptr_t size, uint8_t** buffer) {
  uint8_t* data = Allocate(size);
  if (data == NULL) {
    return Dart_Null();
  }
  Dart_Handle result = Dart_NewExternalTypedDataWithFinalizer(
      Dart_TypedData_kUint8, data, size, data, size, IOBuffer::Finalizer);

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
  return static_cast<uint8_t*>(calloc(size, sizeof(uint8_t)));
}

uint8_t* IOBuffer::Reallocate(uint8_t* buffer, intptr_t new_size) {
  if (new_size == 0) {
    // The call to `realloc()` below has a corner case if the new size is 0:
    // It can return `nullptr` in that case even though `malloc(0)` would
    // return a unique non-`nullptr` value.  To avoid returning `nullptr` on
    // successful realloc, we handle this case specially.
    auto new_buffer = IOBuffer::Allocate(0);
    if (new_buffer != nullptr) {
      free(buffer);
      return new_buffer;
    }
    return buffer;
  }
#if defined(DART_TARGET_OS_WINDOWS)
  // It seems windows realloc() doesn't free memory when shrinking, so we'll
  // manually allocate a new buffer, copy the data and free the old buffer.
  auto new_buffer = IOBuffer::Allocate(new_size);
  if (new_buffer != nullptr) {
    memmove(new_buffer, buffer, new_size);
    free(buffer);
    return static_cast<uint8_t*>(new_buffer);
  }
#endif
  return static_cast<uint8_t*>(realloc(buffer, new_size));
}

}  // namespace bin
}  // namespace dart
