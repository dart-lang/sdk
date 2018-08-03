// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/eventhandler.h"
#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {
namespace bin {

VM_UNIT_TEST_CASE(CircularLinkedList) {
  CircularLinkedList<int> list;

  EXPECT(!list.HasHead());

  list.Add(1);
  EXPECT(list.HasHead());
  EXPECT(list.head() == 1);

  // Test: Inserts don't move head.
  for (int i = 2; i <= 100; i++) {
    list.Add(i);
    EXPECT(list.head() == 1);
  }

  // Test: Rotate cycle through all elements in insertion order.
  for (int i = 1; i <= 100; i++) {
    EXPECT(list.HasHead());
    EXPECT(list.head() == i);
    list.Rotate();
  }

  // Test: Removing head results in next element to be head.
  for (int i = 1; i <= 100; i++) {
    list.RemoveHead();
    for (int j = i + 1; j <= 100; j++) {
      EXPECT(list.HasHead());
      EXPECT(list.head() == j);
      list.Rotate();
    }
  }

  // Test: Removing all items individually make list empty.
  EXPECT(!list.HasHead());

  // Test: Removing all items at once makes list empty.
  for (int i = 1; i <= 100; i++) {
    list.Add(i);
  }
  list.RemoveAll();
  EXPECT(!list.HasHead());

  // Test: Remove individual items just deletes them without modifying head.
  for (int i = 1; i <= 10; i++) {
    list.Add(i);
  }
  for (int i = 2; i <= 9; i++) {
    list.Remove(i);
  }
  EXPECT(list.head() == 1);
  list.Rotate();
  EXPECT(list.head() == 10);
  list.Rotate();
  EXPECT(list.head() == 1);

  // Test: Remove non-existent element leaves list un-changed.
  list.Remove(4242);
  EXPECT(list.head() == 1);

  // Test: Remove head element individually moves head to next element.
  list.Remove(1);
  EXPECT(list.HasHead());
  EXPECT(list.head() == 10);
  list.Remove(10);
  EXPECT(!list.HasHead());

  // Test: Remove non-existent element from empty list works.
  list.Remove(4242);
}

}  // namespace bin
}  // namespace dart
