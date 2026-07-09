// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

import "package:expect/expect.dart";

void test(List<int> list, int index, Iterable<int> iterable) {
  List copy = list.toList();
  list.setAll(index, iterable);
  Expect.equals(copy.length, list.length);
  for (int i = 0; i < index; i++) {
    Expect.equals(copy[i], list[i]);
  }
  List iterableList = iterable.toList();
  for (int i = 0; i < iterableList.length; i++) {
    Expect.equals(iterableList[i], list[i + index]);
  }
  for (int i = index + iterableList.length; i < copy.length; i++) {
    Expect.equals(copy[i], list[i]);
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

void main() {
  for (var makeIterable in iterableMakers) {
    test([1, 2, 3], 0, makeIterable([4, 5]));
    test([1, 2, 3], 1, makeIterable([4, 5]));
    test([1, 2, 3], 2, makeIterable([4]));
    test([1, 2, 3], 3, makeIterable([]));
    test([1, 2, 3], 0, makeIterable(const [4, 5]));
    test([1, 2, 3], 1, makeIterable(const [4, 5]));
    test([1, 2, 3], 2, makeIterable(const [4]));
    test([1, 2, 3], 3, makeIterable(const []));
    test([1, 2, 3].toList(growable: false), 0, makeIterable([4, 5]));
    test([1, 2, 3].toList(growable: false), 1, makeIterable([4, 5]));
    test([1, 2, 3].toList(growable: false), 2, makeIterable([4]));
    test([1, 2, 3].toList(growable: false), 3, makeIterable([]));
    test([1, 2, 3].toList(growable: false), 0, makeIterable(const [4, 5]));
    test([1, 2, 3].toList(growable: false), 1, makeIterable(const [4, 5]));
    test([1, 2, 3].toList(growable: false), 2, makeIterable(const [4]));
    test([1, 2, 3].toList(growable: false), 3, makeIterable(const []));
    test(MyList([1, 2, 3]), 0, makeIterable([4, 5]));
    test(MyList([1, 2, 3]), 1, makeIterable([4, 5]));
    test(MyList([1, 2, 3]), 2, makeIterable([4]));
    test(MyList([1, 2, 3]), 3, makeIterable([]));

    Expect.throwsRangeError(() => test([1, 2, 3], -1, makeIterable([4, 5])));
    Expect.throwsRangeError(
      () => test([1, 2, 3].toList(growable: false), -1, makeIterable([4, 5])),
    );
    Expect.throwsRangeError(() => test([1, 2, 3], 1, makeIterable([4, 5, 6])));
    Expect.throwsRangeError(
      () => test([1, 2, 3].toList(growable: false), 1, makeIterable([4, 5, 6])),
    );
    Expect.throwsRangeError(
      () => test(MyList([1, 2, 3]), -1, makeIterable([4, 5])),
    );
    Expect.throwsRangeError(
      () => test(MyList([1, 2, 3]), 1, makeIterable([4, 5, 6])),
    );
    Expect.throwsUnsupportedError(
      () => test(const [1, 2, 3], 0, makeIterable([4, 5])),
    );
    Expect.throwsUnsupportedError(
      () => test(const [1, 2, 3], -1, makeIterable([4, 5])),
    );
    Expect.throwsUnsupportedError(
      () => test(const [1, 2, 3], 1, makeIterable([4, 5, 6])),
    );
  }
}

// `setAll` implementations can have type tests and special cases to handle
// different types of iterables differently, so we test with a few different
// types of iterables.
List<Iterable<int> Function(List<int>)> iterableMakers = [
  (list) => list,
  MyList.new,
  (list) => list.where((x) => true),
  (list) => list.map((x) => x),
  (list) => list.getRange(0, list.length),
];
