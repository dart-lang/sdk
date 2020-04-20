// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/hash_map.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

class TestValue {
 public:
  explicit TestValue(intptr_t x) : x_(x) {}
  intptr_t Hashcode() const { return x_ & 1; }
  bool Equals(TestValue* other) { return x_ == other->x_; }

 private:
  intptr_t x_;
};

TEST_CASE(DirectChainedHashMap) {
  DirectChainedHashMap<PointerKeyValueTrait<TestValue> > map;
  EXPECT(map.IsEmpty());
  TestValue v1(0);
  TestValue v2(1);
  TestValue v3(0);
  map.Insert(&v1);
  EXPECT(map.LookupValue(&v1) == &v1);
  map.Insert(&v2);
  EXPECT(map.LookupValue(&v1) == &v1);
  EXPECT(map.LookupValue(&v2) == &v2);
  EXPECT(map.LookupValue(&v3) == &v1);
  EXPECT(map.Remove(&v1));
  EXPECT(map.Lookup(&v1) == NULL);
  map.Insert(&v1);
  DirectChainedHashMap<PointerKeyValueTrait<TestValue> > map2(map);
  EXPECT(map2.LookupValue(&v1) == &v1);
  EXPECT(map2.LookupValue(&v2) == &v2);
  EXPECT(map2.LookupValue(&v3) == &v1);
}

TEST_CASE(DirectChainedHashMapInsertRemove) {
  DirectChainedHashMap<PointerKeyValueTrait<TestValue> > map;
  EXPECT(map.IsEmpty());
  TestValue v1(1);
  TestValue v2(3);  // Note: v1, v2, v3 should have the same hash.
  TestValue v3(5);

  // Start with adding and removing the same element.
  map.Insert(&v1);
  EXPECT(map.LookupValue(&v1) == &v1);
  EXPECT(map.Remove(&v1));
  EXPECT(map.Lookup(&v1) == NULL);

  // Inserting v2 first should put it at the head of the list.
  map.Insert(&v2);
  map.Insert(&v1);
  EXPECT(map.LookupValue(&v2) == &v2);
  EXPECT(map.LookupValue(&v1) == &v1);

  // Check to see if removing the head of the list causes issues.
  EXPECT(map.Remove(&v2));
  EXPECT(map.Lookup(&v2) == NULL);
  EXPECT(map.LookupValue(&v1) == &v1);

  // Reinsert v2, which will place it at the back of the hash map list.
  map.Insert(&v2);
  EXPECT(map.LookupValue(&v2) == &v2);

  // Remove from the back of the hash map list.
  EXPECT(map.Remove(&v2));
  EXPECT(map.Lookup(&v2) == NULL);
  EXPECT(map.Remove(&v1));
  EXPECT(map.Lookup(&v1) == NULL);

  // Check to see that removing an invalid element returns false.
  EXPECT(!map.Remove(&v1));

  // One last case: remove from the middle of a hash map list.
  map.Insert(&v1);
  map.Insert(&v2);
  map.Insert(&v3);

  EXPECT(map.LookupValue(&v1) == &v1);
  EXPECT(map.LookupValue(&v2) == &v2);
  EXPECT(map.LookupValue(&v3) == &v3);

  EXPECT(map.Remove(&v2));
  EXPECT(map.LookupValue(&v1) == &v1);
  EXPECT(map.Lookup(&v2) == NULL);
  EXPECT(map.LookupValue(&v3) == &v3);

  EXPECT(map.Remove(&v1));
  EXPECT(map.Remove(&v3));

  EXPECT(map.IsEmpty());
}

TEST_CASE(MallocDirectChainedHashMap) {
  MallocDirectChainedHashMap<PointerKeyValueTrait<TestValue> > map;
  EXPECT(map.IsEmpty());
  TestValue v1(0);
  TestValue v2(1);
  TestValue v3(0);
  map.Insert(&v1);
  EXPECT(map.LookupValue(&v1) == &v1);
  map.Insert(&v2);
  EXPECT(map.LookupValue(&v1) == &v1);
  EXPECT(map.LookupValue(&v2) == &v2);
  EXPECT(map.LookupValue(&v3) == &v1);
  MallocDirectChainedHashMap<PointerKeyValueTrait<TestValue> > map2(map);
  EXPECT(map2.LookupValue(&v1) == &v1);
  EXPECT(map2.LookupValue(&v2) == &v2);
  EXPECT(map2.LookupValue(&v3) == &v1);
}

