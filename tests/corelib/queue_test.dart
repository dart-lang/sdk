// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library queue.test;

import "package:expect/expect.dart";
import 'dart:collection';

abstract class QueueTest {
  Queue newQueue();
  Queue newQueueFrom(Iterable iterable);

  void testMain() {
    Queue queue = newQueue();
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

    Queue mapped = newQueueFrom(queue.map(mapTest));
    checkQueue(mapped, 3, 111);
    checkQueue(queue, 3, 1110);
    Expect.equals(1, mapped.removeFirst());
    Expect.equals(100, mapped.removeLast());
    Expect.equals(10, mapped.removeFirst());

    Queue other = newQueueFrom(queue.where(is10));
    checkQueue(other, 1, 10);

    Expect.equals(true, queue.any(is10));

    bool isInstanceOfInt(int value) {
      return (value is int);
    }

    Expect.equals(true, queue.every(isInstanceOfInt));

    Expect.equals(false, queue.every(is10));

    bool is1(int value) {
      return (value == 1);
    }

    Expect.equals(false, queue.any(is1));

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

    other = newQueueFrom(queue.where(isGreaterThanOne));
    checkQueue(other, 2, 5);

    // Cycle through values without ever having large element count.
    queue = newQueue();
    queue.add(0);
    for (int i = 0; i < 255; i++) {
      queue.add(i + 1);
      Expect.equals(i, queue.removeFirst());
    }
    Expect.equals(255, queue.removeFirst());
    Expect.isTrue(queue.isEmpty);

    testAddAll();
    testLengthChanges();
    testLarge();
    testFromListToList();
  }

  void checkQueue(Queue queue, int expectedSize, int expectedSum) {
    testLength(expectedSize, queue);
    int sum = 0;
    void sumElements(int value) {
      sum += value;
    }

    queue.forEach(sumElements);
    Expect.equals(expectedSum, sum);
  }

  testLength(int length, Queue queue) {
    Expect.equals(length, queue.length);
    ((length == 0) ? Expect.isTrue : Expect.isFalse)(queue.isEmpty);
    ((length != 0) ? Expect.isTrue : Expect.isFalse)(queue.isNotEmpty);
  }

  void testAddAll() {
    Set<int> set = new Set<int>.from([1, 2, 4]);
    Expect.equals(3, set.length);

    Queue queue1 = newQueueFrom(set);
    Queue queue2 = newQueue();
    Queue queue3 = newQueue();
    testLength(3, queue1);
    testLength(0, queue2);
    testLength(0, queue3);

    queue2.addAll(set);
    testLength(3, queue2);

    queue3.addAll(queue1);
    testLength(3, queue3);

    int sum = 0;
    void f(e) {
      sum += e;
    }

    ;

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
    queue1 = newQueueFrom(set);
    queue2 = newQueue();
    queue3 = newQueue();

    queue2.addAll(set);
    queue3.addAll(queue1);

    Expect.equals(0, set.length);
    Expect.equals(0, queue1.length);
    Expect.equals(0, queue2.length);
    Expect.equals(0, queue3.length);
  }

