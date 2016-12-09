// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";

test(List list, int start, int end, Iterable iterable) {
  List copy = list.toList();
  list.replaceRange(start, end, iterable);
  List iterableList = iterable.toList();
  Expect.equals(copy.length + iterableList.length - (end - start), list.length);
  for (int i = 0; i < start; i++) {
    Expect.equals(copy[i], list[i]);
  }
  for (int i = 0; i < iterableList.length; i++) {
    Expect.equals(iterableList[i], list[i + start]);
  }
  int removedLength = end - start;
  for (int i = end; i < copy.length; i++) {
    Expect.equals(copy[i], list[i + iterableList.length - removedLength]);
  }
}

class MyList extends ListBase {
  List list;
  MyList(this.list);
  get length => list.length;
  set length(value) { list.length = value; }
  operator [](index) => list[index];
  operator []=(index, val) { list[index] = val; }
  toString() => list.toString();
}

main() {
  test([1, 2, 3], 0, 1, [4, 5]);
  test([1, 2, 3], 1, 1, [4, 5]);
  test([1, 2, 3], 2, 3, [4, 5]);
  test([1, 2, 3], 3, 3, [4, 5]);
  test([1, 2, 3], 0, 3, [4, 5]);
  test([1, 2, 3], 2, 3, [4]);
  test([1, 2, 3], 0, 3, []);
  test([1, 2, 3], 0, 1, [4, 5].map((x) => x));
  test([1, 2, 3], 1, 1, [4, 5].map((x) => x));
  test([1, 2, 3], 2, 3, [4, 5].map((x) => x));
  test([1, 2, 3], 3, 3, [4, 5].map((x) => x));
  test([1, 2, 3], 0, 3, [4, 5].map((x) => x));
  test([1, 2, 3], 2, 3, [4].map((x) => x));
  test([1, 2, 3], 0, 3, [].map((x) => x));
  test([1, 2, 3], 0, 1, const [4, 5]);
  test([1, 2, 3], 1, 1, const [4, 5]);
  test([1, 2, 3], 2, 3, const [4, 5]);
  test([1, 2, 3], 3, 3, const [4, 5]);
  test([1, 2, 3], 0, 3, const [4, 5]);
  test([1, 2, 3], 2, 3, const [4]);
  test([1, 2, 3], 0, 3, const []);
  test([1, 2, 3], 0, 1, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 1, 1, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 2, 3, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 3, 3, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 0, 3, new Iterable.generate(2, (x) => x + 4));
  test([1, 2, 3], 2, 3, new Iterable.generate(2, (x) => x + 4));
  test(new MyList([1, 2, 3]), 0, 1, [4, 5]);
  test(new MyList([1, 2, 3]), 1, 1, [4, 5]);
  test(new MyList([1, 2, 3]), 2, 3, [4, 5]);
  test(new MyList([1, 2, 3]), 3, 3, [4, 5]);
  test(new MyList([1, 2, 3]), 0, 3, [4, 5]);
  test(new MyList([1, 2, 3]), 2, 3, [4]);
  test(new MyList([1, 2, 3]), 0, 3, []);
  test(new MyList([1, 2, 3]), 0, 1, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 1, 1, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 2, 3, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 3, 3, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 0, 3, [4, 5].map((x) => x));
  test(new MyList([1, 2, 3]), 2, 3, [4].map((x) => x));
  test(new MyList([1, 2, 3]), 0, 3, [].map((x) => x));
  test(new MyList([1, 2, 3]), 0, 1, const [4, 5]);
  test(new MyList([1, 2, 3]), 1, 1, const [4, 5]);
  test(new MyList([1, 2, 3]), 2, 3, const [4, 5]);
  test(new MyList([1, 2, 3]), 3, 3, const [4, 5]);
  test(new MyList([1, 2, 3]), 0, 3, const [4, 5]);
  test(new MyList([1, 2, 3]), 2, 3, const [4]);
  test(new MyList([1, 2, 3]), 0, 3, const []);
  test(new MyList([1, 2, 3]), 0, 1, new Iterable.generate(2, (x) => x + 4));
  test(new MyList([1, 2, 3]), 1, 1, new Iterable.generate(2, (x) => x + 4));
  test(new MyList([1, 2, 3]), 2, 3, new Iterable.generate(2, (x) => x + 4));
  test(new MyList([1, 2, 3]), 3, 3, new Iterable.generate(2, (x) => x + 4));
  test(new MyList([1, 2, 3]), 0, 3, new Iterable.generate(2, (x) => x + 4));
  test(new MyList([1, 2, 3]), 2, 3, new Iterable.generate(2, (x) => x + 4));

  expectRE(() => test([1, 2, 3], -1, 0, []));
  expectRE(() => test([1, 2, 3], 2, 1, []));
  expectRE(() => test([1, 2, 3], 0, -1, []));
  expectRE(() => test([1, 2, 3], 1, 4, []));
  expectRE(() => test(new MyList([1, 2, 3]), -1, 0, []));
  expectRE(() => test(new MyList([1, 2, 3]), 2, 1, []));
  expectRE(() => test(new MyList([1, 2, 3]), 0, -1, []));
  expectRE(() => test(new MyList([1, 2, 3]), 1, 4, []));
  expectUE(() => test([1, 2, 3].toList(growable: false), 2, 3, []));
  expectUE(() => test([1, 2, 3].toList(growable: false), -1, 0, []));
  expectUE(() => test([1, 2, 3].toList(growable: false), 2, 1, []));
  expectUE(() => test([1, 2, 3].toList(growable: false), 0, -1, []));
  expectUE(() => test([1, 2, 3].toList(growable: false), 1, 4, []));
  expectUE(() => test(const [1, 2, 3], 2, 3, []));
  expectUE(() => test(const [1, 2, 3], -1, 0, []));
  expectUE(() => test(const [1, 2, 3], 2, 1, []));
  expectUE(() => test(const [1, 2, 3], 0, -1, []));
  expectUE(() => test(const [1, 2, 3], 1, 4, []));
}

void expectRE(Function f) {
  Expect.throws(f, (e) => e is RangeError);
}

void expectUE(Function f) {
  Expect.throws(f, (e) => e is UnsupportedError);
}
