// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/growable_array.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(GrowableArray) {
  GrowableArray<int> g;
  EXPECT_EQ(0, g.length());
  EXPECT(g.is_empty());
  g.Add(5);
  EXPECT_EQ(5, g[0]);
  EXPECT_EQ(1, g.length());
  EXPECT(!g.is_empty());
  g.Add(3);
  const GrowableArray<int>& temp = g;
  EXPECT_EQ(5, temp[0]);
  EXPECT_EQ(3, temp[1]);
  for (int i = 0; i < 10000; i++) {
    g.Add(i);
  }
  EXPECT_EQ(10002, g.length());
  EXPECT_EQ(10000 - 1, g.Last());

  GrowableArray<int64_t> f(10);
  EXPECT_EQ(0, f.length());
  f.Add(-1LL);
  f.Add(15LL);
  EXPECT_EQ(2, f.length());
  for (int64_t l = 0; l < 100; l++) {
    f.Add(l);
  }
  EXPECT_EQ(102, f.length());
  EXPECT_EQ(100 - 1, f.Last());
  EXPECT_EQ(-1LL, f[0]);

  GrowableArray<int> h;
  EXPECT_EQ(0, h.length());
  h.Add(101);
  h.Add(102);
  h.Add(103);
  EXPECT_EQ(3, h.length());
  EXPECT_EQ(103, h.Last());
  h.RemoveLast();
  EXPECT_EQ(2, h.length());
  EXPECT_EQ(102, h.Last());
  h.RemoveLast();
  EXPECT_EQ(1, h.length());
  EXPECT_EQ(101, h.Last());
  h.RemoveLast();
  EXPECT_EQ(0, h.length());
  EXPECT(h.is_empty());
  h.Add(-8899);
  h.Add(7908);
  EXPECT(!h.is_empty());
  h.Clear();
  EXPECT(h.is_empty());
}


static int greatestFirst(const int* a, const int* b) {
  if (*a > *b) {
    return -1;
  } else if (*a < *b) {
    return 1;
  } else {
    return 0;
  }
}

TEST_CASE(GrowableArraySort) {
  GrowableArray<int> g;
  g.Add(12);
  g.Add(4);
  g.Add(64);
  g.Add(8);
  g.Sort(greatestFirst);
  EXPECT_EQ(64, g[0]);
  EXPECT_EQ(4, g.Last());
}

}  // namespace dart
