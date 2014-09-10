// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bit_set.h"
#include "vm/unit_test.h"

namespace dart {

template<intptr_t Size>
void TestBitSet() {
  BitSet<Size> set;
  EXPECT_EQ(-1, set.Last());
  for (int i = 0; i < Size; ++i) {
    EXPECT_EQ(false, set.Test(i));
    set.Set(i, true);
    EXPECT_EQ(true, set.Test(i));
    EXPECT_EQ(i, set.Last());
    for (int j = 0; j < Size; ++j) {
      intptr_t next = set.Next(j);
      if (j <= i) {
        EXPECT_EQ(i, next);
      } else {
        EXPECT_EQ(-1, next);
      }
    }
    set.Set(i, false);
    EXPECT_EQ(false, set.Test(i));
  }
  set.Reset();
  for (int i = 0; i < Size - 1; ++i) {
    set.Set(i, true);
    for (int j = i + 1; j < Size; ++j) {
      set.Set(j, true);
      EXPECT_EQ(j, set.Last());
      EXPECT_EQ(i, set.ClearLastAndFindPrevious(j));
      EXPECT_EQ(false, set.Test(j));
    }
  }
}


TEST_CASE(BitSetBasic) {
  TestBitSet<8>();
  TestBitSet<42>();
  TestBitSet<128>();
  TestBitSet<200>();
}

}  // namespace dart
