// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/virtual_memory.h"
#include "platform/assert.h"
#include "vm/heap/heap.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory_compressed.h"

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
      VirtualMemory::Allocate(kVirtualMemoryBlockSize, false, false, "test");
  EXPECT(vm != nullptr);
  EXPECT(vm->address() != nullptr);
  EXPECT_EQ(vm->start(), reinterpret_cast<uword>(vm->address()));
  EXPECT_EQ(kVirtualMemoryBlockSize, vm->size());
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
  intptr_t kHeapPageSize = kPageSize;
  intptr_t kVirtualPageSize = 4096;

  intptr_t kIterations = kHeapPageSize / kVirtualPageSize;
  for (intptr_t i = 0; i < kIterations; i++) {
    VirtualMemory* vm = VirtualMemory::AllocateAligned(
        kHeapPageSize, kHeapPageSize, false, false, "test");
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
        VirtualMemory::Allocate(kVirtualMemoryBlockSize, false, false, "test");
    delete vm;
  }
  // Check that truncation does not introduce leaks.
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm =
        VirtualMemory::Allocate(kVirtualMemoryBlockSize, false, false, "test");
    vm->Truncate(kVirtualMemoryBlockSize / 2);
    delete vm;
  }
  for (intptr_t i = 0; i < kIterations; ++i) {
    VirtualMemory* vm =
        VirtualMemory::Allocate(kVirtualMemoryBlockSize, true, false, "test");
    vm->Truncate(0);
    delete vm;
  }
}

static int testFunction(int x) {
  return x * 2;
}

NO_SANITIZE_UNDEFINED("function")  // See #52440
VM_UNIT_TEST_CASE(DuplicateRXVirtualMemory) {
  const uword page_size = VirtualMemory::PageSize();
  const uword pointer = reinterpret_cast<uword>(&testFunction);
  const uword page_start = Utils::RoundDown(pointer, page_size);
  const uword offset = pointer - page_start;

  // Grab 2 * page_size, in case testFunction happens to land near the end of
  // the page.
  VirtualMemory* vm = VirtualMemory::ForImagePage(
      reinterpret_cast<void*>(page_start), 2 * page_size);
  EXPECT_NE(nullptr, vm);

  VirtualMemory* vm2 = vm->DuplicateRX();
  EXPECT_NE(nullptr, vm2);

  auto testFunction2 = reinterpret_cast<int (*)(int)>(vm2->start() + offset);
  EXPECT_NE(&testFunction, testFunction2);

  EXPECT_EQ(246, testFunction2(123));

  delete vm;
  delete vm2;
}

}  // namespace dart