  void testLengthChanges() {
    // Test that the length property is updated properly by
    // modifications;
    Queue queue = newQueue();
    testLength(0, queue);

    for (int i = 1; i <= 10; i++) {
      queue.add(i);
      testLength(i, queue);
    }

    for (int i = 1; i <= 10; i++) {
      queue.addFirst(11 - i);
      testLength(10 + i, queue);
    }

    for (int i = 1; i <= 10; i++) {
      queue.addLast(i);
      testLength(20 + i, queue);
    }

    queue.addAll([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    testLength(40, queue);

    for (int i = 1; i <= 5; i++) {
      Expect.equals(i, queue.removeFirst());
      testLength(40 - i, queue);
    }

    for (int i = 1; i <= 5; i++) {
      Expect.equals(11 - i, queue.removeLast());
      testLength(35 - i, queue);
    }

    Expect.isTrue(queue.remove(10));
    testLength(29, queue);
    Expect.isFalse(queue.remove(999));
    testLength(29, queue);

    queue.removeWhere((x) => x == 7);
    testLength(26, queue);

    queue.retainWhere((x) => x != 3);
    testLength(23, queue);

    Expect.listEquals(
        [6, 8, 9, 1, 2, 4, 5, 6, 8, 9, 10, 1, 2, 4, 5, 6, 8, 9, 10, 1, 2, 4, 5],
        queue.toList());

    // Regression test: http://dartbug.com/16270
    // These should all do nothing, and should not throw.
    Queue emptyQueue = newQueue();
    emptyQueue.remove(0);
    emptyQueue.removeWhere((x) => null);
    emptyQueue.retainWhere((x) => null);
  }

  void testLarge() {
    int N = 10000;
    Set set = new Set();

    Queue queue = newQueue();
    Expect.isTrue(queue.isEmpty);

    for (int i = 0; i < N; i++) {
      queue.add(i);
      set.add(i);
    }
    Expect.equals(N, queue.length);
    Expect.isFalse(queue.isEmpty);

    Expect.equals(0, queue.elementAt(0));
    Expect.equals(N - 1, queue.elementAt(N - 1));
    Expect.throws(() {
      queue.elementAt(-1);
    });
    Expect.throws(() {
      queue.elementAt(N);
    });

    Iterable skip1 = queue.skip(1);
    Iterable take1 = queue.take(1);
    Iterable mapped = queue.map((e) => -e);

    for (int i = 0; i < 500; i++) {
      Expect.equals(i, take1.first);
      Expect.equals(i, queue.first);
      Expect.equals(-i, mapped.first);
      Expect.equals(i + 1, skip1.first);
      Expect.equals(i, queue.removeFirst());
      Expect.equals(i + 1, take1.first);
      Expect.equals(-i - 1, mapped.first);
      Expect.equals(N - 1 - i, queue.last);
      Expect.equals(N - 1 - i, queue.removeLast());
    }
    Expect.equals(N - 1000, queue.length);

    Expect.isTrue(queue.remove(N >> 1));
    Expect.equals(N - 1001, queue.length);

    queue.clear();
    Expect.equals(0, queue.length);
    Expect.isTrue(queue.isEmpty);

    queue.addAll(set);
    Expect.equals(N, queue.length);
    Expect.isFalse(queue.isEmpty);

    // Iterate.
    for (var element in queue) {
      Expect.isTrue(set.contains(element));
    }

    queue.forEach((element) {
      Expect.isTrue(set.contains(element));
    });

    queue.addAll(set);
    Expect.equals(N * 2, queue.length);
    Expect.isFalse(queue.isEmpty);

    queue.clear();
    Expect.equals(0, queue.length);
    Expect.isTrue(queue.isEmpty);
  }

  void testFromListToList() {
    const int N = 256;
    List list = [];
    for (int i = 0; i < N; i++) {
      Queue queue = newQueueFrom(list);

      Expect.equals(list.length, queue.length);
      List to = queue.toList();
      Expect.listEquals(list, to);

      queue.add(i);
      list.add(i);
      Expect.equals(list.length, queue.length);
      to = queue.toList();
      Expect.listEquals(list, to);
    }
  }
}

class ListQueueTest extends QueueTest {
  Queue newQueue() => new ListQueue();
  Queue newQueueFrom(Iterable elements) => new ListQueue.from(elements);

  void testMain() {
    super.testMain();
    trickyTest();
  }

  void trickyTest() {
    // Test behavior around the know growing capacities of a ListQueue.
    Queue q = new ListQueue();

    for (int i = 0; i < 255; i++) {
      q.add(i);
    }
    for (int i = 0; i < 128; i++) {
      Expect.equals(i, q.removeFirst());
    }
    q.add(255);
    for (int i = 0; i < 127; i++) {
      q.add(i);
    }

    Expect.equals(255, q.length);

    // Remove element at end of internal buffer.
    q.removeWhere((v) => v == 255);
    // Remove element at beginning of internal buffer.
    q.removeWhere((v) => v == 0);
    // Remove element at both ends of internal buffer.
    q.removeWhere((v) => v == 254 || v == 1);

    Expect.equals(251, q.length);

    Iterable i255 = new Iterable.generate(255, (x) => x);

    q = new ListQueue();
    q.addAll(i255);
    Expect.listEquals(i255.toList(), q.toList());

    q = new ListQueue();
    q.addAll(i255.toList());
    Expect.listEquals(i255.toList(), q.toList());

    q = new ListQueue.from(i255);
    for (int i = 0; i < 128; i++) q.removeFirst();
    q.add(256);
    q.add(0);
    q.addAll(i255.toList());
    Expect.equals(129 + 255, q.length);

    // Test addAll that requires the queue to grow.
    q = new ListQueue();
    q.addAll(i255.take(35));
    q.addAll(i255.skip(35).take(96));
    q.addAll(i255.skip(35 + 96));
    Expect.listEquals(i255.toList(), q.toList());
  }
}

class DoubleLinkedQueueTest extends QueueTest {
  Queue newQueue() => new DoubleLinkedQueue();
  Queue newQueueFrom(Iterable elements) => new DoubleLinkedQueue.from(elements);

  void testMain() {
    super.testMain();
    testQueueElements();
  }

  void testQueueElements() {
    DoubleLinkedQueue<int> queue1 = new DoubleLinkedQueue<int>.from([1, 2, 3]);
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

    var firstEntry = queue1.firstEntry();
    var secondEntry = queue1.firstEntry().nextEntry();
    var thirdEntry = queue1.lastEntry();
    firstEntry.prepend(4);
    firstEntry.append(5);
    secondEntry.prepend(6);
    secondEntry.append(7);
    thirdEntry.prepend(8);
    thirdEntry.append(9);
    Expect.equals(9, queue1.length);
    Expect.listEquals(queue1.toList(), [4, 1, 5, 6, 2, 7, 8, 3, 9]);
    Expect.equals(1, firstEntry.remove());
    Expect.equals(2, secondEntry.remove());
    Expect.equals(3, thirdEntry.remove());
    Expect.equals(6, queue1.length);
    Expect.listEquals(queue1.toList(), [4, 5, 6, 7, 8, 9]);
  }
}

void linkEntryTest() {
  var entry = new DoubleLinkedQueueEntry(42);
  Expect.equals(null, entry.previousEntry());
  Expect.equals(null, entry.nextEntry());

  entry.append(37);
  entry.prepend(87);
  var prev = entry.previousEntry();
  var next = entry.nextEntry();
  Expect.equals(42, entry.element);
  Expect.equals(37, next.element);
  Expect.equals(87, prev.element);
  Expect.identical(entry, prev.nextEntry());
  Expect.identical(entry, next.previousEntry());
  Expect.equals(null, next.nextEntry());
  Expect.equals(null, prev.previousEntry());

  entry.element = 117;
  Expect.equals(117, entry.element);
  Expect.identical(next, entry.nextEntry());
  Expect.identical(prev, entry.previousEntry());

  Expect.equals(117, entry.remove());
  Expect.identical(next, prev.nextEntry());
  Expect.identical(prev, next.previousEntry());
  Expect.equals(null, next.nextEntry());
  Expect.equals(null, prev.previousEntry());
  Expect.equals(37, next.element);
  Expect.equals(87, prev.element);

  Expect.equals(37, next.remove());
  Expect.equals(87, prev.element);
  Expect.equals(null, prev.nextEntry());
  Expect.equals(null, prev.previousEntry());

  Expect.equals(87, prev.remove());
}

main() {
  new DoubleLinkedQueueTest().testMain();
  new ListQueueTest().testMain();
  linkEntryTest();
}
