// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "dart:collection";
import "package:expect/expect.dart";

// Test foreach (aka. for-in) functionality.

testIterator(List expect, Iterable input) {
  int i = 0;
  for (var value in input) {
    Expect.isTrue(i < expect.length);
    Expect.equals(expect[i], value);
    i += 1;
  }
  Expect.equals(expect.length, i);

  i = 0;
  var value2;
  for (value2 in input) {
    Expect.isTrue(i < expect.length);
    Expect.equals(expect[i], value2);
    i += 1;
  }
  Expect.equals(expect.length, i);
}

class MyIterable<T> extends IterableBase<T> {
  final List<T> values;
  MyIterable(List<T> values) : this.values = values;
  Iterator<T> get iterator {
    return new MyListIterator<T>(values);
  }
}

class MyListIterator<T> implements Iterator<T> {
  final List<T> values;
  int index;
  MyListIterator(List<T> values)
      : this.values = values,
        index = -1;

  bool moveNext() => ++index < values.length;
  T get current => (0 <= index && index < values.length) ? values[index] : null;
}

void main() {
  testIterator([], []);
  testIterator([], new MyIterable([]));
  testIterator([1], [1]);
  testIterator([1], new MyIterable([1]));
  testIterator([1, 2, 3], [1, 2, 3]);
  testIterator([1, 2, 3], new MyIterable([1, 2, 3]));
  testIterator(["a", "b", "c"], ["a", "b", "c"]);
  testIterator(["a", "b", "c"], new MyIterable(["a", "b", "c"]));

  // Several nested for-in's.
  for (var x in [
    [
      ["a"]
    ]
  ]) {
    for (var y in x) {
      for (var z in y) {
        Expect.equals("a", z);
      }
    }
  }

  // Simultaneous iteration of the same iterable.
  for (var iterable in [
    [1, 2, 3],
    new MyIterable([1, 2, 3])
  ]) {
    int result = 0;
    for (var x in iterable) {
      for (var y in iterable) {
        result += x * y;
      }
    }
    Expect.equals(36, result);
  }

  // Using the same variable (showing that the expression is evaluated
  // in the outer scope).
  int result = 0;
  var x = [1, 2, 3];
  for (var x in x) {
    result += x;
  }
  Expect.equals(6, result);
}
