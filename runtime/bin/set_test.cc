// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/set.h"

#include "vm/unit_test.h"

UNIT_TEST_CASE(SetOperations) {
  Set<int> set;
  EXPECT(set.IsEmpty());
  EXPECT(!set.Contains(1));
  EXPECT(set.Add(1));
  EXPECT(set.Contains(1));
  EXPECT(!set.IsEmpty());
  EXPECT(!set.Remove(2));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Remove(1));
  EXPECT(set.IsEmpty());
  EXPECT(set.Add(3));
  EXPECT(set.Contains(3));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Add(4));
  EXPECT(set.Contains(4));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Add(5));
  EXPECT(set.Contains(5));
  EXPECT(set.Remove(5));
  EXPECT(set.Remove(4));
  EXPECT(set.Remove(3));
  EXPECT(set.IsEmpty());
  EXPECT(set.Add(1));
  EXPECT(set.Contains(1));
  EXPECT(set.Add(2));
  EXPECT(set.Contains(2));
  EXPECT(set.Add(3));
  EXPECT(set.Contains(3));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Size() == 3);
  EXPECT(set.Remove(2));
  EXPECT(set.Remove(1));
  EXPECT(set.Remove(3));
  EXPECT(set.IsEmpty());
  EXPECT(set.Size() == 0);
  EXPECT(set.Add(1));
  EXPECT(set.Contains(1));
  EXPECT(set.Add(2));
  EXPECT(set.Contains(2));
  EXPECT(set.Add(3));
  EXPECT(set.Contains(3));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Remove(2));
  EXPECT(set.Remove(3));
  EXPECT(set.Remove(1));
  EXPECT(set.IsEmpty());
  EXPECT(set.Add(1));
  EXPECT(set.Contains(1));
  EXPECT(set.Add(2));
  EXPECT(set.Contains(2));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Remove(2));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Add(3));
  EXPECT(set.Contains(3));
  EXPECT(set.Add(4));
  EXPECT(set.Contains(4));
  EXPECT(!set.Contains(2));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Remove(3));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Remove(4));
  EXPECT(set.Remove(1));
  EXPECT(set.IsEmpty());
  EXPECT(!set.Contains(4));
  EXPECT(set.Add(1));
  EXPECT(set.Contains(1));
  EXPECT(!set.IsEmpty());
  EXPECT(!set.Add(1));
  EXPECT(set.Size() == 1);
  EXPECT(set.Contains(1));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Add(2));
  EXPECT(set.Contains(2));
  EXPECT(!set.IsEmpty());
  EXPECT(!set.Add(2));
  EXPECT(set.Contains(2));
  EXPECT(!set.IsEmpty());
  EXPECT(set.Size() == 2);
  EXPECT(set.Remove(1));
  EXPECT(set.Remove(2));
  EXPECT(set.IsEmpty());
  EXPECT(set.Size() == 0);
}


UNIT_TEST_CASE(SetIterator) {
  Set<int> set;
  int i;
  for (i = 1; i <= 10; i++) {
    set.Add(i);
  }

  Set<int>::Iterator iterator(&set);
  int value;
  i = 0;

  while (iterator.HasNext()) {
    iterator.GetNext(&value);
    i++;
  }
  EXPECT(i == 10);
  EXPECT(!set.IsEmpty());

  Set<int> emptyset;
  Set<int>::Iterator emptyiterator(&emptyset);

  i = 0;
  while (emptyiterator.HasNext()) {
    emptyiterator.GetNext(&value);
    i++;
  }
  EXPECT(i == 0);
  EXPECT(emptyset.IsEmpty());
}

