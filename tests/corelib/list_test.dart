// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";

void main() {
  testFixedLengthList(new List(4));
  // ListBase implementation of List.
  testFixedLengthList(new MyFixedList(new List(4)));

  testGrowableList(new List());
  testGrowableList([]);
  testGrowableList(new MyList([]));
}

void expectValues(list, val1, val2, val3, val4) {
  Expect.isFalse(list.isEmpty);
  Expect.equals(4, list.length);
  Expect.equals(list[0], val1);
  Expect.equals(list[1], val2);
  Expect.equals(list[2], val3);
  Expect.equals(list[3], val4);
}

void testClosures(List list) {
  testMap(val) {return val * 2 + 10; }
  List mapped = list.map(testMap).toList();
  Expect.equals(mapped.length, list.length);
  for (var i = 0; i < list.length; i++) {
    Expect.equals(mapped[i], list[i]*2 + 10);
  }

  testFilter(val) { return val == 3; }
  Iterable filtered = list.where(testFilter);
  Expect.equals(filtered.length, 1);

  testEvery(val) { return val != 11; }
  bool test = list.every(testEvery);
  Expect.isTrue(test);

  testSome(val) { return val == 1; }
  test = list.any(testSome);
  Expect.isTrue(test);

  testSomeFirst(val) { return val == 0; }
  test = list.any(testSomeFirst);
  Expect.isTrue(test);

  testSomeLast(val) { return val == (list.length - 1); }
  test = list.any(testSomeLast);
  Expect.isTrue(test);
}

void testFixedLengthList(List list) {
  Expect.equals(list.length, 4);
  list[0] = 4;
  expectValues(list, 4, null, null, null);
  String val = "fisk";
  list[1] = val;
  expectValues(list, 4, val, null, null);
  double d = 2.0;
  list[3] = d;
  expectValues(list, 4, val, null, d);

  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }

  for (int i = 0; i < 4; i++) {
    Expect.equals(i, list[i]);
    Expect.equals(i, list.indexOf(i));
    Expect.equals(i, list.lastIndexOf(i));
  }

  Expect.equals(-1, list.indexOf(100));
  Expect.equals(-1, list.lastIndexOf(100));
  list[2] = new Yes();
  Expect.equals(2, list.indexOf(100));
  Expect.equals(2, list.lastIndexOf(100));
  list[3] = new Yes();
  Expect.equals(2, list.indexOf(100));
  Expect.equals(3, list.lastIndexOf(100));
  list[2] = 2;
  Expect.equals(3, list.indexOf(100));
  Expect.equals(3, list.lastIndexOf(100));
  list[3] = 3;
  Expect.equals(-1, list.indexOf(100));
  Expect.equals(-1, list.lastIndexOf(100));

  testClosures(list);

  Expect.throws(list.clear, (e) => e is UnsupportedError);
}

void testGrowableList(List list) {
  Expect.isTrue(list.isEmpty);
  Expect.equals(list.length, 0);
  list.add(4);
  Expect.equals(1, list.length);
  Expect.isTrue(!list.isEmpty);
  Expect.equals(list.length, 1);
  Expect.equals(list.length, 1);
  Expect.equals(list.removeLast(), 4);

  for (int i = 0; i < 10; i++) {
    list.add(i);
  }

  Expect.equals(list.length, 10);
  for (int i = 0; i < 10; i++) {
    Expect.equals(i, list[i]);
    Expect.equals(i, list.indexOf(i));
    Expect.equals(i, list.lastIndexOf(i));
  }

  Expect.equals(-1, list.indexOf(100));
  Expect.equals(-1, list.lastIndexOf(100));
  list[2] = new Yes();
  Expect.equals(2, list.indexOf(100));
  Expect.equals(2, list.lastIndexOf(100));
  list[3] = new Yes();
  Expect.equals(2, list.indexOf(100));
  Expect.equals(3, list.lastIndexOf(100));
  list[2] = 2;
  Expect.equals(3, list.indexOf(100));
  Expect.equals(3, list.lastIndexOf(100));
  list[3] = 3;
  Expect.equals(-1, list.indexOf(100));
  Expect.equals(-1, list.lastIndexOf(100));

  testClosures(list);

  Expect.equals(9, list.removeLast());
  list.clear();
  Expect.equals(0, list.length);
  Expect.isTrue(list.isEmpty);
}

class Yes {
  operator ==(var other) => true;
}

class MyList<E> extends ListBase<E> {
  List<E> _source;
  MyList(this._source);
  int get length => _source.length;
  void set length(int length) { _source.length = length; }
  E operator[](int index) => _source[index];
  void operator[]=(int index, E value) { _source[index] = value; }
}

class MyFixedList<E> extends ListBase<E> {
  List<E> _source;
  MyFixedList(this._source);
  int get length => _source.length;
  void set length(int length) { throw new UnsupportedError("Fixed length!"); }
  E operator[](int index) => _source[index];
  void operator[]=(int index, E value) { _source[index] = value; }
}
