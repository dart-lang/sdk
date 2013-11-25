// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:typed_data";
import "package:expect/expect.dart";

void main() {
  // Typed lists - fixed length and can only contain integers.
  testTypedList(new Uint8List(4));
  testTypedList(new Int8List(4));
  testTypedList(new Uint16List(4));
  testTypedList(new Int16List(4));
  testTypedList(new Uint32List(4));
  testTypedList(new Int32List(4));
  testTypedList(new Uint8List(4).toList(growable: false));
  testTypedList(new Int8List(4).toList(growable: false));
  testTypedList(new Uint16List(4).toList(growable: false));
  testTypedList(new Int16List(4).toList(growable: false));
  testTypedList(new Uint32List(4).toList(growable: false));
  testTypedList(new Int32List(4).toList(growable: false));

  // Fixed length lists, length 4.
  testFixedLengthList(new List(4));
  testFixedLengthList(new List(4).toList(growable: false));
  testFixedLengthList((new List()..length = 4).toList(growable: false));
  // ListBase implementation of List.
  testFixedLengthList(new MyFixedList(new List(4)));
  testFixedLengthList(new MyFixedList(new List(4)).toList(growable: false));

  // Growable lists. Initial length 0.
  testGrowableList(new List());
  testGrowableList(new List().toList());
  testGrowableList(new List(0).toList());
  testGrowableList([]);
  testGrowableList((const []).toList());
  testGrowableList(new MyList([]));
  testGrowableList(new MyList([]).toList());

  testTypedGrowableList(new Uint8List(0).toList());
  testTypedGrowableList(new Int8List(0).toList());
  testTypedGrowableList(new Uint16List(0).toList());
  testTypedGrowableList(new Int16List(0).toList());
  testTypedGrowableList(new Uint32List(0).toList());
  testTypedGrowableList(new Int32List(0).toList());

  testListConstructor();
}

