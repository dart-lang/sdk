// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <vector>

#include "platform/list_queue.h"
#include "vm/unit_test.h"

namespace dart {

void ExpectContentsToBe(const ListQueue<intptr_t>& actual,
                        const std::vector<intptr_t>& expected) {
  intptr_t i = 0;
  actual.ForEach([&expected, &i](intptr_t actual_element) {
    EXPECT(actual_element == expected[i]);
    ++i;
  });
}

VM_UNIT_TEST_CASE(ListQueue_PublicMethods) {
  ListQueue<intptr_t> l;
  intptr_t front = -1;

  l.PushBack(1);
  ExpectContentsToBe(l, {1});
  EXPECT(l.Length() == 1);

  front = l.PopFront();
  EXPECT(front == 1);
  ExpectContentsToBe(l, {});
  EXPECT(l.Length() == 0);

  l.PushBack(2);
  ExpectContentsToBe(l, {2});
  EXPECT(l.Length() == 1);

  l.PushBack(3);
  ExpectContentsToBe(l, {2, 3});
  EXPECT(l.Length() == 2);

  front = l.PopFront();
  EXPECT(front == 2);
  ExpectContentsToBe(l, {3});
  EXPECT(l.Length() == 1);

  l.PushBack(4);
  ExpectContentsToBe(l, {3, 4});
  EXPECT(l.Length() == 2);
}

VM_UNIT_TEST_CASE(ListQueue_Grow) {
  const intptr_t kInitialCapacity = ListQueue<intptr_t>::kInitialCapacity;

  ListQueue<intptr_t> l;
  l.PushBack(1);
  ExpectContentsToBe(l, {1});
  l.PopFront();
  ExpectContentsToBe(l, {});

  // Force |l| to grow by adding more than |kInitialCapacity| elements to it.
  for (intptr_t i = 0; i <= kInitialCapacity + 3; ++i) {
    l.PushBack(123);
  }

  ExpectContentsToBe(l, std::vector<intptr_t>(kInitialCapacity + 4, 123));
}

}  // namespace dart
