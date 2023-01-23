// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from lib/collection/queue_test which showed in error in the
// of private names in dart2js.

library queue.test;

import 'private_names_lib1.dart';

class DoubleLinkedQueueTest {
  void testMain() {
    testQueueElements();
  }

  void testQueueElements() {
    DoubleLinkedQueue<int> queue1 = new DoubleLinkedQueue<int>.from([1, 2, 3]);
    var firstEntry = queue1.firstEntry()!;
    firstEntry.prepend(4);
  }
}

void linkEntryTest() {
  var entry = new DoubleLinkedQueueEntry(42);
}

main() {
  new DoubleLinkedQueueTest().testMain();
  linkEntryTest();
}
