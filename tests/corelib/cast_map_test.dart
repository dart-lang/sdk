// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";
import 'cast_helper.dart';

void main() {
  testDowncast();
  testUpcast();
}

void testDowncast() {
  var map = new Map.fromIterables(elements, elements);
  var dMap = Map.castFrom<C?, C?, D?, D?>(map);

  Expect.isTrue(dMap is Map<D?, D?>);

  Expect.equals(null, dMap[new C()]);
  Expect.throws(() => dMap[c]); // C is not D?.
  Expect.isTrue(dMap.containsKey(c)); // containsKey should not be typed.
  Expect.equals(d, dMap[d]);
  Expect.throws(() => dMap[e]); // E is not D?.
  Expect.isTrue(dMap.containsKey(null));
  Expect.equals(null, dMap[null]);

  Expect.equals(5, dMap.length);
  Expect.throws(() => dMap.remove(c)); // Removes key but fails to return value.
  Expect.equals(4, dMap.length);
  Expect.equals(null, dMap[c]);

  // Test keys and values.
  Expect.isTrue(dMap.keys is Iterable<D?>);
  Expect.isTrue(dMap.values is Iterable<D?>);
  Expect.throws(() => dMap.keys.toList());
  Expect.throws(() => dMap.values.toList());
}

void testUpcast() {
  var map = new Map.fromIterables(elements, elements);
  var objectMap = Map.castFrom<C?, C?, Object?, Object?>(map);

  Expect.equals(5, objectMap.length);
  Expect.equals(c, objectMap[c]);
  Expect.isTrue(objectMap.containsKey(c));
  Expect.equals(c, objectMap.remove(c));
  Expect.equals(4, objectMap.length);

  // Test keys and values.
  Expect.isTrue(objectMap.keys is Iterable<Object?>);
  Expect.isTrue(objectMap.values is Iterable<Object?>);
  var expected = new List<Object?>.from(elements);
  expected.remove(c);
  Expect.listEquals(expected, objectMap.keys.toList());
  Expect.listEquals(expected, objectMap.values.toList());
}
