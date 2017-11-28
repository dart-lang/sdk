// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

@AssumeDynamic()
@NoInline()
confuse(x) => x;

void testListFunctions<T extends num>(
    List<T> list, first, last, T toElementType(dynamic x)) {
  assert(list.length > 0);

  var reversed = list.reversed;
  Expect.listEquals(list, reversed.toList().reversed.toList());
  int index = list.length - 1;
  for (var x in reversed) {
    Expect.equals(list[index], x);
    index--;
  }

  var zero = toElementType(0);
  var one = toElementType(1);
  var two = toElementType(2);
  // Typed lists are fixed length.
  Expect.throwsUnsupportedError(() => list.add(zero));
  Expect.throwsUnsupportedError(() => list.addAll([one, two]));
  Expect.throwsUnsupportedError(() => list.clear());
  Expect.throwsUnsupportedError(() => list.insert(0, zero));
  Expect.throwsUnsupportedError(() => list.insertAll(0, [one, two]));
  Expect.throwsUnsupportedError(() => list.remove(zero));
  Expect.throwsUnsupportedError(() => list.removeAt(0));
  Expect.throwsUnsupportedError(() => list.removeLast());
  Expect.throwsUnsupportedError(() => list.removeRange(0, 1));
  Expect.throwsUnsupportedError(() => list.removeWhere((x) => true));
  Expect.throwsUnsupportedError(() => list.replaceRange(0, 1, []));
  Expect.throwsUnsupportedError(() => list.retainWhere((x) => true));

  var map = list.asMap();
  Expect.equals(list.length, map.length);
  Expect.isTrue(map is Map);
  Expect.listEquals(list, map.values.toList());
  for (int i = 0; i < list.length; i++) {
    Expect.equals(list[i], map[i]);
  }

  Expect.listEquals(list, list.getRange(0, list.length).toList());
  var subRange = list.getRange(1, list.length - 1).toList();
  Expect.equals(list.length - 2, subRange.length);
  index = 1;
  for (var x in subRange) {
    Expect.equals(list[index], x);
    index++;
  }

  Expect.equals(0, list.lastIndexOf(first));
  Expect.equals(list.length - 1, list.lastIndexOf(last));
  if (list is List<int>) {
    Expect.equals(-1, list.lastIndexOf(-1 as T));
  } else {
    Expect.equals(-1, list.lastIndexOf(-1.0 as T));
  }

  var copy = list.toList();
  list.fillRange(1, list.length - 1, toElementType(0));
  Expect.equals(copy.first, list.first);
  Expect.equals(copy.last, list.last);
  for (int i = 1; i < list.length - 1; i++) {
    Expect.equals(0, list[i]);
  }

  list.setAll(
      1, list.getRange(1, list.length - 1).map((x) => toElementType(2)));
  Expect.equals(copy.first, list.first);
  Expect.equals(copy.last, list.last);
  for (int i = 1; i < list.length - 1; i++) {
    Expect.equals(2, list[i]);
  }

  list.setRange(1, list.length - 1,
      new Iterable.generate(list.length - 2, (x) => toElementType(x + 5)));
  Expect.equals(first, list.first);
  Expect.equals(last, list.last);
  for (int i = 1; i < list.length - 1; i++) {
    Expect.equals(4 + i, list[i]);
  }
  list.setRange(1, list.length - 1,
      new Iterable.generate(list.length - 1, (x) => toElementType(x + 5)), 1);
  Expect.equals(first, list.first);
  Expect.equals(last, list.last);
  for (int i = 1; i < list.length - 1; i++) {
    Expect.equals(5 + i, list[i]);
  }

  Expect.throwsStateError(() => list.setRange(1, list.length - 1, []));

  for (int i = 0; i < list.length; i++) {
    list[list.length - 1 - i] = toElementType(i);
  }
  list.sort();
  for (int i = 0; i < list.length; i++) {
    Expect.equals(i, list[i]);
  }

  Expect.listEquals(list.getRange(1, list.length - 1).toList(),
      list.sublist(1, list.length - 1));
  Expect.listEquals(list.getRange(1, list.length).toList(), list.sublist(1));
  Expect.listEquals(list, list.sublist(0));

  Expect.listEquals([], list.sublist(0, 0));
  Expect.listEquals([], list.sublist(list.length));
  Expect.listEquals([], list.sublist(list.length, list.length));

  Expect.throwsRangeError(() => list.sublist(list.length + 1));
  Expect.throwsRangeError(() => list.sublist(0, list.length + 1));
  Expect.throwsRangeError(() => list.sublist(1, 0));
}

