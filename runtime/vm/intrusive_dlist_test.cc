// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/intrusive_dlist.h"
#include "vm/unit_test.h"

namespace dart {

class Base {
 public:
  explicit Base(int arg) : base(arg) {}

  int base;
};

class Item : public Base,
             public IntrusiveDListEntry<Item>,
             public IntrusiveDListEntry<Item, 2> {
 public:
  explicit Item(int arg0, int arg1) : Base(arg0), item(arg1) {}

  int item;
};

UNIT_TEST_CASE(IntrusiveDListMultiEntryTest) {
  Item a1(1, 11), a2(2, 12), a3(3, 13);

  IntrusiveDList<Item> all;
  IntrusiveDList<Item, 2> ready;

  EXPECT(all.IsEmpty());
  EXPECT(ready.IsEmpty());

  all.Append(&a2);
  all.Append(&a3);
  all.Prepend(&a1);
  EXPECT_EQ(all.First()->item, 11);
  EXPECT_EQ(all.Last()->item, 13);

  ready.Append(&a1);
  ready.Append(&a2);
  EXPECT_EQ(ready.First()->item, 11);
  EXPECT_EQ(ready.Last()->item, 12);

  int i = 0;
  for (auto it = all.Begin(); it != all.End(); ++it) {
    i++;
    EXPECT_EQ(it->base, i);
    EXPECT_EQ((*it)->base, i);
    EXPECT_EQ(it->item, 10 + i);
    EXPECT_EQ((*it)->item, 10 + i);
  }
  EXPECT_EQ(i, 3);

  i = 0;
  for (auto it = ready.Begin(); it != ready.End(); ++it) {
    i++;
    EXPECT_EQ(it->base, i);
    EXPECT_EQ((*it)->base, i);
    EXPECT_EQ(it->item, 10 + i);
    EXPECT_EQ((*it)->item, 10 + i);
  }
  EXPECT_EQ(i, 2);

  ready.Remove(&a1);
  ready.Remove(&a2);

  all.Remove(&a1);
  all.Remove(&a2);
  all.Remove(&a3);

  EXPECT(all.IsEmpty());
  EXPECT(ready.IsEmpty());
}

UNIT_TEST_CASE(IntrusiveDListRemoveFirstTest) {
  Item a1(1, 11), a2(2, 12), a3(3, 13);

  IntrusiveDList<Item> all;

  all.Append(&a2);
  all.Append(&a3);
  all.Prepend(&a1);

  EXPECT_EQ(&a1, all.RemoveFirst());
  EXPECT_EQ(&a2, all.RemoveFirst());
  EXPECT_EQ(&a3, all.RemoveFirst());

  EXPECT(all.IsEmpty());
}

UNIT_TEST_CASE(IntrusiveDListRemoveLastTest) {
  Item a1(1, 11), a2(2, 12), a3(3, 13);

  IntrusiveDList<Item> all;

  all.Append(&a2);
  all.Append(&a3);
  all.Prepend(&a1);

  EXPECT_EQ(&a3, all.RemoveLast());
  EXPECT_EQ(&a2, all.RemoveLast());
  EXPECT_EQ(&a1, all.RemoveLast());
  EXPECT(all.IsEmpty());
}

UNIT_TEST_CASE(IntrusiveDListIsInList) {
  Item a1(1, 11), a2(2, 12), a3(3, 13);

  IntrusiveDList<Item> all;

  all.Append(&a2);
  all.Append(&a3);
  all.Prepend(&a1);

  ASSERT(all.IsInList(&a1));
  ASSERT(all.IsInList(&a2));
  ASSERT(all.IsInList(&a3));

  EXPECT_EQ(&a1, all.RemoveFirst());
  EXPECT(!all.IsInList(&a1));
  EXPECT_EQ(&a3, all.RemoveLast());
  EXPECT(!all.IsInList(&a3));
  EXPECT_EQ(&a2, all.RemoveFirst());
  EXPECT(!all.IsInList(&a2));

  EXPECT(all.IsEmpty());
}

UNIT_TEST_CASE(IntrusiveDListEraseIterator) {
  Item a1(1, 11), a2(2, 12), a3(3, 13);

  IntrusiveDList<Item> all;

  all.Append(&a2);
  all.Append(&a3);
  all.Prepend(&a1);

  auto it = all.Begin();
  it = all.Erase(++it);
  EXPECT_EQ(*it, &a3);
  EXPECT_EQ(*it, all.Last());

  it = all.Erase(all.Begin());
  EXPECT_EQ(*it, &a3);
  EXPECT_EQ(*it, all.First());
  EXPECT_EQ(*it, all.Last());

  it = all.Erase(all.Begin());
  EXPECT(it == all.End());
  EXPECT(all.IsEmpty());
}

UNIT_TEST_CASE(IntrusiveDListAppendListTest) {
  // Append to empty list.
  {
    IntrusiveDList<Item> all;
    IntrusiveDList<Item> other;

    Item a1(1, 11), a2(2, 12);
    all.Append(&a1);
    all.Append(&a2);

    other.AppendList(&all);

    EXPECT(all.IsEmpty());
    EXPECT(!other.IsEmpty());
    EXPECT_EQ(&a1, other.First());
    EXPECT_EQ(&a2, other.Last());

    auto it = other.Begin();
    EXPECT_EQ(&a1, *it);
    it = other.Erase(it);
    EXPECT_EQ(&a2, *it);
    it = other.Erase(it);
    EXPECT(it == other.end());
  }
  // Append to non-empty list.
  {
    IntrusiveDList<Item> all;
    IntrusiveDList<Item> other;

    Item a1(1, 11), a2(2, 12);
    all.Append(&a1);
    all.Append(&a2);

    Item o1(1, 11);
    other.Append(&o1);

    other.AppendList(&all);

    EXPECT(all.IsEmpty());
    EXPECT(!other.IsEmpty());
    EXPECT_EQ(&o1, other.First());
    EXPECT_EQ(&a2, other.Last());

    auto it = other.Begin();
    EXPECT_EQ(&o1, *it);
    it = other.Erase(it);
    EXPECT_EQ(&a1, *it);
    it = other.Erase(it);
    EXPECT_EQ(&a2, *it);
    it = other.Erase(it);
    EXPECT(it == other.end());
  }
}

}  // namespace dart.
