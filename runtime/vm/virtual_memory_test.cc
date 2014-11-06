// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

UNIT_TEST_CASE(AllocateVirtualMemory) {
  const intptr_t kVirtualMemoryBlockSize = 64 * KB;
  VirtualMemory* vm = VirtualMemory::Reserve(kVirtualMemoryBlockSize);
  EXPECT(vm != NULL);
  EXPECT(vm->address() != NULL);
  EXPECT_EQ(kVirtualMemoryBlockSize, vm->size());
  EXPECT_EQ(vm->start(), reinterpret_cast<uword>(vm->address()));
  EXPECT_EQ(vm->start() + kVirtualMemoryBlockSize, vm->end());
  EXPECT(vm->Contains(vm->start()));
  EXPECT(vm->Contains(vm->start() + 1));
  EXPECT(vm->Contains(vm->start() + kVirtualMemoryBlockSize - 1));
  EXPECT(vm->Contains(vm->start() + (kVirtualMemoryBlockSize / 2)));
  EXPECT(!vm->Contains(vm->start() - 1));
  EXPECT(!vm->Contains(vm->end()));
  EXPECT(!vm->Contains(vm->end() + 1));
  EXPECT(!vm->Contains(0));
  EXPECT(!vm->Contains(static_cast<uword>(-1)));

  vm->Commit(false);
  char* buf = reinterpret_cast<char*>(vm->address());
  buf[0] = 'a';
  buf[1] = 'c';
  buf[2] = '/';
  buf[3] = 'd';
  buf[4] = 'c';
  buf[5] = 0;
  EXPECT_STREQ("ac/dc", buf);

  delete vm;
}


UNIT_TEST_CASE(FreeVirtualMemory) {
  // Reservations should always be handed back to OS upon destruction.
  const intptr_t kVirtualMemoryBlockSize = 10 * MB;
  const intptr_t kIterations = 900;  // Enough to exhaust 32-bit address space.
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm = VirtualMemory::Reserve(kVirtualMemoryBlockSize);
    vm->Commit(false);
    delete vm;
  }
  // Check that truncation does not introduce leaks.
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm = VirtualMemory::Reserve(kVirtualMemoryBlockSize);
    vm->Commit(false);
    vm->Truncate(kVirtualMemoryBlockSize / 2, true);
    delete vm;
  }
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm = VirtualMemory::Reserve(kVirtualMemoryBlockSize);
    vm->Commit(true);
    vm->Truncate(kVirtualMemoryBlockSize / 2, false);
    delete vm;
  }
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm = VirtualMemory::Reserve(kVirtualMemoryBlockSize);
    vm->Commit(true);
    vm->Truncate(0, true);
    delete vm;
  }
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm = VirtualMemory::Reserve(kVirtualMemoryBlockSize);
    vm->Commit(false);
    vm->Truncate(0, false);
    delete vm;
  }
}


UNIT_TEST_CASE(VirtualMemoryCommitPartial) {
  const intptr_t kVirtualMemoryBlockSize = 3 * MB;
  VirtualMemory* vm = VirtualMemory::Reserve(kVirtualMemoryBlockSize);
  EXPECT(vm != NULL);
  // Commit only the middle MB and write to it.
  const uword commit_start = vm->start() + (1 * MB);
  const intptr_t kCommitSize = 1 * MB;
  vm->Commit(commit_start, kCommitSize, false);
  char* buf = reinterpret_cast<char*>(commit_start);
  buf[0] = 'f';
  buf[1] = 'o';
  buf[2] = 'o';
  buf[3] = 0;
  EXPECT_STREQ("foo", buf);
  delete vm;
}

}  // namespace dart
