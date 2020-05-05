// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import "dart:collection";
import "package:expect/expect.dart";
import 'cast_helper.dart';

void main() {
  testIterable();
  testList();
  testMap();
  testSet();
}

testIterable() {
  var iterable = new Iterable<C?>.generate(elements.length, (n) => elements[n]);
  var iterableNonNull = Iterable.castFrom<C?, C>(iterable);
  // Downcast non-nullable.

  // An iterable that (likely) can do direct access.
  var dIterableDirect = Iterable.castFrom<C, D>(iterableNonNull);
  Expect.equals(d, dIterableDirect.elementAt(1));
  Expect.equals(null, dIterableDirect.skip(3).elementAt(1));

  // An iterable that cannot do direct access.
  var dIterableNonDirect =
      Iterable.castFrom<C, D>(iterableNonNull.where((_) => true));
  Expect.equals(d, dIterableNonDirect.elementAt(1));
  Expect.equals(null, dIterableNonDirect.skip(3).elementAt(1));

  // Iterable that definitely won't survive accessing element 3.
  var iterableLimited = new Iterable<C?>.generate(
      elements.length, (n) => n == 3 ? throw "untouchable" : elements[n]);
  var iterableLimitedNonNull = Iterable.castFrom<C?, C>(iterableLimited);
  var dIterableLimited = Iterable.castFrom<C, D>(iterableLimitedNonNull);
  Expect.equals(d, dIterableLimited.elementAt(1));
  Expect.equals(null, dIterableLimited.skip(3).elementAt(1));

  // Upcast non-nullable.
  var objectIterable = Iterable.castFrom<C, Object>(iterableNonNull);
  Expect.equals(null, objectIterable.skip(3).elementAt(1));
}

testList() {
  var list = new List<C?>.from(elements);
  var listNonNull = List.castFrom<C?, C>(list);

  // Downcast non-nullable.
  var dList = List.castFrom<C, D>(listNonNull);
  Expect.equals(d, dList[1]);
  Expect.equals(null, dList.last);

  // Upcast non-nullable.
  var objectList = List.castFrom<C, Object>(listNonNull);
  Expect.equals(null, objectList.last);
}

testMap() {
  var map = new Map.fromIterables(elements, elements);
  var mapNonNull = Map.castFrom<C?, C?, C, C>(map);

  // Downcast non-nullable.
  var dMap = Map.castFrom<C, C, D, D>(mapNonNull);
  Expect.equals(d, dMap[d]);
  Expect.isTrue(dMap.containsKey(null));
  Expect.equals(null, dMap[null]);

  // Test keys and values
  Expect.isTrue(dMap.keys is Iterable<D>);
  Expect.isTrue(dMap.values is Iterable<D>);
  Expect.throws(() => dMap.keys.toList());
  Expect.throws(() => dMap.values.toList());

  // Upcast non-nullable.
  var objectMap = Map.castFrom<C, C, Object, Object>(mapNonNull);
  Expect.isTrue(objectMap.containsKey(null));
  Expect.equals(null, objectMap[null]);

  // Test keys and values
  Expect.isTrue(objectMap.keys is Iterable<Object>);
  Expect.isTrue(objectMap.values is Iterable<Object>);
  var expectedValues = new List<Object>.from(elements);
  Expect.listEquals(expectedValues, objectMap.values.toList());
}

testSet() {
  var setEls = new Set<C?>.from(elements);
  var setNonNull = Set.castFrom<C?, C>(setEls);

  // Downcast non-nullable.
  var dSet = Set.castFrom<C, D>(setNonNull);
  Expect.equals(d, dSet.elementAt(1));
  Expect.equals(null, dSet.last);

  // Upcast non-nullable.
  var objectSet = Set.castFrom<C, Object>(setNonNull);
  Expect.equals(null, objectSet.last);
}
