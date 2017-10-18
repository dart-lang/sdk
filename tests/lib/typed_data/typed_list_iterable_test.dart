// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

void testIterableFunctions(list, first, last, toElementType) {
  assert(list.length > 0);

  Expect.equals(first, list.first);
  Expect.equals(last, list.last);
  Expect.equals(first, list.firstWhere((x) => x == first));
  Expect.equals(last, list.lastWhere((x) => x == last));
  if (list.length == 1) {
    Expect.equals(first, list.single);
    Expect.equals(first, list.singleWhere((x) => x == last));
  } else {
    Expect.throws(() => list.single, (e) => e is StateError);
    bool isFirst = true;
    Expect.equals(first, list.singleWhere((x) {
      if (isFirst) {
        isFirst = false;
        return true;
      }
      return false;
    }));
  }
  Expect.isFalse(list.isEmpty);

  int i = 0;
  for (var x in list) {
    Expect.equals(list[i++], x);
  }
  Expect.isTrue(list.any((x) => x == last));
  Expect.isFalse(list.any((x) => false));
  Expect.isTrue(list.contains(last));
  Expect.equals(first, list.elementAt(0));
  Expect.isTrue(list.every((x) => true));
  Expect.isFalse(list.every((x) => x != last));
  Expect.listEquals([], list.expand((x) => []).toList());
  var expand2 = list.expand((x) => [x, x]);
  i = 0;
  for (var x in expand2) {
    Expect.equals(list[i ~/ 2], x);
    i++;
  }
  Expect.equals(2 * list.length, i);
  Expect.listEquals(list, list.fold([], (result, x) => result..add(x)));
  i = 0;
  list.forEach((x) {
    Expect.equals(list[i++], x);
  });
  Expect.equals(list.toList().join("*"), list.join("*"));
  Expect.listEquals(list, list.map((x) => x).toList());
  int mapCount = 0;
  var mappedList = list.map((x) {
    mapCount++;
    return x;
  });
  Expect.equals(0, mapCount);
  Expect.equals(list.length, mappedList.length);
  Expect.equals(0, mapCount);
  mappedList.join();
  Expect.equals(list.length, mapCount);

  Expect.listEquals(list, list.where((x) => true).toList());
  int whereCount = 0;
  var whereList = list.where((x) {
    whereCount++;
    return true;
  });
  Expect.equals(0, whereCount);
  Expect.equals(list.length, whereList.length);
  Expect.equals(list.length, whereCount);

  if (list.length > 1) {
    var reduceResult = toElementType(1);
    Expect.equals(
        toElementType(list.length), list.reduce((x, y) => reduceResult + 1));
  } else {
    Expect.equals(first, list.reduce((x, y) {
      throw "should not be called";
    }));
  }

  Expect.isTrue(list.skip(list.length).isEmpty);
  Expect.listEquals(list, list.skip(0).toList());
  Expect.isTrue(list.skipWhile((x) => true).isEmpty);
  Expect.listEquals(list, list.skipWhile((x) => false).toList());
  Expect.listEquals(list, list.take(list.length).toList());
  Expect.isTrue(list.take(0).isEmpty);
  Expect.isTrue(list.takeWhile((x) => false).isEmpty);
  Expect.listEquals(list, list.takeWhile((x) => true).toList());
  Expect.listEquals(list, list.toList().toList());
  var l2 = list.toList();
  l2.add(first);
  Expect.equals(first, l2.last);
  var l3 = list.toList(growable: false);
  Expect.throws(() => l3.add(last), (e) => e is UnsupportedError);
}

void emptyChecks(list) {
  assert(list.length == 0);

  Expect.isTrue(list.isEmpty);

  Expect.throws(() => list.first, (e) => e is StateError);
  Expect.throws(() => list.last, (e) => e is StateError);
  Expect.throws(() => list.single, (e) => e is StateError);
  Expect.throws(() => list.firstWhere((x) => true), (e) => e is StateError);
  Expect.throws(() => list.lastWhere((x) => true), (e) => e is StateError);
  Expect.throws(() => list.singleWhere((x) => true), (e) => e is StateError);

  Expect.isFalse(list.any((x) => true));
  Expect.isFalse(list.contains(null));
  Expect.throws(() => list.elementAt(0), (e) => e is RangeError);
  Expect.isTrue(list.every((x) => false));
  Expect.listEquals([], list.expand((x) => []).toList());
  Expect.listEquals([], list.expand((x) => [x, x]).toList());
  Expect.listEquals(
      [],
      list.expand((x) {
        throw "should not be reached";
      }).toList());
  Expect.listEquals([], list.fold([], (result, x) => result..add(x)));
  Expect.equals(list.toList().join("*"), list.join("*"));
  Expect.listEquals(list, list.map((x) => x).toList());
  int mapCount = 0;
  var mappedList = list.map((x) {
    mapCount++;
    return x;
  });
  Expect.equals(0, mapCount);
  Expect.equals(list.length, mappedList.length);
  Expect.equals(0, mapCount);
  mappedList.join();
  Expect.equals(list.length, mapCount);

  Expect.listEquals(list, list.where((x) => true).toList());
  int whereCount = 0;
  var whereList = list.where((x) {
    whereCount++;
    return true;
  });
  Expect.equals(0, whereCount);
  Expect.equals(list.length, whereList.length);
  Expect.equals(list.length, whereCount);

  Expect.throws(() => list.reduce((x, y) => x), (e) => e is StateError);

  Expect.isTrue(list.skip(list.length).isEmpty);
  Expect.isTrue(list.skip(0).isEmpty);
  Expect.isTrue(list.skipWhile((x) => true).isEmpty);
  Expect.isTrue(list.skipWhile((x) => false).isEmpty);
  Expect.isTrue(list.take(list.length).isEmpty);
  Expect.isTrue(list.take(0).isEmpty);
  Expect.isTrue(list.takeWhile((x) => false).isEmpty);
  Expect.isTrue(list.takeWhile((x) => true).isEmpty);
  Expect.isTrue(list.toList().isEmpty);
  var l2 = list.toList();
  var sampleValue = list is List<int> ? 0 : 0.0;
  l2.add(sampleValue);
  Expect.equals(sampleValue, l2.last);
  var l3 = list.toList(growable: false);
  Expect.throws(() => l3.add(sampleValue), (e) => e is UnsupportedError);
}

main() {
  toDouble(x) => x.toDouble();
  toInt(x) => x.toInt();

  testIterableFunctions(
      new Float32List.fromList([1.5, 9.5]), 1.5, 9.5, toDouble);
  testIterableFunctions(
      new Float64List.fromList([1.5, 9.5]), 1.5, 9.5, toDouble);
  testIterableFunctions(new Int8List.fromList([3, 9]), 3, 9, toInt);
  testIterableFunctions(new Int16List.fromList([3, 9]), 3, 9, toInt);
  testIterableFunctions(new Int32List.fromList([3, 9]), 3, 9, toInt);
  testIterableFunctions(new Uint8List.fromList([3, 9]), 3, 9, toInt);
  testIterableFunctions(new Uint16List.fromList([3, 9]), 3, 9, toInt);
  testIterableFunctions(new Uint32List.fromList([3, 9]), 3, 9, toInt);

  emptyChecks(new Float32List(0));
  emptyChecks(new Float64List(0));
  emptyChecks(new Int8List(0));
  emptyChecks(new Int16List(0));
  emptyChecks(new Int32List(0));
  emptyChecks(new Uint8List(0));
  emptyChecks(new Uint16List(0));
  emptyChecks(new Uint32List(0));
}
