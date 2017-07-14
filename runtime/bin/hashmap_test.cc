// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/hashmap.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"

namespace dart {

// Default initial size of hashmaps used in these tests.
static intptr_t kInitialSize = 8;

typedef uint32_t (*IntKeyHash)(uint32_t key);

class IntSet {
 public:
  explicit IntSet(IntKeyHash hash)
      : hash_(hash), map_(HashMap::SamePointerValue, kInitialSize) {}

  void Insert(int x) {
    EXPECT_NE(0, x);  // 0 corresponds to (void*)NULL - illegal key value
    HashMap::Entry* p = map_.Lookup(reinterpret_cast<void*>(x), hash_(x), true);
    EXPECT(p != NULL);  // insert is set!
    EXPECT_EQ(reinterpret_cast<void*>(x), p->key);
    // We don't care about p->value.
  }

  void Remove(int x) {
    EXPECT_NE(0, x);  // 0 corresponds to (void*)NULL - illegal key value
    map_.Remove(reinterpret_cast<void*>(x), hash_(x));
  }

  bool Present(int x) {
    HashMap::Entry* p =
        map_.Lookup(reinterpret_cast<void*>(x), hash_(x), false);
    if (p != NULL) {
      EXPECT_EQ(reinterpret_cast<void*>(x), p->key);
    }
    return p != NULL;
  }

  void Clear() { map_.Clear(); }

  uint32_t occupancy() const {
    uint32_t count = 0;
    for (HashMap::Entry* p = map_.Start(); p != NULL; p = map_.Next(p)) {
      count++;
    }
    EXPECT_EQ(map_.occupancy_, count);
    return count;
  }

 private:
  IntKeyHash hash_;
  HashMap map_;
};

static uint32_t WordHash(uint32_t key) {
  return dart::Utils::WordHash(key);
}
static uint32_t Hash(uint32_t key) {
  return 23;
}
static uint32_t CollisionHash1(uint32_t key) {
  return key & 0x3;
}
static uint32_t CollisionHash2(uint32_t key) {
  return kInitialSize - 1;
}
static uint32_t CollisionHash3(uint32_t key) {
  return kInitialSize - 2;
}
static uint32_t CollisionHash4(uint32_t key) {
  return kInitialSize - 2;
}

void TestSet(IntKeyHash hash, int size) {
  IntSet set(hash);
  EXPECT_EQ(0u, set.occupancy());

  set.Insert(1);
  set.Insert(2);
  set.Insert(3);
  set.Insert(4);
  EXPECT_EQ(4u, set.occupancy());

  set.Insert(2);
  set.Insert(3);
  EXPECT_EQ(4u, set.occupancy());

  EXPECT(set.Present(1));
  EXPECT(set.Present(2));
  EXPECT(set.Present(3));
  EXPECT(set.Present(4));
  EXPECT(!set.Present(5));
  EXPECT_EQ(4u, set.occupancy());

  set.Remove(1);
  EXPECT(!set.Present(1));
  EXPECT(set.Present(2));
  EXPECT(set.Present(3));
  EXPECT(set.Present(4));
  EXPECT_EQ(3u, set.occupancy());

  set.Remove(3);
  EXPECT(!set.Present(1));
  EXPECT(set.Present(2));
  EXPECT(!set.Present(3));
  EXPECT(set.Present(4));
  EXPECT_EQ(2u, set.occupancy());

  set.Remove(4);
  EXPECT(!set.Present(1));
  EXPECT(set.Present(2));
  EXPECT(!set.Present(3));
  EXPECT(!set.Present(4));
  EXPECT_EQ(1u, set.occupancy());

  set.Clear();
  EXPECT_EQ(0u, set.occupancy());

  // Insert a long series of values.
  const int start = 453;
  const int factor = 13;
  const int offset = 7;
  const uint32_t n = size;

  int x = start;
  for (uint32_t i = 0; i < n; i++) {
    EXPECT_EQ(i, set.occupancy());
    set.Insert(x);
    x = x * factor + offset;
  }
  EXPECT_EQ(n, set.occupancy());

  // Verify the same sequence of values.
  x = start;
  for (uint32_t i = 0; i < n; i++) {
    EXPECT(set.Present(x));
    x = x * factor + offset;
  }
  EXPECT_EQ(n, set.occupancy());

  // Remove all these values.
  x = start;
  for (uint32_t i = 0; i < n; i++) {
    EXPECT_EQ(n - i, set.occupancy());
    EXPECT(set.Present(x));
    set.Remove(x);
    EXPECT(!set.Present(x));
    x = x * factor + offset;

    // Verify the expected values are still there.
    int y = start;
    for (uint32_t j = 0; j < n; j++) {
      if (j <= i) {
        EXPECT(!set.Present(y));
      } else {
        EXPECT(set.Present(y));
      }
      y = y * factor + offset;
    }
  }
  EXPECT_EQ(0u, set.occupancy());
}

VM_UNIT_TEST_CASE(HashMap_Basic) {
  TestSet(WordHash, 100);
  TestSet(Hash, 100);
  TestSet(CollisionHash1, 50);
  TestSet(CollisionHash2, 50);
  TestSet(CollisionHash3, 50);
  TestSet(CollisionHash4, 50);
}

}  // namespace dart
