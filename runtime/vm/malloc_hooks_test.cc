// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if defined(DART_USE_TCMALLOC) && !defined(PRODUCT)

#include "platform/assert.h"
#include "vm/class_finalizer.h"
#include "vm/globals.h"
#include "vm/malloc_hooks.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

static void MallocHookTestBufferInitializer(volatile char* buffer,
                                            uintptr_t size) {
  // Run through the buffer and do something. If we don't do this and the memory
  // in buffer isn't touched, the tcmalloc hooks won't be called.
  for (uintptr_t i = 0; i < size; ++i) {
    buffer[i] = i;
  }
}


UNIT_TEST_CASE(BasicMallocHookTest) {
  MallocHooks::InitOnce();
  MallocHooks::ResetStats();
  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());
  const intptr_t buffer_size = 10;
  char* buffer = new char[buffer_size];
  MallocHookTestBufferInitializer(buffer, buffer_size);

  EXPECT_EQ(1L, MallocHooks::allocation_count());
  EXPECT_EQ(static_cast<intptr_t>(sizeof(char) * buffer_size),
            MallocHooks::heap_allocated_memory_in_bytes());

  delete[] buffer;
  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());
  MallocHooks::TearDown();
}


UNIT_TEST_CASE(FreeUnseenMemoryMallocHookTest) {
  MallocHooks::InitOnce();
  const intptr_t pre_hook_buffer_size = 3;
  char* pre_hook_buffer = new char[pre_hook_buffer_size];
  MallocHookTestBufferInitializer(pre_hook_buffer, pre_hook_buffer_size);

  MallocHooks::ResetStats();
  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());

  const intptr_t buffer_size = 10;
  volatile char* buffer = new char[buffer_size];
  MallocHookTestBufferInitializer(buffer, buffer_size);

  EXPECT_EQ(1L, MallocHooks::allocation_count());
  EXPECT_EQ(static_cast<intptr_t>(sizeof(char) * buffer_size),
            MallocHooks::heap_allocated_memory_in_bytes());

  delete[] pre_hook_buffer;
  EXPECT_EQ(1L, MallocHooks::allocation_count());
  EXPECT_EQ(static_cast<intptr_t>(sizeof(char) * buffer_size),
            MallocHooks::heap_allocated_memory_in_bytes());


  delete[] buffer;
  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());
  MallocHooks::TearDown();
}

};  // namespace dart

#endif  // defined(DART_USE_TCMALLOC) && !defined(PRODUCT)
