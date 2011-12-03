// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/freelist.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(FreeList) {
  FreeList* free_list = new FreeList();
  intptr_t kBlobSize = 1 * MB;
  intptr_t kSmallObjectSize = 4 * kWordSize;
  intptr_t kMediumObjectSize = 16 * kWordSize;
  intptr_t kLargeObjectSize = 8 * KB;
  uword blob = reinterpret_cast<uword>(malloc(kBlobSize));
  // Enqueue the large blob as one free block.
  free_list->Free(blob, kBlobSize);
  // Allocate a small object. Expect it to be positioned as the first element.
  uword small_object = free_list->TryAllocate(kSmallObjectSize);
  EXPECT_EQ(blob, small_object);
  // Freeing and allocating should give us the same memory back.
  free_list->Free(small_object, kSmallObjectSize);
  small_object = free_list->TryAllocate(kSmallObjectSize);
  EXPECT_EQ(blob, small_object);
  // Splitting the remainder further with small and medium objects.
  uword small_object2 = free_list->TryAllocate(kSmallObjectSize);
  EXPECT_EQ(blob + kSmallObjectSize, small_object2);
  uword med_object = free_list->TryAllocate(kMediumObjectSize);
  EXPECT_EQ(small_object2 + kSmallObjectSize, med_object);
  // Allocate a large object.
  uword large_object = free_list->TryAllocate(kLargeObjectSize);
  EXPECT_EQ(med_object + kMediumObjectSize, large_object);
  // Make sure that small objects can still split the remainder.
  uword small_object3 = free_list->TryAllocate(kSmallObjectSize);
  EXPECT_EQ(large_object + kLargeObjectSize, small_object3);
  // Split the large object.
  free_list->Free(large_object, kLargeObjectSize);
  uword small_object4 = free_list->TryAllocate(kSmallObjectSize);
  EXPECT_EQ(large_object, small_object4);
  // Get the full remainder of the large object.
  large_object = free_list->TryAllocate(kLargeObjectSize - kSmallObjectSize);
  EXPECT_EQ(small_object4 + kSmallObjectSize, large_object);
  // Get another large object from the large unallocated remainder.
  uword large_object2 = free_list->TryAllocate(kLargeObjectSize);
  EXPECT_EQ(small_object3 + kSmallObjectSize, large_object2);
  // Delete the memory associated with the test.
  free(reinterpret_cast<void*>(blob));
  delete free_list;
}

}  // namespace dart
