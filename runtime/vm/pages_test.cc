// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/pages.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Pages) {
  PageSpace* space = new PageSpace(NULL, 4 * MBInWords, 8 * MBInWords);
  EXPECT(!space->Contains(reinterpret_cast<uword>(&space)));
  uword block = space->TryAllocate(8 * kWordSize);
  EXPECT(block != 0);
  uword total = 0;
  while (total < 2 * MB) {
    const intptr_t kBlockSize = 16 * kWordSize;
    uword new_block = space->TryAllocate(kBlockSize);
    EXPECT(block != 0);
    EXPECT(block != new_block);
    EXPECT(space->IsValidAddress(new_block));
    block = new_block;
    total += kBlockSize;
  }
  // Allocate a large block.
  uword large_block = space->TryAllocate(1 * MB);
  EXPECT(large_block != 0);
  EXPECT(block != large_block);
  EXPECT(space->IsValidAddress(large_block));
  delete space;
}

}  // namespace dart
