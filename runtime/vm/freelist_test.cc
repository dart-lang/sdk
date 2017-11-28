// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/freelist.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

static uword Allocate(FreeList* free_list, intptr_t size, bool is_protected) {
  uword result = free_list->TryAllocate(size, is_protected);
  if (result && is_protected) {
    bool status = VirtualMemory::Protect(reinterpret_cast<void*>(result), size,
                                         VirtualMemory::kReadExecute);
    ASSERT(status);
  }
  return result;
}

static void Free(FreeList* free_list,
                 uword address,
                 intptr_t size,
                 bool is_protected) {
  if (is_protected) {
    bool status = VirtualMemory::Protect(reinterpret_cast<void*>(address), size,
                                         VirtualMemory::kReadWrite);
    ASSERT(status);
  }
  free_list->Free(address, size);
  if (is_protected) {
    bool status = VirtualMemory::Protect(reinterpret_cast<void*>(address), size,
                                         VirtualMemory::kReadExecute);
    ASSERT(status);
  }
}

static void TestFreeList(VirtualMemory* region,
                         FreeList* free_list,
                         bool is_protected) {
  const intptr_t kSmallObjectSize = 4 * kWordSize;
  const intptr_t kMediumObjectSize = 16 * kWordSize;
  const intptr_t kLargeObjectSize = 8 * KB;
  uword blob = region->start();
  // Enqueue the large blob as one free block.
  free_list->Free(blob, region->size());

  if (is_protected) {
    // Write protect the whole region.
    region->Protect(VirtualMemory::kReadExecute);
  }

  // Allocate a small object. Expect it to be positioned as the first element.
  uword small_object = Allocate(free_list, kSmallObjectSize, is_protected);
  EXPECT_EQ(blob, small_object);
  // Freeing and allocating should give us the same memory back.
  Free(free_list, small_object, kSmallObjectSize, is_protected);
  small_object = Allocate(free_list, kSmallObjectSize, is_protected);
  EXPECT_EQ(blob, small_object);
  // Splitting the remainder further with small and medium objects.
  uword small_object2 = Allocate(free_list, kSmallObjectSize, is_protected);
  EXPECT_EQ(blob + kSmallObjectSize, small_object2);
  uword med_object = Allocate(free_list, kMediumObjectSize, is_protected);
  EXPECT_EQ(small_object2 + kSmallObjectSize, med_object);
  // Allocate a large object.
  uword large_object = Allocate(free_list, kLargeObjectSize, is_protected);
  EXPECT_EQ(med_object + kMediumObjectSize, large_object);
  // Make sure that small objects can still split the remainder.
  uword small_object3 = Allocate(free_list, kSmallObjectSize, is_protected);
  EXPECT_EQ(large_object + kLargeObjectSize, small_object3);
  // Split the large object.
  Free(free_list, large_object, kLargeObjectSize, is_protected);
  uword small_object4 = Allocate(free_list, kSmallObjectSize, is_protected);
  EXPECT_EQ(large_object, small_object4);
  // Get the full remainder of the large object.
  large_object =
      Allocate(free_list, kLargeObjectSize - kSmallObjectSize, is_protected);
  EXPECT_EQ(small_object4 + kSmallObjectSize, large_object);
  // Get another large object from the large unallocated remainder.
  uword large_object2 = Allocate(free_list, kLargeObjectSize, is_protected);
  EXPECT_EQ(small_object3 + kSmallObjectSize, large_object2);
}

TEST_CASE(FreeList) {
  FreeList* free_list = new FreeList();
  const intptr_t kBlobSize = 1 * MB;
  VirtualMemory* region =
      VirtualMemory::Allocate(kBlobSize, /* is_executable */ false, NULL);

  TestFreeList(region, free_list, false);

  // Delete the memory associated with the test.
  delete region;
  delete free_list;
}

TEST_CASE(FreeListProtected) {
  FreeList* free_list = new FreeList();
  const intptr_t kBlobSize = 1 * MB;
  VirtualMemory* region =
      VirtualMemory::Allocate(kBlobSize, /* is_executable */ false, NULL);

  TestFreeList(region, free_list, true);

  // Delete the memory associated with the test.
  delete region;
  delete free_list;
}

TEST_CASE(FreeListProtectedTinyObjects) {
  FreeList* free_list = new FreeList();
  const intptr_t kBlobSize = 1 * MB;
  const intptr_t kObjectSize = 2 * kWordSize;
  uword* objects = new uword[kBlobSize / kObjectSize];

  VirtualMemory* blob =
      VirtualMemory::Allocate(kBlobSize, /* is_executable = */ false, NULL);
  ASSERT(Utils::IsAligned(blob->start(), 4096));
  blob->Protect(VirtualMemory::kReadWrite);

  // Enqueue the large blob as one free block.
  free_list->Free(blob->start(), blob->size());

  // Write protect the whole region.
  blob->Protect(VirtualMemory::kReadExecute);

  // Allocate small objects.
  for (intptr_t i = 0; i < blob->size() / kObjectSize; i++) {
    objects[i] = Allocate(free_list, kObjectSize, true);  // is_protected
  }

  // All space is occupied. Expect failed allocation.
  ASSERT(Allocate(free_list, kObjectSize, true) == 0);

  // Free all objects again. Make the whole region writable for this.
  blob->Protect(VirtualMemory::kReadWrite);
  for (intptr_t i = 0; i < blob->size() / kObjectSize; i++) {
    free_list->Free(objects[i], kObjectSize);
  }

  // Delete the memory associated with the test.
  delete blob;
  delete free_list;
  delete[] objects;
}

TEST_CASE(FreeListProtectedVariableSizeObjects) {
  FreeList* free_list = new FreeList();
  const intptr_t kBlobSize = 8 * KB;
  const intptr_t kMinSize = 2 * kWordSize;
  uword* objects = new uword[kBlobSize / kMinSize];
  for (intptr_t i = 0; i < kBlobSize / kMinSize; ++i) {
    objects[i] = static_cast<uword>(NULL);
  }

  VirtualMemory* blob =
      VirtualMemory::Allocate(kBlobSize, /* is_executable = */ false, NULL);
  ASSERT(Utils::IsAligned(blob->start(), 4096));
  blob->Protect(VirtualMemory::kReadWrite);

  // Enqueue the large blob as one free block.
  free_list->Free(blob->start(), blob->size());

  // Write protect the whole region.
  blob->Protect(VirtualMemory::kReadExecute);

  // Allocate and free objects so that free list has > 1 elements.
  uword e0 = Allocate(free_list, 1 * KB, true);
  ASSERT(e0);
  uword e1 = Allocate(free_list, 3 * KB, true);
  ASSERT(e1);
  uword e2 = Allocate(free_list, 2 * KB, true);
  ASSERT(e2);
  uword e3 = Allocate(free_list, 2 * KB, true);
  ASSERT(e3);

  Free(free_list, e1, 3 * KB, true);
  Free(free_list, e2, 2 * KB, true);
  e0 = Allocate(free_list, 3 * KB - 2 * kWordSize, true);
  ASSERT(e0);

  // Delete the memory associated with the test.
  delete blob;
  delete free_list;
  delete[] objects;
}

}  // namespace dart
