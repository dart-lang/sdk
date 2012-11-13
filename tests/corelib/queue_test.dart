// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library queue_test;

class QueueTest {

  static testMain() {
    Queue queue = new Queue();
    checkQueue(queue, 0, 0);

    queue.addFirst(1);
    checkQueue(queue, 1, 1);

    queue.addLast(10);
    checkQueue(queue, 2, 11);

    Expect.equals(10, queue.removeLast());
    checkQueue(queue, 1, 1);

    queue.addLast(10);
    Expect.equals(1, queue.removeFirst());
    checkQueue(queue, 1, 10);

    queue.addFirst(1);
    queue.addLast(100);
    queue.addLast(1000);
    Expect.equals(1000, queue.removeLast());
    queue.addLast(1000);
    checkQueue(queue, 4, 1111);

    queue.removeFirst();
    checkQueue(queue, 3, 1110);

    int mapTest(int value) {
      return value ~/ 10;
    }

    bool is10(int value) {
      return (value == 10);
    }

    Queue mapped = queue.map(mapTest);
    checkQueue(mapped, 3, 111);
    checkQueue(queue, 3, 1110);
    Expect.equals(1, mapped.removeFirst());
    Expect.equals(100, mapped.removeLast());
    Expect.equals(10, mapped.removeFirst());

    Queue other = queue.filter(is10);
    checkQueue(other, 1, 10);

    Expect.equals(true, queue.some(is10));

    bool isInstanceOfInt(int value) {
      return (value is int);
    }

    Expect.equals(true, queue.every(isInstanceOfInt));

    Expect.equals(false, queue.every(is10));

    bool is1(int value) {
      return (value == 1);
    }
    Expect.equals(false, queue.some(is1));

    queue.clear();
    Expect.equals(0, queue.length);

    var exception = null;
    try {
      queue.removeFirst();
    } on StateError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
    Expect.equals(0, queue.length);

    exception = null;
    try {
      queue.removeLast();
    } on StateError catch (e) {
      exception = e;
    }
    Expect.equals(true, exception != null);
    Expect.equals(0, queue.length);

    queue.addFirst(1);
    queue.addFirst(2);
    Expect.equals(2, queue.first);
    Expect.equals(1, queue.last);

    queue.addLast(3);
    Expect.equals(3, queue.last);
    bool isGreaterThanOne(int value) {
      return (value > 1);
    }

    other = queue.filter(isGreaterThanOne);
    checkQueue(other, 2, 5);

    testAddAll();
  }

  static void checkQueue(Queue queue, int expectedSize, int expectedSum) {
    Expect.equals(expectedSize, queue.length);
    int sum = 0;
    void sumElements(int value) {
      sum += value;
    }
    queue.forEach(sumElements);
    Expect.equals(expectedSum, sum);
  }

  static testAddAll() {
    Set<int> set = new Set<int>.from([1, 2, 4]);

    Queue<int> queue1 = new Queue<int>.from(set);
    Queue<int> queue2 = new Queue<int>();
    Queue<int> queue3 = new Queue<int>();

    queue2.addAll(set);
    queue3.addAll(queue1);

    Expect.equals(3, set.length);
    Expect.equals(3, queue1.length);
    Expect.equals(3, queue2.length);
    Expect.equals(3, queue3.length);

    int sum = 0;
    void f(e) { sum += e; };

    set.forEach(f);
    Expect.equals(7, sum);
    sum = 0;

    queue1.forEach(f);
    Expect.equals(7, sum);
    sum = 0;

    queue2.forEach(f);
    Expect.equals(7, sum);
    sum = 0;

    queue3.forEach(f);
    Expect.equals(7, sum);
    sum = 0;

    set = new Set<int>.from([]);
    queue1 = new Queue<int>.from(set);
    queue2 = new Queue<int>();
    queue3 = new Queue<int>();

    queue2.addAll(set);
    queue3.addAll(queue1);

    Expect.equals(0, set.length);
    Expect.equals(0, queue1.length);
    Expect.equals(0, queue2.length);
    Expect.equals(0, queue3.length);

    testQueueElements();
  }

  static testQueueElements() {
    DoubleLinkedQueue<int> queue1 = new DoubleLinkedQueue<int>.from([1, 2, 4]);
    DoubleLinkedQueue<int> queue2 = new DoubleLinkedQueue<int>();
    queue2.addAll(queue1);

    Expect.equals(queue1.length, queue2.length);
    DoubleLinkedQueueEntry<int> entry1 = queue1.firstEntry();
    DoubleLinkedQueueEntry<int> entry2 = queue2.firstEntry();
    while (entry1 != null) {
      Expect.equals(true, !identical(entry1, entry2));
      entry1 = entry1.nextEntry();
      entry2 = entry2.nextEntry();
    }
    Expect.equals(null, entry2);
  }
}

main() {
  QueueTest.testMain();
}
