// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

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
  // Downcast non-nullable.

  // An iterable that (likely) can do direct access.
  var dIterableDirect = Iterable.castFrom<C?, D>(iterable);
  Expect.equals(d, dIterableDirect.elementAt(1));
  // null is not D.
  Expect.throws(() => dIterableDirect.skip(3).elementAt(1));

  // An iterable that cannot do direct access.
  var dIterableNonDirect =
      Iterable.castFrom<C?, D>(iterable.where((_) => true));
  Expect.equals(d, dIterableNonDirect.elementAt(1));
  // null is not D.
  Expect.throws(() => dIterableNonDirect.skip(3).elementAt(1));

  // Iterable that definitely won't survive accessing element 3.
  var iterableLimited = new Iterable<C?>.generate(
      elements.length, (n) => n == 3 ? throw "untouchable" : elements[n]);
  var dIterableLimited = Iterable.castFrom<C?, D>(iterableLimited);
  Expect.equals(d, dIterableLimited.elementAt(1));
  // null is not D.
  Expect.throws(() => dIterableLimited.skip(3).elementAt(1));

  // Upcast non-nullable.
  var objectIterable = Iterable.castFrom<C?, Object>(iterable);
  // null is not Object.
  Expect.throws(() => objectIterable.skip(3).elementAt(1));
}

testList() {
  var list = new List<C?>.from(elements);

  // Downcast non-nullable.
  var dList = List.castFrom<C?, D>(list);
  Expect.equals(d, dList[1]);
  Expect.throws(() => dList.last); // null is not D.

  // Upcast non-nullable.
  var objectList = List.castFrom<C?, Object>(list);
  Expect.throws(() => objectList.last); // null is not Object.
}

testMap() {
  var map = new Map.fromIterables(elements, elements);

  // Downcast non-nullable.
  var dMap = Map.castFrom<C?, C?, D, D>(map);
  Expect.equals(d, dMap[d]);
  Expect.isTrue(dMap.containsKey(null));
  Expect.equals(null, dMap[null]);

  // Test keys and values
  Expect.isTrue(dMap.keys is Iterable<D>);
  Expect.isTrue(dMap.values is Iterable<D>);
  Expect.throws(() => dMap.keys.toList());
  Expect.throws(() => dMap.values.toList());

  // Upcast non-nullable.
  var objectMap = Map.castFrom<C?, C?, Object, Object>(map);
  Expect.isTrue(objectMap.containsKey(null));
  Expect.equals(null, objectMap[null]);

  // Test keys and values
  Expect.isTrue(objectMap.keys is Iterable<Object>);
  Expect.isTrue(objectMap.values is Iterable<Object>);
  // null is not Object.
  Expect.throws(() => objectMap.keys.toList());
  Expect.throws(() => objectMap.values.toList());
}

testSet() {
  var setEls = new Set<C?>.from(elements);

  // Downcast non-nullable.
  var dSet = Set.castFrom<C?, D>(setEls);
  Expect.equals(d, dSet.elementAt(1));
  Expect.throws(() => dSet.last); // null is not D.

  // Upcast non-nullable.
  var objectSet = Set.castFrom<C?, Object>(setEls);
  Expect.throws(() => objectSet.last); // null is not Object.
}