void testLength(int length, List list) {
  Expect.equals(length, list.length);
  (length == 0 ? Expect.isTrue : Expect.isFalse)(list.isEmpty);
  (length != 0 ? Expect.isTrue : Expect.isFalse)(list.isNotEmpty);
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

  // fillRange.
  list.fillRange(1, 3, 7);
  Expect.listEquals([3, 7, 7, 1], list);
  list.fillRange(0, 0, 9);
  Expect.listEquals([3, 7, 7, 1], list);
  list.fillRange(4, 4, 9);
  Expect.listEquals([3, 7, 7, 1], list);
  list.fillRange(0, 4, 9);
  Expect.listEquals([9, 9, 9, 9], list);

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

  // Argument checking isn't implemented for typed arrays in browsers,
  // so it's moved to the method below for now.
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

  // Argument errors on bad indices. List is still [0, 1, 2, 3].
  testArgumentError(action()) {
    Expect.throws(action, (e) => e is ArgumentError);
  }

  // Direct indices (0 <= index < length).
  testArgumentError(() => list[-1]);
  testArgumentError(() => list[4]);
  testArgumentError(() => list[-1] = 99);
  testArgumentError(() => list[4] = 99);
  testArgumentError(() => list.elementAt(-1));
  testArgumentError(() => list.elementAt(4));
  // Ranges (0 <= start <= end <= length).
  testArgumentError(() => list.sublist(-1, 2));
  testArgumentError(() => list.sublist(-1, 5));
  testArgumentError(() => list.sublist(2, 5));
  testArgumentError(() => list.sublist(4, 2));
  testArgumentError(() => list.getRange(-1, 2));
  testArgumentError(() => list.getRange(-1, 5));
  testArgumentError(() => list.getRange(2, 5));
  testArgumentError(() => list.getRange(4, 2));
  testArgumentError(() => list.setRange(-1, 2, [1, 2, 3]));
  testArgumentError(() => list.setRange(-1, 5, [1, 2, 3, 4, 5, 6]));
  testArgumentError(() => list.setRange(2, 5, [1, 2, 3]));
  testArgumentError(() => list.setRange(4, 2, [1, 2]));
  // for setAll, end is implictly start + values.length.
  testArgumentError(() => list.setAll(-1, []));
  testArgumentError(() => list.setAll(5, []));
  testArgumentError(() => list.setAll(2, [1, 2, 3]));
  testArgumentError(() => list.fillRange(-1, 2));
  testArgumentError(() => list.fillRange(-1, 5));
  testArgumentError(() => list.fillRange(2, 5));
  testArgumentError(() => list.fillRange(4, 2));
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

void testTypedGrowableList(List list) {
  testLength(0, list);
  // set length.
  list.length = 4;
  testLength(4, list);

  testTypedLengthInvariantOperations(list);

  testGrowableListOperations(list);
}

void testGrowableList(List list) {
  testLength(0, list);
  // set length.
  list.length = 4;
  testLength(4, list);

  testLengthInvariantOperations(list);

  testGrowableListOperations(list);
}

void testGrowableListOperations(List list) {
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

  // Operations that change the length cause ConcurrentModificationError.
  void testConcurrentModification(action()) {
    testIterator(int when) {
      list.length = 4;
      list.setAll(0, [0, 1, 2, 3]);
      Expect.throws(() {
        for (var element in list) {
          if (element == when) action();
        }
      }, (e) => e is ConcurrentModificationError);
    }
    testForEach(int when) {
      list.length = 4;
      list.setAll(0, [0, 1, 2, 3]);
      Expect.throws(() {
        list.forEach((var element) {
          if (element == when) action();
        });
      }, (e) => e is ConcurrentModificationError);
    }
    // Test the change at different points of the iteration.
    testIterator(0);
    testIterator(1);
    testIterator(3);
    testForEach(0);
    testForEach(1);
    testForEach(3);
  }

  testConcurrentModification(() => list.add(5));
  testConcurrentModification(() => list.addAll([5, 6]));
  testConcurrentModification(() => list.removeLast());
  for (int i = 0; i < 4; i++) {
    testConcurrentModification(() => list.remove(i));
    testConcurrentModification(() => list.removeAt(i));
    testConcurrentModification(() => list.removeWhere((x) => x == i));
    testConcurrentModification(() => list.retainWhere((x) => x != i));
    testConcurrentModification(() => list.insert(i, 5));
    testConcurrentModification(() => list.insertAll(i, [5, 6]));
    testConcurrentModification(() => list.removeRange(i, i + 1));
    testConcurrentModification(() => list.replaceRange(i, i + 1, [5, 6]));
  }

  // Any operation that doesn't change the length should be safe for iteration.
  testSafeConcurrentModification(action()) {
    list.length = 4;
    list.setAll(0, [0, 1, 2, 3]);
    for (var i in list) {
      action();
    }
    list.forEach((e) => action());
  }

  testSafeConcurrentModification(() {
    list.add(5);
    list.removeLast();
  });
  testSafeConcurrentModification(() {
    list.add(list[0]);
    list.removeAt(0);
  });
  testSafeConcurrentModification(() {
    list.insert(0, list.removeLast());
  });
  testSafeConcurrentModification(() {
    list.replaceRange(1, 3, list.sublist(1, 3).reversed);
  });

  // Argument errors on bad indices for methods that are only allowed
  // on growable lists.
  list.length = 4;
  list.setAll(0, [0, 1, 2, 3]);
  testArgumentError(action()) {
    Expect.throws(action, (e) => e is ArgumentError);
  }

  // Direct indices (0 <= index < length).
  testArgumentError(() => list.removeAt(-1));
  testArgumentError(() => list.removeAt(4));
  // Direct indices including end (0 <= index <= length).
  testArgumentError(() => list.insert(-1, 0));
  testArgumentError(() => list.insert(5, 0));
  testArgumentError(() => list.insertAll(-1, [0]));
  testArgumentError(() => list.insertAll(5, [0]));
  testArgumentError(() => list.insertAll(-1, [0]));
  testArgumentError(() => list.insertAll(5, [0]));
  // Ranges (0 <= start <= end <= length).
  testArgumentError(() => list.removeRange(-1, 2));
  testArgumentError(() => list.removeRange(2, 5));
  testArgumentError(() => list.removeRange(-1, 5));
  testArgumentError(() => list.removeRange(4, 2));
  testArgumentError(() => list.replaceRange(-1, 2, [9]));
  testArgumentError(() => list.replaceRange(2, 5, [9]));
  testArgumentError(() => list.replaceRange(-1, 5, [9]));
  testArgumentError(() => list.replaceRange(4, 2, [9]));
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

void testListConstructor() {
  Expect.throws(() { new List(0).add(4); });  // Is fixed-length.
  Expect.throws(() { new List(-2); });  // Not negative. /// 01: ok
  Expect.throws(() { new List(null); });  // Not null.
  Expect.listEquals([4], new List()..add(4));
  Expect.throws(() { new List.filled(0, 42).add(4); });  // Is fixed-length.
  Expect.throws(() { new List.filled(-2, 42); });  // Not negative.
  Expect.throws(() { new List.filled(null, 42); });  // Not null.
}
