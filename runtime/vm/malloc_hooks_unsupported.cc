// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if (!defined(DART_USE_TCMALLOC) && !defined(DART_USE_JEMALLOC)) ||            \
    defined(PRODUCT)

#include "vm/malloc_hooks.h"

namespace dart {

void MallocHooks::InitOnce() {
  // Do nothing.
}


void MallocHooks::TearDown() {
  // Do nothing.
}


bool MallocHooks::ProfilingEnabled() {
  return false;
}


bool MallocHooks::stack_trace_collection_enabled() {
  return false;
}


void MallocHooks::set_stack_trace_collection_enabled(bool enabled) {
  // Do nothing.
}


void MallocHooks::ResetStats() {
  // Do nothing.
}


bool MallocHooks::Active() {
  return false;
}


void MallocHooks::PrintToJSONObject(JSONObject* jsobj) {
  // Do nothing.
}


Sample* MallocHooks::GetSample(const void* ptr) {
  return NULL;
}


intptr_t MallocHooks::allocation_count() {
  return 0;
}


intptr_t MallocHooks::heap_allocated_memory_in_bytes() {
  return 0;
}

}  // namespace dart

#endif  // !defined(DART_USE_TCMALLOC) && ...
