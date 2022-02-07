// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if !defined(DEBUG) || !defined(DART_USE_TCMALLOC)

#include "vm/malloc_hooks.h"

#include "vm/json_stream.h"

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
#include <malloc.h>
#elif defined(DART_HOST_OS_MACOS)
#include <malloc/malloc.h>
#endif

#if !defined(DART_HOST_OS_WINDOWS) && !defined(DART_HOST_OS_MACOS)
extern "C" {
__attribute__((weak)) uintptr_t __sanitizer_get_current_allocated_bytes();
__attribute__((weak)) uintptr_t __sanitizer_get_heap_size();
__attribute__((weak)) int __sanitizer_install_malloc_and_free_hooks(
    void (*malloc_hook)(const void*, uintptr_t),
    void (*free_hook)(const void*));
}
#endif

namespace dart {

void MallocHooks::Init() {
  // Do nothing.
}

void MallocHooks::Cleanup() {
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

bool MallocHooks::GetStats(intptr_t* used,
                           intptr_t* capacity,
                           const char** implementation) {
#if !defined(PRODUCT)
#if !defined(DART_HOST_OS_WINDOWS) && !defined(DART_HOST_OS_MACOS)
  if (__sanitizer_get_current_allocated_bytes != nullptr &&
      __sanitizer_get_heap_size != nullptr) {
    *used = __sanitizer_get_current_allocated_bytes();
    *capacity = __sanitizer_get_heap_size();
    *implementation = "scudo";
    return true;
  }
#endif
  return false;
#else
  return false;
#endif
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
