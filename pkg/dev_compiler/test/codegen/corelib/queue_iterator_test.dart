// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library queue.iterator.test;

import "package:expect/expect.dart";
import 'dart:collection' show Queue;

class QueueIteratorTest {
  static testMain() {
    testSmallQueue();
    testLargeQueue();
    testEmptyQueue();
  }

  static int sum(int expected, Iterator<int> it) {
    int count = 0;
    while (it.moveNext()) {
      count += it.current;
    }
    Expect.equals(expected, count);
  }

  static void testSmallQueue() {
    Queue<int> queue = new Queue<int>();
    queue.addLast(1);
    queue.addLast(2);
    queue.addLast(3);

    Iterator<int> it = queue.iterator;
    sum(6, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }

  static void testLargeQueue() {
    Queue<int> queue = new Queue<int>();
    int count = 0;
    for (int i = 0; i < 100; i++) {
      count += i;
      queue.addLast(i);
    }
    Iterator<int> it = queue.iterator;
    sum(count, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }

  static void testEmptyQueue() {
    Queue<int> queue = new Queue<int>();
    Iterator<int> it = queue.iterator;
    sum(0, it);
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }
}

main() {
  QueueIteratorTest.testMain();
}
