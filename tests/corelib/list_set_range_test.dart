// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

import "package:expect/expect.dart";

void main() {
  for (var makeIterable in iterableMakers) {
    var list = [];
    list.setRange(0, 0, makeIterable(const []));
    list.setRange(0, 0, makeIterable([]));
    list.setRange(0, 0, makeIterable(const []), 1);
    list.setRange(0, 0, makeIterable([]), 1);
    Expect.listEquals([], list);
    Expect.throwsRangeError(() => list.setRange(0, 1, []));
    Expect.throwsRangeError(() => list.setRange(0, 1, [], 1));
    Expect.throwsRangeError(() => list.setRange(0, 1, [1], 0));

    list = [1];
    list.setRange(0, 0, makeIterable([]), 0);
    Expect.listEquals([1], list);
    list.setRange(0, 0, makeIterable(const []), 0);
    Expect.listEquals([1], list);

    Expect.throwsRangeError(() => list.setRange(0, 2, [1, 2]));
    Expect.listEquals([1], list);

    Expect.throwsStateError(() => list.setRange(0, 1, [1, 2], 2));
    Expect.listEquals([1], list);

    Expect.throwsStateError(() => list.setRange(0, 1, list, 2));
    Expect.listEquals([1], list);

    list.setRange(0, 1, makeIterable([2]), 0);
    Expect.listEquals([2], list);

    list.setRange(0, 1, makeIterable(const [3]), 0);
    Expect.listEquals([3], list);

    list = [3, 4, 5, 6];
    list.setRange(0, 4, makeIterable([1, 2, 3, 4]));
    Expect.listEquals([1, 2, 3, 4], list);

    list.setRange(2, 4, makeIterable([5, 6, 7, 8]));
    Expect.listEquals([1, 2, 5, 6], list);

    Expect.throwsRangeError(
      () => list.setRange(4, 5, makeIterable([5, 6, 7, 8])),
    );
    Expect.listEquals([1, 2, 5, 6], list);

    list.setRange(1, 3, makeIterable([9, 10, 11, 12]));
    Expect.listEquals([1, 9, 10, 6], list);
  }

  testNegativeIndices();

  testNonExtendableList();

  testNotEnoughElements();
}

void testNegativeIndices() {
  for (var makeIterable in iterableMakers) {
    var list = [1, 2];
    Expect.throwsRangeError(() => list.setRange(-1, 1, makeIterable([1])));
    Expect.throwsArgumentError(
      () => list.setRange(0, 1, makeIterable([1]), -1),
    );

    Expect.throwsRangeError(() => list.setRange(2, 1, makeIterable([1])));

    Expect.throwsArgumentError(
      () => list.setRange(-1, -2, makeIterable([1]), -1),
    );
    Expect.listEquals([1, 2], list);

    Expect.throwsRangeError(() => list.setRange(-1, -1, makeIterable([1])));
    Expect.listEquals([1, 2], list);

    // The skipCount is only used if the length is not 0.
    list.setRange(0, 0, makeIterable([1]), -1);
    Expect.listEquals([1, 2], list);
  }
}

void testNonExtendableList() {
  for (var makeIterable in iterableMakers) {
    var list = List<int?>.filled(6, null);
    Expect.listEquals([null, null, null, null, null, null], list);
    list.setRange(0, 3, makeIterable([1, 2, 3, 4]));
    list.setRange(3, 6, makeIterable([1, 2, 3, 4]));
    Expect.listEquals([1, 2, 3, 1, 2, 3], list);
  }
}

// Test errors when there aren't enough elements in the source iterable.
void testNotEnoughElements() {
  // Check errors when the source doesn't have enough elements after skipping
  // `skipCount` elements.
  for (var makeIterable in iterableMakers) {
    List<int> list = [1, 2, 3, 4, 5];
    Expect.throws(() => list.setRange(0, 5, makeIterable([9, 9, 9])));
  }

  // Check errors when the source doesn't have `skipCount` elements.
  for (var makeIterable in iterableMakers) {
    List<int> list = [1, 2, 3, 4, 5];
    Expect.throws(() => list.setRange(0, 5, makeIterable([9, 9, 9]), 5));
  }
}

class MyList<T> extends ListBase<T> {
  final List<T> list;
  MyList(this.list);
  get length => list.length;
  set length(value) {
    list.length = value;
  }

  operator [](index) => list[index];
  operator []=(index, val) {
    list[index] = val;
  }

  toString() => list.toString();
}

// `setRange` implementations can have type tests and special cases to handle
// different types of iterables differently, so we test with a few different
// types of iterables.
List<Iterable<int> Function(List<int>)> iterableMakers = [
  (list) => list,
  MyList.new,
  (list) => list.where((x) => true),
  (list) => list.map((x) => x),
  (list) => list.getRange(0, list.length),
];
