// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:collection/collection.dart";
import "package:unittest/unittest.dart";

void main() {
  group("new QueueList()", () {
    test("creates an empty QueueList", () {
      expect(new QueueList(), isEmpty);
    });

    test("takes an initial capacity", () {
      expect(new QueueList(100), isEmpty);
    });
  });

  test("new QueueList.from() copies the contents of an iterable", () {
    expect(new QueueList.from([1, 2, 3].skip(1)), equals([2, 3]));
  });

  group("add()", () {
    test("adds an element to the end of the queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      queue.add(4);
      expect(queue, equals([1, 2, 3, 4]));
    });

    test("expands a full queue", () {
      var queue = atCapacity();
      queue.add(8);
      expect(queue, equals([1, 2, 3, 4, 5, 6, 7, 8]));
    });
  });

  group("addAll()", () {
    test("adds elements to the end of the queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      queue.addAll([4, 5, 6]);
      expect(queue, equals([1, 2, 3, 4, 5, 6]));
    });

    test("expands a full queue", () {
      var queue = atCapacity();
      queue.addAll([8, 9]);
      expect(queue, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });
  });

  group("addFirst()", () {
    test("adds an element to the beginning of the queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      queue.addFirst(0);
      expect(queue, equals([0, 1, 2, 3]));
    });

    test("expands a full queue", () {
      var queue = atCapacity();
      queue.addFirst(0);
      expect(queue, equals([0, 1, 2, 3, 4, 5, 6, 7]));
    });
  });

  group("removeFirst()", () {
    test("removes an element from the beginning of the queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      expect(queue.removeFirst(), equals(1));
      expect(queue, equals([2, 3]));
    });

    test("removes an element from the beginning of a queue with an internal "
        "gap", () {
      var queue = withInternalGap();
      expect(queue.removeFirst(), equals(1));
      expect(queue, equals([2, 3, 4, 5, 6, 7]));
    });

    test("removes an element from the beginning of a queue at capacity", () {
      var queue = atCapacity();
      expect(queue.removeFirst(), equals(1));
      expect(queue, equals([2, 3, 4, 5, 6, 7]));
    });

    test("throws a StateError for an empty queue", () {
      expect(new QueueList().removeFirst, throwsStateError);
    });
  });

  group("removeLast()", () {
    test("removes an element from the end of the queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      expect(queue.removeLast(), equals(3));
      expect(queue, equals([1, 2]));
    });

    test("removes an element from the end of a queue with an internal gap", () {
      var queue = withInternalGap();
      expect(queue.removeLast(), equals(7));
      expect(queue, equals([1, 2, 3, 4, 5, 6]));
    });

    test("removes an element from the end of a queue at capacity", () {
      var queue = atCapacity();
      expect(queue.removeLast(), equals(7));
      expect(queue, equals([1, 2, 3, 4, 5, 6]));
    });

    test("throws a StateError for an empty queue", () {
      expect(new QueueList().removeLast, throwsStateError);
    });
  });

  group("length", () {
    test("returns the length of a queue", () {
      expect(new QueueList.from([1, 2, 3]).length, equals(3));
    });

    test("returns the length of a queue with an internal gap", () {
      expect(withInternalGap().length, equals(7));
    });

    test("returns the length of a queue at capacity", () {
      expect(atCapacity().length, equals(7));
    });
  });

  group("length=", () {
    test("shrinks a larger queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      queue.length = 1;
      expect(queue, equals([1]));
    });

    test("grows a smaller queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      queue.length = 5;
      expect(queue, equals([1, 2, 3, null, null]));
    });

    test("throws a RangeError if length is less than 0", () {
      expect(() => new QueueList().length = -1, throwsRangeError);
    });
  });

  group("[]", () {
    test("returns individual entries in the queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      expect(queue[0], equals(1));
      expect(queue[1], equals(2));
      expect(queue[2], equals(3));
    });

    test("returns individual entries in a queue with an internal gap", () {
      var queue = withInternalGap();
      expect(queue[0], equals(1));
      expect(queue[1], equals(2));
      expect(queue[2], equals(3));
      expect(queue[3], equals(4));
      expect(queue[4], equals(5));
      expect(queue[5], equals(6));
      expect(queue[6], equals(7));
    });

    test("throws a RangeError if the index is less than 0", () {
      var queue = new QueueList.from([1, 2, 3]);
      expect(() => queue[-1], throwsRangeError);
    });

    test("throws a RangeError if the index is greater than or equal to the "
        "length", () {
      var queue = new QueueList.from([1, 2, 3]);
      expect(() => queue[3], throwsRangeError);
    });
  });

  group("[]=", () {
    test("sets individual entries in the queue", () {
      var queue = new QueueList.from([1, 2, 3]);
      queue[0] = "a";
      queue[1] = "b";
      queue[2] = "c";
      expect(queue, equals(["a", "b", "c"]));
    });

    test("sets individual entries in a queue with an internal gap", () {
      var queue = withInternalGap();
      queue[0] = "a";
      queue[1] = "b";
      queue[2] = "c";
      queue[3] = "d";
      queue[4] = "e";
      queue[5] = "f";
      queue[6] = "g";
      expect(queue, equals(["a", "b", "c", "d", "e", "f", "g"]));
    });

    test("throws a RangeError if the index is less than 0", () {
      var queue = new QueueList.from([1, 2, 3]);
      expect(() {
        queue[-1] = 0;
      }, throwsRangeError);
    });

    test("throws a RangeError if the index is greater than or equal to the "
        "length", () {
      var queue = new QueueList.from([1, 2, 3]);
      expect(() {
        queue[3] = 4;
      }, throwsRangeError);
    });
  });

  group("throws a modification error for", () {
    var queue;
    setUp(() {
      queue = new QueueList.from([1, 2, 3]);
    });

    test("add", () {
      expect(() => queue.forEach((_) => queue.add(4)),
          throwsConcurrentModificationError);
    });

    test("addAll", () {
      expect(() => queue.forEach((_) => queue.addAll([4, 5, 6])),
          throwsConcurrentModificationError);
    });

    test("addFirst", () {
      expect(() => queue.forEach((_) => queue.addFirst(0)),
          throwsConcurrentModificationError);
    });

    test("removeFirst", () {
      expect(() => queue.forEach((_) => queue.removeFirst()),
          throwsConcurrentModificationError);
    });

    test("removeLast", () {
      expect(() => queue.forEach((_) => queue.removeLast()),
          throwsConcurrentModificationError);
    });

    test("length=", () {
      expect(() => queue.forEach((_) => queue.length = 1),
          throwsConcurrentModificationError);
    });
  });
}

/// Returns a queue whose internal ring buffer is full enough that adding a new
/// element will expand it.
QueueList atCapacity() {
  // Use addAll because [new QueueList.from(List)] won't use the default initial
  // capacity of 8.
  return new QueueList()..addAll([1, 2, 3, 4, 5, 6, 7]);
}

/// Returns a queue whose internal tail has a lower index than its head.
QueueList withInternalGap() {
  var queue = new QueueList.from([null, null, null, null, 1, 2, 3, 4]);
  for (var i = 0; i < 4; i++) {
    queue.removeFirst();
  }
  for (var i = 5; i < 8; i++) {
    queue.addLast(i);
  }
  return queue;
}

/// Returns a matcher that expects that a closure throws a
/// [ConcurrentModificationError].
final throwsConcurrentModificationError = throwsA(
    new isInstanceOf<ConcurrentModificationError>(
        "ConcurrentModificationError"));
