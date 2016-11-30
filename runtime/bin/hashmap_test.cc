// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/hashmap.h"
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


UNIT_TEST_CASE(HashMap_Basic) {
  TestSet(WordHash, 100);
  TestSet(Hash, 100);
  TestSet(CollisionHash1, 50);
  TestSet(CollisionHash2, 50);
  TestSet(CollisionHash3, 50);
  TestSet(CollisionHash4, 50);
}


UNIT_TEST_CASE(HashMap_RemoveDuringIteration) {
  class Utils {
   public:
    static bool MatchFun(void* key1, void* key2) { return key1 == key2; }
    static void* Key(intptr_t i) { return reinterpret_cast<void*>(i); }
    static void* Value(intptr_t i) { return reinterpret_cast<void*>(i); }
    static uint32_t HashCode(intptr_t key) { return 1; }
  };

  HashMap map(Utils::MatchFun, 8);

  // Add 6 (1, 1), ..., (6, 60) entries to the map all with a hashcode of 1
  // (i.e. have all keys have collinding hashcode).
  //
  // This causes the probing position in the hashmap to be 1 and open-addressing
  // with linear probing will fill in the slots towards the right
  // (i.e. from 1..6).
  for (intptr_t i = 1; i <= 6 /* avoid rehash at 7 */; i++) {
    HashMap::Entry* entry = map.Lookup(Utils::Key(i), Utils::HashCode(i), true);
    entry->value = Utils::Value(10 * i);
  }

  // Now we iterate over all elements and delete the current element. Since all
  // our entries have a colliding hashcode of 1, each deletion will cause all
  // following elements to be left-rotated by 1.
  intptr_t i = 0;
  HashMap::Entry* current = map.Start();
  while (current != NULL) {
    i++;
    EXPECT_EQ(Utils::Key(i), current->key);
    EXPECT_EQ(Utils::Value(10 * i), current->value);

    // Every 2nd element we keep to hit the left-rotation case only sometimes.
    if (i % 2 == 0) {
      current = map.Remove(current);
    } else {
      current = map.Next(current);
    }
  }
  EXPECT_EQ(6, i);
}

}  // namespace dart
