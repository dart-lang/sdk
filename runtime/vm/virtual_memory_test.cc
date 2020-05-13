// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory.h"
#include "platform/assert.h"
#include "vm/heap/heap.h"
#include "vm/unit_test.h"

namespace dart {

bool IsZero(char* begin, char* end) {
  for (char* current = begin; current < end; ++current) {
    if (*current != 0) {
      return false;
    }
  }
  return true;
}

VM_UNIT_TEST_CASE(AllocateVirtualMemory) {
  const intptr_t kVirtualMemoryBlockSize = 64 * KB;
  VirtualMemory* vm =
      VirtualMemory::Allocate(kVirtualMemoryBlockSize, false, "test");
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

  char* buf = reinterpret_cast<char*>(vm->address());
  EXPECT(IsZero(buf, buf + vm->size()));
  buf[0] = 'a';
  buf[1] = 'c';
  buf[2] = '/';
  buf[3] = 'd';
  buf[4] = 'c';
  buf[5] = 0;
  EXPECT_STREQ("ac/dc", buf);

  delete vm;
}

VM_UNIT_TEST_CASE(AllocateAlignedVirtualMemory) {
  intptr_t kHeapPageSize = kOldPageSize;
  intptr_t kVirtualPageSize = 4096;

  intptr_t kIterations = kHeapPageSize / kVirtualPageSize;
  for (intptr_t i = 0; i < kIterations; i++) {
    VirtualMemory* vm = VirtualMemory::AllocateAligned(
        kHeapPageSize, kHeapPageSize, false, "test");
    EXPECT(Utils::IsAligned(vm->start(), kHeapPageSize));
    EXPECT_EQ(kHeapPageSize, vm->size());
    delete vm;
  }
}

VM_UNIT_TEST_CASE(FreeVirtualMemory) {
  // Reservations should always be handed back to OS upon destruction.
  const intptr_t kVirtualMemoryBlockSize = 10 * MB;
  const intptr_t kIterations = 900;  // Enough to exhaust 32-bit address space.
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm =
        VirtualMemory::Allocate(kVirtualMemoryBlockSize, false, "test");
    delete vm;
  }
  // Check that truncation does not introduce leaks.
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm =
        VirtualMemory::Allocate(kVirtualMemoryBlockSize, false, "test");
    vm->Truncate(kVirtualMemoryBlockSize / 2);
    delete vm;
  }
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm =
        VirtualMemory::Allocate(kVirtualMemoryBlockSize, true, "test");
    vm->Truncate(0);
    delete vm;
  }
}

}  // namespace dart
