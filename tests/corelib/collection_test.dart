// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CollectionTest {
  CollectionTest(Collection collection) {
    testReduce(collection);
  }

  void testReduce(Collection collection) {
    Expect.equals(28, collection.reduce(0, (prev, element) => prev + element));
    Expect.equals(
        3024, collection.reduce(1, (prev, element) => prev * element));
  }
}


main() {
  final TEST_ELEMENTS = const [4, 2, 6, 7, 9];
  // Const list.
  new CollectionTest(TEST_ELEMENTS);

  // Fixed size list.
  var fixedList = new List(TEST_ELEMENTS.length);
  for (int i = 0; i < TEST_ELEMENTS.length; i++) {
    fixedList[i] = TEST_ELEMENTS[i];
  }
  new CollectionTest(fixedList);

  // Dynamic size list.
  new CollectionTest(new List.from(TEST_ELEMENTS));

  // Dynamic size set.
  new CollectionTest(new Set.from(TEST_ELEMENTS));
}
