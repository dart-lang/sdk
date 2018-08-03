// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ring_buffer.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(RingBuffer) {
  RingBuffer<int, 2> buf;
  EXPECT_EQ(0, buf.Size());
  buf.Add(42);
  EXPECT_EQ(1, buf.Size());
  EXPECT_EQ(42, buf.Get(0));
  buf.Add(87);
  EXPECT_EQ(2, buf.Size());
  EXPECT_EQ(87, buf.Get(0));
  EXPECT_EQ(42, buf.Get(1));
  buf.Add(-1);
  EXPECT_EQ(2, buf.Size());
  EXPECT_EQ(-1, buf.Get(0));
  EXPECT_EQ(87, buf.Get(1));
}

}  // namespace dart