class IntptrPair {
 public:
  IntptrPair() : first_(-1), second_(-1) {}
  IntptrPair(intptr_t first, intptr_t second)
      : first_(first), second_(second) {}

  intptr_t first() const { return first_; }
  intptr_t second() const { return second_; }

  bool operator==(const IntptrPair& other) {
    return (first_ == other.first_) && (second_ == other.second_);
  }

  bool operator!=(const IntptrPair& other) {
    return (first_ != other.first_) || (second_ != other.second_);
  }

 private:
  intptr_t first_;
  intptr_t second_;
};

TEST_CASE(DirectChainedHashMapIterator) {
  IntptrPair p1(1, 1);
  IntptrPair p2(2, 2);
  IntptrPair p3(3, 3);
  IntptrPair p4(4, 4);
  IntptrPair p5(5, 5);
  DirectChainedHashMap<NumbersKeyValueTrait<IntptrPair> > map;
  EXPECT(map.IsEmpty());
  DirectChainedHashMap<NumbersKeyValueTrait<IntptrPair> >::Iterator it =
      map.GetIterator();
  EXPECT(it.Next() == NULL);
  it.Reset();

  map.Insert(p1);
  EXPECT(*it.Next() == p1);
  it.Reset();

  map.Insert(p2);
  map.Insert(p3);
  map.Insert(p4);
  map.Insert(p5);
  intptr_t count = 0;
  intptr_t sum = 0;
  while (true) {
    IntptrPair* p = it.Next();
    if (p == NULL) {
      break;
    }
    count++;
    sum += p->second();
  }

  EXPECT(count == 5);
  EXPECT(sum == 15);
}

TEST_CASE(DirectChainedHashMapIteratorWithCollisionInLastBucket) {
  intptr_t values[] = {65,  325, 329, 73,  396, 207, 215, 93,  227, 39,
                       431, 112, 176, 313, 188, 317, 61,  127, 447};
  IntMap<intptr_t> map;

  for (intptr_t value : values) {
    map.Insert(value, value);
  }

  bool visited[ARRAY_SIZE(values)] = {};
  intptr_t count = 0;
  auto it = map.GetIterator();
  for (auto* p = it.Next(); p != nullptr; p = it.Next()) {
    ++count;
    bool found = false;
    intptr_t i = 0;
    for (intptr_t v : values) {
      if (v == p->key) {
        EXPECT(v == p->value);
        EXPECT(!visited[i]);
        visited[i] = true;
        found = true;
        break;
      }
      ++i;
    }
    EXPECT(found);
  }
  EXPECT(count == ARRAY_SIZE(values));
  for (bool is_visited : visited) {
    EXPECT(is_visited);
  }
}

TEST_CASE(CStringMap) {
  const char* const kConst1 = "test";
  const char* const kConst2 = "test 2";

  char* const str1 = OS::SCreate(nullptr, "%s", kConst1);
  char* const str2 = OS::SCreate(nullptr, "%s", kConst2);
  char* const str3 = OS::SCreate(nullptr, "%s", kConst1);

  // Make sure these strings are pointer-distinct, but C-string-equal.
  EXPECT_NE(str1, str3);
  EXPECT_STREQ(str1, str3);

  const intptr_t i1 = 1;
  const intptr_t i2 = 2;

  CStringMap<intptr_t> map;
  EXPECT(map.IsEmpty());

  map.Insert({str1, i1});
  EXPECT_NOTNULL(map.Lookup(str1));
  EXPECT_EQ(i1, map.LookupValue(str1));
  EXPECT_NULLPTR(map.Lookup(str2));
  EXPECT_NOTNULL(map.Lookup(str3));
  EXPECT_EQ(i1, map.LookupValue(str3));

  map.Insert({str2, i2});
  EXPECT_NOTNULL(map.Lookup(str1));
  EXPECT_EQ(i1, map.LookupValue(str1));
  EXPECT_NOTNULL(map.Lookup(str2));
  EXPECT_EQ(i2, map.LookupValue(str2));
  EXPECT_NOTNULL(map.Lookup(str3));
  EXPECT_EQ(i1, map.LookupValue(str3));

  EXPECT(map.Remove(str3));
  EXPECT_NULLPTR(map.Lookup(str1));
  EXPECT_NOTNULL(map.Lookup(str2));
  EXPECT_EQ(i2, map.LookupValue(str2));
  EXPECT_NULLPTR(map.Lookup(str3));

  EXPECT(!map.Remove(str3));
  EXPECT(map.Remove(str2));
  EXPECT(map.IsEmpty());

  free(str3);
  free(str2);
  free(str1);
}

