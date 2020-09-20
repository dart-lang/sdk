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
  testFixedLengthList(<T>(T t) => List<T>.filled(4, t));
  testFixedLengthList(<T>(T t) => List<T>.filled(4, t).toList(growable: false));
  // ListBase implementation of List.
  testFixedLengthList(<T>(T t) => new MyFixedList(List<T>.filled(4, t)));
  testFixedLengthList(<T>(T t) =>
      new MyFixedList<T>(List<T>.filled(4, t)).toList(growable: false));

  // Growable lists. Initial length 0.
  testGrowableList(<T>(T t) => <T>[].toList());
  testGrowableList(<T>(T t) => new List<T>.filled(0, t, growable: true));
  testGrowableList(<T>(T t) => []);
  testGrowableList(<T>(T t) => new List.from(const []));
  testGrowableList(<T>(T t) => new MyList([]));
  testGrowableList(<T>(T t) => new MyList<T>([]).toList());

  testTypedGrowableList(new Uint8List(0).toList());
  testTypedGrowableList(new Int8List(0).toList());
  testTypedGrowableList(new Uint16List(0).toList());
  testTypedGrowableList(new Int16List(0).toList());
  testTypedGrowableList(new Uint32List(0).toList());
  testTypedGrowableList(new Int32List(0).toList());

  testListConstructor();

  testErrors();
}

void testErrors() {
  // Regression for issue http://dartbug.com/24295
  testIndexError(list, index, name) {
    try {
      list[list.length];
    } on RangeError catch (err, s) {
      Expect.isTrue(err is RangeError, "$name[$index]");
      Expect.equals(list.length, err.invalidValue, "$name[$index] value");
      Expect.equals(list.length - 1, err.end, "$name[$index] end");
      Expect.equals(0, err.start, "$name[$index] start");
    }
  }

  testIndex(list, name) {
    testIndexError(list, list.length, name); //   Just too big.
    testIndexError(list, -1, name); //            Negative.
    testIndexError(list, 0x123456789, name); //   > 2^32.
    testIndexError(list, -0x123456789, name); //  < -2^32.
  }

  // Slices.
  testSliceError(list, start, end, name) {
    name = "$name[$start:$end]";
    var realError;
    try {
      RangeError.checkValidRange(start, end, list.length);
    } catch (e) {
      realError = e;
    }
    var result;
    try {
      result = list.sublist(start, end);
    } on RangeError catch (actualError) {
      Expect.isNotNull(realError, "$name should not fail");
      Expect.isTrue(actualError is RangeError, "$name is-error: $actualError");
      Expect.equals(realError.name, actualError.name, "$name name");
      Expect.equals(realError.invalidValue, actualError.invalidValue,
          "$name[0:l+1] value");
      Expect.equals(realError.start, actualError.start, "$name[0:l+1] start");
      Expect.equals(realError.end, actualError.end, "$name[0:l+1] end");
      return;
    }
    // Didn't throw.
    Expect.isNull(realError, "$name should fail");
    Expect.equals(end - start, result.length, "$name result length");
  }

  testSlice(list, name) {
    testSliceError(list, 0, list.length, name); // Should not fail.
    testSliceError(list, 0, list.length + 1, name);
    testSliceError(list, 0, 0x123456789, name);
    testSliceError(list, -1, list.length, name);
    testSliceError(list, -0x123456789, list.length, name);
    testSliceError(list, list.length + 1, list.length + 1, name);
    testSliceError(list, -1, null, name);
    if (list.length > 0) {
      testSliceError(list, list.length, list.length - 1, name);
    }
  }

  testRangeErrors(list, name) {
    testIndex(list, "$name#${list.length} index");
    testSlice(list, "$name#${list.length} slice");
  }

  // Empty lists.
  testRangeErrors([], "list");
  testRangeErrors(List.filled(0, null, growable: false), "fixed-list");
  testRangeErrors(const [], "const-list");
  testRangeErrors(new List.unmodifiable([]), "unmodifiable");
  testRangeErrors(new Uint8List(0), "typed-list");
  testRangeErrors(new Uint8List.view(new Uint8List(0).buffer), "typed-list");
  testRangeErrors([1, 2, 3].sublist(1, 1), "sub-list");
  // Non-empty lists.
  testRangeErrors([1, 2, 3], "list");
  testRangeErrors(List.filled(3, null, growable: false), "fixed-list");
  testRangeErrors(const [1, 2, 3], "const-list");
  testRangeErrors(new List.unmodifiable([1, 2, 3]), "unmodifiable");
  testRangeErrors(new Uint8List(3), "typed-list");
  testRangeErrors(new Uint8List.view(new Uint8List(3).buffer), "typed-list");
  testRangeErrors([1, 2, 3, 4, 5].sublist(1, 3), "sub-list");
}

