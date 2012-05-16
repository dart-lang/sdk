// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bit_vector.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(BitVector) {
  { BitVector* v = new BitVector(15);
    v->Add(1);
    { BitVector::Iterator iter(v);
      EXPECT_EQ(1, iter.Current());
      iter.Advance();
      EXPECT(iter.Done());
    }
    v->Add(0);
    v->Add(1);
    { BitVector::Iterator iter(v);
      EXPECT_EQ(0, iter.Current());
      iter.Advance();
      EXPECT_EQ(1, iter.Current());
      iter.Advance();
      EXPECT(iter.Done());
    }
  }

  { BitVector* v = new BitVector(128);
    v->Add(49);
    v->Add(62);
    v->Add(63);
    v->Add(65);
    BitVector::Iterator iter(v);
    EXPECT_EQ(49, iter.Current());
    iter.Advance();
    EXPECT_EQ(62, iter.Current());
    iter.Advance();
    EXPECT_EQ(63, iter.Current());
    iter.Advance();
    EXPECT_EQ(65, iter.Current());
    iter.Advance();
    EXPECT(iter.Done());
  }
}

}  // namespace dart