TEST_CASE(CStringMapUpdate) {
  const char* const kConst1 = "test";
  const char* const kConst2 = "test 2";

  char* str1 = OS::SCreate(nullptr, "%s", kConst1);
  char* str2 = OS::SCreate(nullptr, "%s", kConst2);
  char* str3 = OS::SCreate(nullptr, "%s", kConst1);
  char* str4 = OS::SCreate(nullptr, "%s", kConst1);  // Only used for lookup.

  // Make sure these strings are pointer-distinct, but C-string-equal.
  EXPECT_NE(str1, str3);
  EXPECT_NE(str1, str4);
  EXPECT_NE(str3, str4);
  EXPECT_STREQ(str1, str3);
  EXPECT_STREQ(str1, str4);

  CStringKeyValueTrait<intptr_t>::Pair p1 = {str1, 1};
  CStringKeyValueTrait<intptr_t>::Pair p2 = {str2, 2};
  CStringKeyValueTrait<intptr_t>::Pair p3 = {str3, 3};

  CStringMap<intptr_t> map;
  EXPECT(map.IsEmpty());

  map.Update(p1);
  EXPECT_NOTNULL(map.Lookup(str1));
  EXPECT_EQ(p1.value, map.LookupValue(str1));
  EXPECT_NULLPTR(map.Lookup(str2));
  EXPECT_NOTNULL(map.Lookup(str3));
  EXPECT_EQ(p1.value, map.LookupValue(str3));
  EXPECT_NOTNULL(map.Lookup(str4));
  EXPECT_EQ(p1.value, map.LookupValue(str4));

  map.Update(p2);
  EXPECT_NOTNULL(map.Lookup(str1));
  EXPECT_EQ(p1.value, map.LookupValue(str1));
  EXPECT_NOTNULL(map.Lookup(str2));
  EXPECT_EQ(p2.value, map.LookupValue(str2));
  EXPECT_NOTNULL(map.Lookup(str3));
  EXPECT_EQ(p1.value, map.LookupValue(str3));
  EXPECT_NOTNULL(map.Lookup(str4));
  EXPECT_EQ(p1.value, map.LookupValue(str4));

  // Check Lookup after Update.
  map.Update(p3);
  EXPECT_NOTNULL(map.Lookup(str1));
  EXPECT_EQ(p3.value, map.LookupValue(str1));
  EXPECT_NOTNULL(map.Lookup(str2));
  EXPECT_EQ(p2.value, map.LookupValue(str2));
  EXPECT_NOTNULL(map.Lookup(str3));
  EXPECT_EQ(p3.value, map.LookupValue(str3));
  EXPECT_NOTNULL(map.Lookup(str4));
  EXPECT_EQ(p3.value, map.LookupValue(str4));

  // Check that single Remove after only Updates ensures Lookup fails after.
  EXPECT(map.Remove(str3));
  EXPECT_NULLPTR(map.Lookup(str1));
  EXPECT_NOTNULL(map.Lookup(str2));
  EXPECT_EQ(p2.value, map.LookupValue(str2));
  EXPECT_NULLPTR(map.Lookup(str3));
  EXPECT_NULLPTR(map.Lookup(str4));

  EXPECT(!map.Remove(str3));
  EXPECT(map.Remove(str2));
  EXPECT(map.IsEmpty());

  // Quick double-check that these weren't side-effected by the implementation
  // of hash maps (p1 especially).
  EXPECT_EQ(str1, p1.key);
  EXPECT_EQ(1, p1.value);
  EXPECT_EQ(str2, p2.key);
  EXPECT_EQ(2, p2.value);
  EXPECT_EQ(str3, p3.key);
  EXPECT_EQ(3, p3.value);

  free(str4);
  free(str3);
  free(str2);
  free(str1);
}

}  // namespace dart
