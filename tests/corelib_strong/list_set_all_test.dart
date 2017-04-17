// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";

test(List list, int index, Iterable iterable) {
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

class MyList extends ListBase {
  List list;
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

main() {
  test([1, 2, 3], 0, [4, 5]);
  test([1, 2, 3], 1, [4, 5]);
  test([1, 2, 3], 2, [4]);
  test([1, 2, 3], 3, []);
  test([1, 2, 3], 0, [4, 5].map((x) => x));
  test([1, 2, 3], 1, [4, 5].map((x) => x));
  test([1, 2, 3], 2, [4].map((x) => x));
  test([1, 2, 3], 3, [].map((x) => x));
  test([1, 2, 3], 0, const [4, 5]);
  test([1, 2, 3], 1, const [4, 5]);
  test([1, 2, 3], 2, const [4]);
  test([1, 2, 3], 3, const []);
  test([1, 2, 3], 0, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 1, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 2, new Iterable.generate(1, (x) => x + 4));
  test([1, 2, 3], 3, new Iterable.generate(0, (x) => x + 4));
  test([1, 2, 3].toList(growable: false), 0, [4, 5]);
  test([1, 2, 3].toList(growable: false), 1, [4, 5]);
  test([1, 2, 3].toList(growable: false), 2, [4]);
  test([1, 2, 3].toList(growable: false), 3, []);
  test([1, 2, 3].toList(growable: false), 0, [4, 5].map((x) => x));
  test([1, 2, 3].toList(growable: false), 1, [4, 5].map((x) => x));
  test([1, 2, 3].toList(growable: false), 2, [4].map((x) => x));
  test([1, 2, 3].toList(growable: false), 3, [].map((x) => x));
  test([1, 2, 3].toList(growable: false), 0, const [4, 5]);
  test([1, 2, 3].toList(growable: false), 1, const [4, 5]);
  test([1, 2, 3].toList(growable: false), 2, const [4]);
  test([1, 2, 3].toList(growable: false), 3, const []);
  test([1, 2, 3].toList(growable: false), 0,
      new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3].toList(growable: false), 1,
      new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3].toList(growable: false), 2,
      new Iterable.generate(1, (x) => x + 4));
  test([1, 2, 3].toList(growable: false), 3,
      new Iterable.generate(0, (x) => x + 4));
  test(new MyList([1, 2, 3]), 0, [4, 5]);
  test(new MyList([1, 2, 3]), 1, [4, 5]);
  test(new MyList([1, 2, 3]), 2, [4]);
  test(new MyList([1, 2, 3]), 3, []);
  test(new MyList([1, 2, 3]), 0, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 1, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 2, [4].map((x) => x));
  test(new MyList([1, 2, 3]), 3, [].map((x) => x));

  expectRE(() => test([1, 2, 3], -1, [4, 5]));
  expectRE(() => test([1, 2, 3].toList(growable: false), -1, [4, 5]));
  expectRE(() => test([1, 2, 3], 1, [4, 5, 6]));
  expectRE(() => test([1, 2, 3].toList(growable: false), 1, [4, 5, 6]));
  expectRE(() => test(new MyList([1, 2, 3]), -1, [4, 5]));
  expectRE(() => test(new MyList([1, 2, 3]), 1, [4, 5, 6]));
  expectUE(() => test(const [1, 2, 3], 0, [4, 5]));
  expectUE(() => test(const [1, 2, 3], -1, [4, 5]));
  expectUE(() => test(const [1, 2, 3], 1, [4, 5, 6]));
}

void expectRE(void f()) {
  Expect.throws(f, (e) => e is RangeError);
}

void expectUE(void f()) {
  Expect.throws(f, (e) => e is UnsupportedError);
}
