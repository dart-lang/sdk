// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/allocation.h"

#include "platform/assert.h"

namespace dart {

void* malloc(size_t size) {
  void* result = ::malloc(size);
  if (result == nullptr) {
    OUT_OF_MEMORY();
  }
  return result;
}

void* realloc(void* ptr, size_t size) {
  void* result = ::realloc(ptr, size);
  if (result == nullptr) {
    OUT_OF_MEMORY();
  }
  return result;
}

}  // namespace dart
