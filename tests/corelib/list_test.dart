// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:typeddata";
import "package:expect/expect.dart";

void main() {
  // Fixed length lists, length 4.
  testFixedLengthList(new List(4));
  testFixedLengthList(new List(4).toList(growable: false));
  testFixedLengthList((new List()..length = 4).toList(growable: false));
  // ListBase implementation of List.
  testFixedLengthList(new MyFixedList(new List(4)));
  testFixedLengthList(new MyFixedList(new List(4)).toList(growable: false));


  testTypedList(new Uint8List(4));
  testTypedList(new Int8List(4));
  testTypedList(new Uint16List(4));
  testTypedList(new Int16List(4));
  testTypedList(new Uint32List(4));
  testTypedList(new Int32List(4));

  // Growable lists. Initial length 0.
  testGrowableList(new List());
  testGrowableList(new List().toList());
  testGrowableList(new List(0).toList());
  testGrowableList([]);
  testGrowableList((const []).toList());
  testGrowableList(new MyList([]));
  testGrowableList(new MyList([]).toList());
}

void testLength(int length, List list) {
  Expect.equals(length, list.length);
  (length == 0 ? Expect.isTrue : Expect.isFalse)(list.isEmpty);
}

void testTypedLengthInvariantOperations(List list) {
  // length
  Expect.equals(list.length, 4);
  // operators [], []=.
  for (int i = 0; i < 4; i++) list[i] = 0;
  list[0] = 4;
  Expect.listEquals([4, 0, 0, 0], list);
  list[1] = 7;
  Expect.listEquals([4, 7, 0, 0], list);
  list[3] = 2;
  Expect.listEquals([4, 7, 0, 2], list);

  for (int i = 0; i < list.length; i++) {
    list[i] = i;
  }

  // indexOf, lastIndexOf
  for (int i = 0; i < 4; i++) {
    Expect.equals(i, list[i]);
    Expect.equals(i, list.indexOf(i));
    Expect.equals(i, list.lastIndexOf(i));
  }

  // setRange.
  list.setRange(0, 4, [3, 2, 1, 0]);
  Expect.listEquals([3, 2, 1, 0], list);

  list.setRange(1, 4, list);
  Expect.listEquals([3, 3, 2, 1], list);

  list.setRange(0, 3, list, 1);
  Expect.listEquals([3, 2, 1, 1], list);
  list.setRange(0, 3, list, 1);
  Expect.listEquals([2, 1, 1, 1], list);

  list.setRange(2, 4, list, 0);
  Expect.listEquals([2, 1, 2, 1], list);

  // setAll.
  list.setAll(0, [3, 2, 0, 1]);
  Expect.listEquals([3, 2, 0, 1], list);
  list.setAll(1, [0, 1]);
  Expect.listEquals([3, 0, 1, 1], list);

  // sort.
  list.setRange(0, 4, [3, 2, 1, 0]);
  list.sort();
  Expect.listEquals([0, 1, 2, 3], list);
  list.setRange(0, 4, [1, 2, 3, 0]);
  list.sort();
  Expect.listEquals([0, 1, 2, 3], list);
  list.setRange(0, 4, [1, 3, 0, 2]);
  list.sort((a, b) => b - a);  // reverse compare.
  Expect.listEquals([3, 2, 1, 0], list);
  list.setRange(0, 4, [1, 2, 3, 0]);
  list.sort((a, b) => b - a);
  Expect.listEquals([3, 2, 1, 0], list);

  // Some Iterable methods.

  list.setRange(0, 4, [0, 1, 2, 3]);
  // map.
  testMap(val) {return val * 2 + 10; }
  List mapped = list.map(testMap).toList();
  Expect.equals(mapped.length, list.length);
  for (var i = 0; i < list.length; i++) {
    Expect.equals(mapped[i], list[i] * 2 + 10);
  }

  matchAll(val) => true;
  matchSome(val) { return (val == 1 || val == 2); }
  matchSomeFirst(val) { return val == 0; }
  matchSomeLast(val) { return val == 3; }
  matchNone(val) => false;

  // where.
  Iterable filtered = list.where(matchSome);
  Expect.equals(filtered.length, 2);

  // every
  Expect.isTrue(list.every(matchAll));
  Expect.isFalse(list.every(matchSome));
  Expect.isFalse(list.every(matchNone));

  // any
  Expect.isTrue(list.any(matchAll));
  Expect.isTrue(list.any(matchSome));
  Expect.isTrue(list.any(matchSomeFirst));
  Expect.isTrue(list.any(matchSomeLast));
  Expect.isFalse(list.any(matchNone));
}

void testLengthInvariantOperations(List list) {
  testTypedLengthInvariantOperations(list);
  // Tests that need untyped lists.
  list.setAll(0, [0, 1, 2, 3]);
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

}

