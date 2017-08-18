// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";

test(List list, int start, int end, [fillValue]) {
  List copy = list.toList();
  list.fillRange(start, end, fillValue);
  Expect.equals(copy.length, list.length);
  for (int i = 0; i < start; i++) {
    Expect.equals(copy[i], list[i]);
  }
  for (int i = start; i < end; i++) {
    Expect.equals(fillValue, list[i]);
  }
  for (int i = end; i < list.length; i++) {
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
  test([1, 2, 3], 0, 1);
  test([1, 2, 3], 0, 1, 99);
  test([1, 2, 3], 1, 1);
  test([1, 2, 3], 1, 1, 499);
  test([1, 2, 3], 3, 3);
  test([1, 2, 3], 3, 3, 499);
  test([1, 2, 3].toList(growable: false), 0, 1);
  test([1, 2, 3].toList(growable: false), 0, 1, 99);
  test([1, 2, 3].toList(growable: false), 1, 1);
  test([1, 2, 3].toList(growable: false), 1, 1, 499);
  test([1, 2, 3].toList(growable: false), 3, 3);
  test([1, 2, 3].toList(growable: false), 3, 3, 499);
  test(new MyList([1, 2, 3]), 0, 1);
  test(new MyList([1, 2, 3]), 0, 1, 99);
  test(new MyList([1, 2, 3]), 1, 1);
  test(new MyList([1, 2, 3]), 1, 1, 499);
  test(new MyList([1, 2, 3]), 3, 3);
  test(new MyList([1, 2, 3]), 3, 3, 499);

  expectRE(() => test([1, 2, 3], -1, 0));
  expectRE(() => test([1, 2, 3], 2, 1));
  expectRE(() => test([1, 2, 3], 0, -1));
  expectRE(() => test([1, 2, 3], 1, 4));
  expectRE(() => test(new MyList([1, 2, 3]), -1, 0));
  expectRE(() => test(new MyList([1, 2, 3]), 2, 1));
  expectRE(() => test(new MyList([1, 2, 3]), 0, -1));
  expectRE(() => test(new MyList([1, 2, 3]), 1, 4));
  expectUE(() => test(const [1, 2, 3], 2, 3));
  expectUE(() => test(const [1, 2, 3], -1, 0));
  expectUE(() => test(const [1, 2, 3], 2, 1));
  expectUE(() => test(const [1, 2, 3], 0, -1));
  expectUE(() => test(const [1, 2, 3], 1, 4));
}

void expectRE(void f()) {
  Expect.throws(f, (e) => e is RangeError);
}

void expectUE(void f()) {
  Expect.throws(f, (e) => e is UnsupportedError);
}
