// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";

test(List<int> list, int index, Iterable<int> iterable) {
  List copy = list.toList();
  list.insertAll(index, iterable);
  List iterableList = iterable.toList();
  Expect.equals(copy.length + iterableList.length, list.length);
  for (int i = 0; i < index; i++) {
    Expect.equals(copy[i], list[i]);
  }
  for (int i = 0; i < iterableList.length; i++) {
    Expect.equals(iterableList[i], list[i + index]);
  }
  for (int i = index + iterableList.length; i < copy.length; i++) {
    Expect.equals(copy[i], list[i + iterableList.length]);
  }
}

class MyList<T> extends ListBase<T> {
  List<T> list;
  MyList(this.list);
  get length => list.length;
  set length(value) {
    list.length = value;
  }

  operator [](index) => list[index];
  operator []=(index, val) {
    list[index] = val;
  }

  void add(T element) {
    list.add(element);
  }

  toString() => list.toString();
}

main() {
  test([1, 2, 3], 0, [4, 5]);
  test([1, 2, 3], 1, [4, 5]);
  test([1, 2, 3], 2, [4, 5]);
  test([1, 2, 3], 3, [4, 5]);
  test([1, 2, 3], 2, [4]);
  test([1, 2, 3], 3, []);
  test([1, 2, 3], 0, [4, 5].map((x) => x));
  test([1, 2, 3], 1, [4, 5].map((x) => x));
  test([1, 2, 3], 2, [4, 5].map((x) => x));
  test([1, 2, 3], 3, [4, 5].map((x) => x));
  test([1, 2, 3], 2, [4].map((x) => x));
  test([1, 2, 3], 3, [].map((x) => x));
  test([1, 2, 3], 0, const [4, 5]);
  test([1, 2, 3], 1, const [4, 5]);
  test([1, 2, 3], 2, const [4, 5]);
  test([1, 2, 3], 3, const [4, 5]);
  test([1, 2, 3], 2, const [4]);
  test([1, 2, 3], 3, const []);
  test([1, 2, 3], 0, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 1, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 2, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 3, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 2, new Iterable.generate(1, (x) => x + 4));
  test([1, 2, 3], 3, new Iterable.generate(0, (x) => x + 4));
  test(new MyList([1, 2, 3]), 0, [4, 5]);
  test(new MyList([1, 2, 3]), 1, [4, 5]);
  test(new MyList([1, 2, 3]), 2, [4]);
  test(new MyList([1, 2, 3]), 3, []);
  test(new MyList([1, 2, 3]), 2, [4, 5]);
  test(new MyList([1, 2, 3]), 3, [4, 5]);
  test(new MyList([1, 2, 3]), 0, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 1, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 2, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 3, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 2, [4].map((x) => x));
  test(new MyList([1, 2, 3]), 3, [].map((x) => x));
  test(new MyList([]), 0, []);
  test(new MyList([]), 0, [4]);
  test(new MyList([]), 0, [4, 5]);
  test(new MyList([1]), 0, [4, 5]);
  test(new MyList([1]), 1, [4, 5]);

  Expect.throwsRangeError(() => test([1, 2, 3], -1, [4, 5]));
  Expect.throwsUnsupportedError(
      () => test([1, 2, 3].toList(growable: false), -1, [4, 5]));
  Expect.throwsRangeError(() => test(new MyList([1, 2, 3]), -1, [4, 5]));
  Expect.throwsUnsupportedError(
      () => test([1, 2, 3].toList(growable: false), 0, [4, 5]));
}