void testTypedList(List list) {
  testTypedLengthInvariantOperations(list);
  testCannotChangeLength(list);
}

void testFixedLengthList(List list) {
  testLengthInvariantOperations(list);
  testCannotChangeLength(list);
}

void testCannotChangeLength(List list) {
  isUnsupported(action()) {
    Expect.throws(action, (e) => e is UnsupportedError);
  }
  isUnsupported(() => list.add(0));
  isUnsupported(() => list.addAll([0]));
  isUnsupported(() => list.removeLast());
  isUnsupported(() => list.insert(0, 1));
  isUnsupported(() => list.insertAll(0, [1]));
  isUnsupported(() => list.clear());
  isUnsupported(() => list.remove(1));
  isUnsupported(() => list.removeAt(1));
  isUnsupported(() => list.removeRange(0, 1));
  isUnsupported(() => list.replaceRange(0, 1, []));
}

void testGrowableList(List list) {
  testLength(0, list);
  // set length.
  list.length = 4;
  testLength(4, list);

  testLengthInvariantOperations(list);

  // add, removeLast.
  list.clear();
  testLength(0, list);
  list.add(4);
  testLength(1, list);
  Expect.equals(4, list.removeLast());
  testLength(0, list);

  for (int i = 0; i < 100; i++) {
    list.add(i);
  }

  Expect.equals(list.length, 100);
  for (int i = 0; i < 100; i++) {
    Expect.equals(i, list[i]);
  }

  Expect.equals(17, list.indexOf(17));
  Expect.equals(17, list.lastIndexOf(17));
  Expect.equals(-1, list.indexOf(999));
  Expect.equals(-1, list.lastIndexOf(999));

  Expect.equals(99, list.removeLast());
  testLength(99, list);

  // remove.
  Expect.isTrue(list.remove(4));
  testLength(98, list);
  Expect.isFalse(list.remove(4));
  testLength(98, list);
  list.clear();
  testLength(0, list);

  list.add(4);
  list.add(4);
  testLength(2, list);
  Expect.isTrue(list.remove(4));
  testLength(1, list);
  Expect.isTrue(list.remove(4));
  testLength(0, list);
  Expect.isFalse(list.remove(4));
  testLength(0, list);

  // removeWhere, retainWhere
  for (int i = 0; i < 100; i++) {
    list.add(i);
  }
  testLength(100, list);
  list.removeWhere((int x) => x.isOdd);
  testLength(50, list);
  for (int i = 0; i < list.length; i++) {
    Expect.isTrue(list[i].isEven);
  }
  list.retainWhere((int x) => (x % 3) == 0);
  testLength(17, list);
  for (int i = 0; i < list.length; i++) {
    Expect.isTrue((list[i] % 6) == 0);
  }

  // insert, remove, removeAt
  list.clear();
  testLength(0, list);

  list.insert(0, 0);
  Expect.listEquals([0], list);

  list.insert(0, 1);
  Expect.listEquals([1, 0], list);

  list.insert(0, 2);
  Expect.listEquals([2, 1, 0], list);

  Expect.isTrue(list.remove(1));
  Expect.listEquals([2, 0], list);

  list.insert(1, 1);
  Expect.listEquals([2, 1, 0], list);

  list.removeAt(1);
  Expect.listEquals([2, 0], list);

  list.removeAt(1);
  Expect.listEquals([2], list);

  // insertAll
  list.insertAll(0, [1, 2, 3]);
  Expect.listEquals([1, 2, 3, 2], list);

  list.insertAll(2, []);
  Expect.listEquals([1, 2, 3, 2], list);

  list.insertAll(4, [7, 9]);
  Expect.listEquals([1, 2, 3, 2, 7, 9], list);

  // addAll
  list.addAll(list.reversed.toList());
  Expect.listEquals([1, 2, 3, 2, 7, 9, 9, 7, 2, 3, 2, 1], list);

  list.addAll([]);
  Expect.listEquals([1, 2, 3, 2, 7, 9, 9, 7, 2, 3, 2, 1], list);

  // replaceRange
  list.replaceRange(3, 7, [0, 0]);
  Expect.listEquals([1, 2, 3, 0, 0, 7, 2, 3, 2, 1], list);

  list.replaceRange(2, 3, [5, 5, 5]);
  Expect.listEquals([1, 2, 5, 5, 5, 0, 0, 7, 2, 3, 2, 1], list);

  list.replaceRange(2, 4, [6, 6]);
  Expect.listEquals([1, 2, 6, 6, 5, 0, 0, 7, 2, 3, 2, 1], list);

  list.replaceRange(6, 8, []);
  Expect.listEquals([1, 2, 6, 6, 5, 0, 2, 3, 2, 1], list);
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
