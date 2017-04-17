// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  defaultFunctionValuesTest();
  defaultKeyFunctionTest();
  defaultValueFunctionTest();
  noDefaultValuesTest();
  emptyIterableTest();
  equalElementsTest();
  genericTypeTest();
}

void defaultFunctionValuesTest() {
  var map = new LinkedHashMap.fromIterable([1, 2, 3]);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is LinkedHashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(1, map[1]);
  Expect.equals(2, map[2]);
  Expect.equals(3, map[3]);
}

void defaultKeyFunctionTest() {
  var map = new LinkedHashMap.fromIterable([1, 2, 3], value: (x) => x + 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is LinkedHashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(2, map[1]);
  Expect.equals(3, map[2]);
  Expect.equals(4, map[3]);
}

void defaultValueFunctionTest() {
  var map = new LinkedHashMap.fromIterable([1, 2, 3], key: (x) => x + 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is LinkedHashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(1, map[2]);
  Expect.equals(2, map[3]);
  Expect.equals(3, map[4]);
}

void noDefaultValuesTest() {
  var map = new LinkedHashMap.fromIterable([1, 2, 3],
      key: (x) => x + 1, value: (x) => x - 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is LinkedHashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(0, map[2]);
  Expect.equals(1, map[3]);
  Expect.equals(2, map[4]);
}

void emptyIterableTest() {
  var map = new LinkedHashMap.fromIterable([]);
  Expect.isTrue(map is Map);
  Expect.isTrue(map is LinkedHashMap);

  Expect.equals(0, map.length);
  Expect.equals(0, map.keys.length);
  Expect.equals(0, map.values.length);
}

void equalElementsTest() {
  var map = new LinkedHashMap.fromIterable([1, 2, 2], key: (x) => x + 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is LinkedHashMap);

  Expect.equals(2, map.length);
  Expect.equals(2, map.keys.length);
  Expect.equals(2, map.values.length);

  Expect.equals(1, map[2]);
  Expect.equals(2, map[3]);
}

void genericTypeTest() {
  var map = new LinkedHashMap<int, String>.fromIterable(<int>[1, 2, 3],
      value: (x) => '$x');
  Expect.isTrue(map is Map<int, String>);
  Expect.isTrue(map is LinkedHashMap<int, String>);

  map = new LinkedHashMap<String, String>.fromIterable(<int>[1, 2, 3],
      key: (x) => '$x', value: (x) => '$x');
  Expect.isTrue(map is Map<String, String>);
  Expect.isTrue(map is LinkedHashMap<String, String>);

  // Make sure it is not just LinkedHashMap<dynamic, dynamic>.
  Expect.isFalse(map is LinkedHashMap<int, dynamic>);
  Expect.isFalse(map is LinkedHashMap<dynamic, int>);
}