void emptyChecks<T>(List<T> list, T toElementType(dynamic c)) {
  assert(list.length == 0);

  Expect.isTrue(list.isEmpty);

  var reversed = list.reversed;
  Expect.listEquals(list, reversed.toList().reversed.toList());

  var zero = toElementType(0);
  var one = toElementType(1);
  var two = toElementType(2);
  // Typed lists are fixed length. Even when they are empty.
  Expect.throwsUnsupportedError(() => list.add(zero));
  Expect.throwsUnsupportedError(() => list.addAll([one, two]));
  Expect.throwsUnsupportedError(() => list.clear());
  Expect.throwsUnsupportedError(() => list.insert(0, zero));
  Expect.throwsUnsupportedError(() => list.insertAll(0, [one, two]));
  Expect.throwsUnsupportedError(() => list.remove(zero));
  Expect.throwsUnsupportedError(() => list.removeAt(0));
  Expect.throwsUnsupportedError(() => list.removeLast());
  Expect.throwsUnsupportedError(() => list.removeRange(0, 1));
  Expect.throwsUnsupportedError(() => list.removeWhere((x) => true));
  Expect.throwsUnsupportedError(() => list.replaceRange(0, 1, []));
  Expect.throwsUnsupportedError(() => list.retainWhere((x) => true));

  var map = list.asMap();
  Expect.equals(list.length, map.length);
  Expect.isTrue(map is Map);
  Expect.listEquals(list, map.values.toList());
  for (int i = 0; i < list.length; i++) {
    Expect.equals(list[i], map[i]);
  }

  Expect.listEquals(list, list.getRange(0, list.length).toList());

  var copy = list.toList();
  // Make sure we are allowed to call range-functions if they are 0..0.
  list.fillRange(0, 0);
  Expect.listEquals([], list.getRange(0, 0).toList());

  final minusOne = toElementType(-1);
  Expect.equals(-1, list.lastIndexOf(minusOne));
  list.setRange(0, 0, [one, two]);

  list.sort();

  Expect.listEquals([], list.sublist(0, 0));
}

main() {
  double toDouble(x) => x.toDouble();
  int toInt(x) => x.toInt();

  testListFunctions(
      new Float32List.fromList([1.5, 6.3, 9.5]), 1.5, 9.5, toDouble);
  testListFunctions(
      new Float64List.fromList([1.5, 6.3, 9.5]), 1.5, 9.5, toDouble);
  testListFunctions(new Int8List.fromList([3, 5, 9]), 3, 9, toInt);
  testListFunctions(new Int16List.fromList([3, 5, 9]), 3, 9, toInt);
  testListFunctions(new Int32List.fromList([3, 5, 9]), 3, 9, toInt);
  testListFunctions(new Uint8List.fromList([3, 5, 9]), 3, 9, toInt);
  testListFunctions(new Uint16List.fromList([3, 5, 9]), 3, 9, toInt);
  testListFunctions(new Uint32List.fromList([3, 5, 9]), 3, 9, toInt);

  emptyChecks(new Float32List(0), toDouble);
  emptyChecks(new Float64List(0), toDouble);
  emptyChecks(new Int8List(0), toInt);
  emptyChecks(new Int16List(0), toInt);
  emptyChecks(new Int32List(0), toInt);
  emptyChecks(new Uint8List(0), toInt);
  emptyChecks(new Uint16List(0), toInt);
  emptyChecks(new Uint32List(0), toInt);
}
