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
  typedTest();
}

void defaultFunctionValuesTest() {
  var map = new SplayTreeMap.fromIterable([1, 2, 3]);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(1, map[1]);
  Expect.equals(2, map[2]);
  Expect.equals(3, map[3]);
}

void defaultKeyFunctionTest() {
  var map = new SplayTreeMap.fromIterable([1, 2, 3], value: (x) => x + 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(2, map[1]);
  Expect.equals(3, map[2]);
  Expect.equals(4, map[3]);
}

void defaultValueFunctionTest() {
  var map = new SplayTreeMap.fromIterable([1, 2, 3], key: (x) => x + 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(1, map[2]);
  Expect.equals(2, map[3]);
  Expect.equals(3, map[4]);
}

void noDefaultValuesTest() {
  var map = new SplayTreeMap.fromIterable([1, 2, 3],
      key: (x) => x + 1, value: (x) => x - 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals(0, map[2]);
  Expect.equals(1, map[3]);
  Expect.equals(2, map[4]);
}

void emptyIterableTest() {
  var map = new SplayTreeMap.fromIterable([]);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(0, map.length);
  Expect.equals(0, map.keys.length);
  Expect.equals(0, map.values.length);
}

void equalElementsTest() {
  var map = new SplayTreeMap.fromIterable([1, 2, 2], key: (x) => x + 1);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(2, map.length);
  Expect.equals(2, map.keys.length);
  Expect.equals(2, map.values.length);

  Expect.equals(1, map[2]);
  Expect.equals(2, map[3]);
}

void genericTypeTest() {
  var map = new SplayTreeMap<int, String>.fromIterable([1, 2, 3], value: (x) => '$x');
  Expect.isTrue(map is Map<int, String>);
  Expect.isTrue(map is SplayTreeMap<int, String>);

  // Make sure it is not just SplayTreeMap<dynamic, dynamic>.
  Expect.isFalse(map is SplayTreeMap<String, dynamic>);
  Expect.isFalse(map is SplayTreeMap<dynamic, int>);
}

// Test in checked mode with explicitly given types.
void typedTest() {
  bool isCheckedMode = false;
  assert((isCheckedMode = true));
  if (!isCheckedMode) return;

  Expect.throws(() {
    new SplayTreeMap<String,bool>.fromIterable(<int>[1, 2, 3],
      key: (int v) => "$v"
      // No "value" map, defaults to identity, which returns int, not bool.
    );
  });

  Expect.throws(() {
    new SplayTreeMap<String,bool>.fromIterable(<int>[1, 2, 3],
      // No "key" map, defaults to identity, which returns int, not String.
      value: (int v) => v.isOdd
    );
  });

  Expect.throws(() {
    new SplayTreeMap<String,bool>.fromIterable(<int>[1, 2, 3],
      key: (int v) => v,     // wrong type.
      value: (int v) => v.isOdd
    );
  });

  Expect.throws(() {
    new SplayTreeMap<String,bool>.fromIterable(<int>[1, 2, 3],
      key: (int v) => "$v",
      value: (int v) => v    // wrong type.
    );
  });

  // But it works with explicit types when used correctly.
  Map<String, bool> map =
      new SplayTreeMap<String, bool>.fromIterable(<int>[1, 2, 3],
                                                  key: (int v) => "$v",
                                                  value: (int v) => v.isOdd);
  Iterable<String> keys = map.keys;
  Iterable<bool> values = map.values;
  List<String> keyList = keys.toList();
  List<bool> valueList = values.toList();
  Expect.equals(3, keyList.length);
  Expect.equals(3, valueList.length);
  Expect.equals(keys.first, map.firstKey());
  Expect.equals(keys.last, map.lastKey());
}
