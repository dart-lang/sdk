// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

void main() {
  testSetRangeTooFewElementsAndSkipCount();
  testSetAllIndexRangeCheckOnEmptyIterable();
}

void testSetRangeTooFewElementsAndSkipCount() {
  for (final makeList in <List<int> Function(List<int>)>[
    (l) => List<int>.of(l, growable: true),
    (l) => List<int>.of(l, growable: false),
    (l) => CustomList(List<int>.of(l)),
  ]) {
    Expect.throwsStateError(
      () => makeList([1, 2, 3, 4, 5]).setRange(0, 4, CustomList([10, 20]), 0),
    );
    Expect.throwsStateError(
      () => makeList([1, 2, 3, 4, 5]).setRange(0, 4, [10, 20].map((x) => x), 0),
    );
    Expect.throwsStateError(
      () => makeList([1, 2, 3, 4, 5]).setRange(0, 4, [10, 20], 0),
    );
    Expect.throwsStateError(() {
      final list = makeList([1, 2, 3, 4, 5]);
      list.setRange(0, 4, list, 2);
    });
    Expect.throwsArgumentError(
      () => makeList([1, 2, 3, 4, 5]).setRange(0, 1, [10, 20], -1),
    );
  }
}

void testSetAllIndexRangeCheckOnEmptyIterable() {
  for (final makeList in <List<int> Function(List<int>)>[
    (l) => List<int>.of(l, growable: true),
    (l) => List<int>.of(l, growable: false),
    (l) => CustomList(List<int>.of(l)),
  ]) {
    Expect.throwsRangeError(
      () => makeList([1, 2, 3]).setAll(-1, <int>[].map((x) => x)),
    );
    Expect.throwsRangeError(
      () => makeList([1, 2, 3]).setAll(4, <int>[].map((x) => x)),
    );
  }
}

class CustomList<E> extends ListBase<E> {
  final List<E> inner;

  CustomList(this.inner);

  @override
  int get length => inner.length;

  @override
  set length(int value) => inner.length = value;

  @override
  E operator [](int index) => inner[index];

  @override
  void operator []=(int index, E value) => inner[index] = value;

  @override
  void add(E element) => inner.add(element);
}
