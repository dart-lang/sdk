// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class QueueIteratorTest {
  static testMain() {
    testSmallQueue();
    testLargeQueue();
    testEmptyQueue();
  }

  static void testThrows(Iterator<int> it) {
    Expect.equals(false, it.hasNext);
    var exception = null;
    try {
      it.next();
    } on NoMoreElementsException catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
  }

  static int sum(int expected, Iterator<int> it) {
    int count = 0;
    while (it.hasNext) {
      count += it.next();
    }
    Expect.equals(expected, count);
  }

  static void testSmallQueue() {
    Queue<int> queue = new Queue<int>();
    queue.addLast(1);
    queue.addLast(2);
    queue.addLast(3);

    Iterator<int> it = queue.iterator();
    Expect.equals(true, it.hasNext);
    sum(6, it);
    testThrows(it);
  }

  static void testLargeQueue() {
    Queue<int> queue = new Queue<int>();
    int count = 0;
    for (int i = 0; i < 100; i++) {
      count += i;
      queue.addLast(i);
    }
    Iterator<int> it = queue.iterator();
    Expect.equals(true, it.hasNext);
    sum(count, it);
    testThrows(it);
  }

  static void testEmptyQueue() {
    Queue<int> queue = new Queue<int>();
    Iterator<int> it = queue.iterator();
    Expect.equals(false, it.hasNext);
    sum(0, it);
    testThrows(it);
  }
}

main() {
  QueueIteratorTest.testMain();
}
