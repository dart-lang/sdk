// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if !defined(DART_USE_TCMALLOC) || defined(PRODUCT)

#include "vm/malloc_hooks.h"

namespace dart {

void MallocHooks::InitOnce() {
  // Do nothing.
}


void MallocHooks::TearDown() {
  // Do nothing.
}


void MallocHooks::ResetStats() {
  // Do nothing.
}


bool MallocHooks::Initialized() {
  return false;
}


intptr_t MallocHooks::allocation_count() {
  return 0;
}


intptr_t MallocHooks::heap_allocated_memory_in_bytes() {
  return 0;
}

}  // namespace dart

#endif  // defined(DART_USE_TCMALLOC) || defined(PRODUCT)