void testLength(int length, List list) {
  Expect.equals(length, list.length);
  (length == 0 ? Expect.isTrue : Expect.isFalse)(list.isEmpty);
  (length != 0 ? Expect.isTrue : Expect.isFalse)(list.isNotEmpty);
}

void testTypedLengthInvariantOperations(List<int?> list) {
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
  list.setRange(0, 4, <int>[3, 2, 1, 0]);
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
  list.setAll(0, <int>[3, 2, 0, 1]);
  Expect.listEquals([3, 2, 0, 1], list);
  list.setAll(1, <int>[0, 1]);
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
  list.setRange(0, 4, <int>[3, 2, 1, 0]);
  list.sort();
  Expect.listEquals([0, 1, 2, 3], list);
  list.setRange(0, 4, <int>[1, 2, 3, 0]);
  list.sort();
  Expect.listEquals([0, 1, 2, 3], list);
  list.setRange(0, 4, <int>[1, 3, 0, 2]);
  list.sort((a, b) => b! - a!); // reverse compare.
  Expect.listEquals([3, 2, 1, 0], list);
  list.setRange(0, 4, <int>[1, 2, 3, 0]);
  list.sort((a, b) => b! - a!);
  Expect.listEquals([3, 2, 1, 0], list);

  // Some Iterable methods.

  list.setRange(0, 4, <int>[0, 1, 2, 3]);
  // map.
  testMap(val) {
    return val * 2 + 10;
  }

  List mapped = list.map(testMap).toList();
  Expect.equals(mapped.length, list.length);
  for (var i = 0; i < list.length; i++) {
    Expect.equals(mapped[i], list[i]! * 2 + 10);
  }

  matchAll(val) => true;
  matchSome(val) {
    return (val == 1 || val == 2);
  }

  matchSomeFirst(val) {
    return val == 0;
  }

  matchSomeLast(val) {
    return val == 3;
  }

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

void testUntypedListTests(List list) {
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

void testLengthInvariantOperations(List<int?> list) {
  testTypedLengthInvariantOperations(list);

  Expect.throwsTypeError(
      () => testUntypedListTests(list), 'List<int> cannot store non-ints');

  // Argument errors on bad indices. List is still [0, 1, 2, 3].

  // Direct indices (0 <= index < length).
  Expect.throwsArgumentError(() => list[-1]);
  Expect.throwsArgumentError(() => list[4]);
  Expect.throwsArgumentError(() => list[-1] = 99);
  Expect.throwsArgumentError(() => list[4] = 99);
  Expect.throwsArgumentError(() => list.elementAt(-1));
  Expect.throwsArgumentError(() => list.elementAt(4));
  // Ranges (0 <= start <= end <= length).
  Expect.throwsArgumentError(() => list.sublist(-1, 2));
  Expect.throwsArgumentError(() => list.sublist(-1, 5));
  Expect.throwsArgumentError(() => list.sublist(2, 5));
  Expect.throwsArgumentError(() => list.sublist(4, 2));
  Expect.throwsArgumentError(() => list.getRange(-1, 2));
  Expect.throwsArgumentError(() => list.getRange(-1, 5));
  Expect.throwsArgumentError(() => list.getRange(2, 5));
  Expect.throwsArgumentError(() => list.getRange(4, 2));
  Expect.throwsArgumentError(() => list.setRange(-1, 2, <int>[1, 2, 3]));
  Expect.throwsArgumentError(() => list.setRange(-1, 5, <int>[1, 2, 3, 4, 5, 6]));
  Expect.throwsArgumentError(() => list.setRange(2, 5, <int>[1, 2, 3]));
  Expect.throwsArgumentError(() => list.setRange(4, 2, <int>[1, 2]));
  // for setAll, end is implicitly start + values.length.
  Expect.throwsArgumentError(() => list.setAll(-1, <int>[]));
  Expect.throwsArgumentError(() => list.setAll(5, <int>[]));
  Expect.throwsArgumentError(() => list.setAll(2, <int>[1, 2, 3]));
  Expect.throwsArgumentError(() => list.fillRange(-1, 2, 1));
  Expect.throwsArgumentError(() => list.fillRange(-1, 5, 1));
  Expect.throwsArgumentError(() => list.fillRange(2, 5, 1));
  Expect.throwsArgumentError(() => list.fillRange(4, 2, 1));
}

void testTypedList(List<int> list) {
  testTypedLengthInvariantOperations(list);
  testCannotChangeLength(list);
}

void testFixedLengthList(List<T> Function<T>(T t) createList) {
  testLengthInvariantOperations(createList<int>(-1));
  testCannotChangeLength(createList<int>(-1));
  testLengthInvariantOperations(createList<int?>(null));
  testCannotChangeLength(createList<int?>(null));
  testUntypedListTests(createList(null));
}

void testCannotChangeLength(List<int?> list) {
  list.setAll(0, <int>[0, 1, 2, 3]);
  Expect.throwsUnsupportedError(() => list.add(0));
  Expect.throwsUnsupportedError(() => list.addAll(<int>[0]));
  Expect.throwsUnsupportedError(() => list.removeLast());
  Expect.throwsUnsupportedError(() => list.insert(0, 1));
  Expect.throwsUnsupportedError(() => list.insertAll(0, <int>[1]));
  Expect.throwsUnsupportedError(() => list.clear());
  Expect.throwsUnsupportedError(() => list.remove(1));
  Expect.throwsUnsupportedError(() => list.removeAt(1));
  Expect.throwsUnsupportedError(() => list.removeRange(0, 1));
  Expect.throwsUnsupportedError(() => list.replaceRange(0, 1, <int>[]));
}

void testTypedGrowableList(List<int> list) {
  testLength(0, list);
  list.addAll([0, 0, 0, 0]);
  testLength(4, list);

  testTypedLengthInvariantOperations(list);

  testGrowableListOperations(list);

  list.length = 2;
  testLength(2, list);
}

void testGrowableList(List<T> Function<T>(T t) createList) {
  List<int> list = createList<int>(-1);
  testLength(0, list);
  list.addAll([0, 0, 0, 0]);
  testLength(4, list);
  testLengthInvariantOperations(list);
  testGrowableListOperations(list);

  List<int?> listNullable = createList<int?>(null);
  testLength(0, listNullable);
  listNullable.length = 4;
  testLength(4, listNullable);
  testLengthInvariantOperations(listNullable);
  testGrowableListOperations(listNullable);

  List listDynamic = createList(null);
  testLength(0, listDynamic);
  listDynamic.length = 4;
  testLength(4, listDynamic);
  testUntypedListTests(listDynamic);
}

void testGrowableListOperations(List<int?> list) {
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
  list.removeWhere((int? x) => x!.isOdd);
  testLength(50, list);
  for (int i = 0; i < list.length; i++) {
    Expect.isTrue(list[i]!.isEven);
  }
  list.retainWhere((int? x) => (x! % 3) == 0);
  testLength(17, list);
  for (int i = 0; i < list.length; i++) {
    Expect.isTrue((list[i]! % 6) == 0);
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
  list.insertAll(0, <int>[1, 2, 3]);
  Expect.listEquals([1, 2, 3, 2], list);

  list.insertAll(2, <int>[]);
  Expect.listEquals([1, 2, 3, 2], list);

  list.insertAll(4, <int>[7, 9]);
  Expect.listEquals([1, 2, 3, 2, 7, 9], list);

  // addAll
  list.addAll(list.reversed.toList());
  Expect.listEquals([1, 2, 3, 2, 7, 9, 9, 7, 2, 3, 2, 1], list);

  list.addAll(<int>[]);
  Expect.listEquals([1, 2, 3, 2, 7, 9, 9, 7, 2, 3, 2, 1], list);

  // replaceRange
  list.replaceRange(3, 7, <int>[0, 0]);
  Expect.listEquals([1, 2, 3, 0, 0, 7, 2, 3, 2, 1], list);

  list.replaceRange(2, 3, <int>[5, 5, 5]);
  Expect.listEquals([1, 2, 5, 5, 5, 0, 0, 7, 2, 3, 2, 1], list);

  list.replaceRange(2, 4, <int>[6, 6]);
  Expect.listEquals([1, 2, 6, 6, 5, 0, 0, 7, 2, 3, 2, 1], list);

  list.replaceRange(6, 8, <int>[]);
  Expect.listEquals([1, 2, 6, 6, 5, 0, 2, 3, 2, 1], list);

  // Any operation that doesn't change the length should be safe for iteration.
  testSafeConcurrentModification(action()) {
    list.length = 4;
    list.setAll(0, <int>[0, 1, 2, 3]);
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
  list.setAll(0, <int>[0, 1, 2, 3]);

  // Direct indices (0 <= index < length).
  Expect.throwsArgumentError(() => list.removeAt(-1));
  Expect.throwsArgumentError(() => list.removeAt(4));
  // Direct indices including end (0 <= index <= length).
  Expect.throwsArgumentError(() => list.insert(-1, 0));
  Expect.throwsArgumentError(() => list.insert(5, 0));
  Expect.throwsArgumentError(() => list.insertAll(-1, <int>[0]));
  Expect.throwsArgumentError(() => list.insertAll(5, <int>[0]));
  Expect.throwsArgumentError(() => list.insertAll(-1, <int>[0]));
  Expect.throwsArgumentError(() => list.insertAll(5, <int>[0]));
  // Ranges (0 <= start <= end <= length).
  Expect.throwsArgumentError(() => list.removeRange(-1, 2));
  Expect.throwsArgumentError(() => list.removeRange(2, 5));
  Expect.throwsArgumentError(() => list.removeRange(-1, 5));
  Expect.throwsArgumentError(() => list.removeRange(4, 2));
  Expect.throwsArgumentError(() => list.replaceRange(-1, 2, <int>[9]));
  Expect.throwsArgumentError(() => list.replaceRange(2, 5, <int>[9]));
  Expect.throwsArgumentError(() => list.replaceRange(-1, 5, <int>[9]));
  Expect.throwsArgumentError(() => list.replaceRange(4, 2, <int>[9]));
}

class Yes {
  operator ==(var other) => true;
  int get hashCode => 0;
}

class MyList<E> extends ListBase<E> {
  // TODO(42496): Use a nullable list because insert() is implemented in terms
  // of length=. Change this back to `E` and remove the `as E` below when that
  // issue is fixed.
  List<E?> _source;
  MyList(this._source);
  int get length => _source.length;
  void set length(int length) {
    _source.length = length;
  }

  void add(E element) {
    _source.add(element);
  }

  E operator [](int index) => _source[index] as E;
  void operator []=(int index, E value) {
    _source[index] = value;
  }
}

class MyFixedList<E> extends ListBase<E> {
  List<E> _source;
  MyFixedList(this._source);
  int get length => _source.length;
  void set length(int length) {
    throw new UnsupportedError("Fixed length!");
  }

  E operator [](int index) => _source[index];
  void operator []=(int index, E value) {
    _source[index] = value;
  }
}

void testListConstructor() {
  // Is fixed-length.
  Expect.throws(() => new List<int?>.filled(0, null).add(4));
  Expect.throws(() => new List.filled(-2, null)); // Not negative. //# 01: ok
  // Not null.
  Expect.listEquals([4], <int>[]..add(4));
  // Is fixed-length.
  Expect.throws(() => new List.filled(0, 42).add(4));
  // Not negative.
  Expect.throws(() => new List.filled(-2, 42));
}
