// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_USE_JEMALLOC) && !defined(PRODUCT)

#include "vm/malloc_hooks.h"

#include <jemalloc/jemalloc.h>

#include "vm/json_stream.h"

namespace dart {

void MallocHooks::InitOnce() {
  // Do nothing.
}

void MallocHooks::TearDown() {
  // Do nothing.
}

void MallocHooks::PrintToJSONObject(JSONObject* jsobj) {
  // Here, we ignore the value of FLAG_profiler_native_memory because we can
  // gather this information cheaply without hooking into every call to the
  // malloc library.
  jsobj->AddProperty("_heapAllocatedMemoryUsage",
                     heap_allocated_memory_in_bytes());
  jsobj->AddProperty("_heapAllocationCount", allocation_count());
}

intptr_t MallocHooks::heap_allocated_memory_in_bytes() {
  uint64_t epoch = 1;
  size_t epoch_sz = sizeof(epoch);
  int result = mallctl("epoch", &epoch, &epoch_sz, &epoch, epoch_sz);
  if (result != 0) {
    return 0;
  }

  intptr_t allocated;
  size_t allocated_sz = sizeof(allocated);
  result = mallctl("stats.allocated", &allocated, &allocated_sz, NULL, 0);
  if (result != 0) {
    return 0;
  }
  return allocated;
}

intptr_t MallocHooks::allocation_count() {
  return 0;
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

Sample* MallocHooks::GetSample(const void* ptr) {
  return NULL;
}

}  // namespace dart

#endif  // defined(DART_USE_JEMALLOC) && ...
