// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map.from.test;

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  for (Map<num, num> map in [
    <num, num>{},
    const <num, num>{},
    new HashMap<num, num>(),
    new LinkedHashMap<num, num>(),
    new SplayTreeMap<num, num>(),
    <num, num>{1: 11, 2: 12, 4: 14},
    const <num, num>{1: 11, 2: 12, 4: 14},
    new Map<num, num>()
      ..[1] = 11
      ..[2] = 12
      ..[3] = 13,
    new HashMap<num, num>()
      ..[1] = 11
      ..[2] = 12
      ..[3] = 13,
    new LinkedHashMap<num, num>()
      ..[1] = 11
      ..[2] = 12
      ..[3] = 13,
    new SplayTreeMap<num, num>()
      ..[1] = 11
      ..[2] = 12
      ..[3] = 13,
  ]) {
    expectThrows(void operation()) {
      Expect.throwsTypeError(operation);
    }

    var sourceType = map.runtimeType.toString();
    check(sourceType, map, new Map<Object, Object>.of(map));
    check(sourceType, map, new Map<num, num>.of(map));
    expectThrows(() => new Map<int, int>.of(map));
    check(sourceType, map, new HashMap<Object, Object>.of(map));
    check(sourceType, map, new HashMap<num, num>.of(map));
    expectThrows(() => new HashMap<int, int>.of(map));
    check(sourceType, map, new LinkedHashMap<Object, Object>.of(map));
    check(sourceType, map, new LinkedHashMap<num, num>.of(map));
    expectThrows(() => new LinkedHashMap<int, int>.of(map));
    check(sourceType, map, new SplayTreeMap<Object, Object>.of(map));
    check(sourceType, map, new SplayTreeMap<num, num>.of(map));
    expectThrows(() => new SplayTreeMap<int, int>.of(map));
  }
}

check(String sourceType, Map<num, num> expect, Map actual) {
  var targetType = actual.runtimeType.toString();
  var name = "$sourceType->$targetType";
  Expect.equals(expect.length, actual.length, "$name.length");
  for (var key in expect.keys) {
    Expect.isTrue(actual.containsKey(key), "$name?[$key]");
    Expect.equals(expect[key], actual[key], "$name[$key]");
  }
}
