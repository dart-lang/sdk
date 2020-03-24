// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map_unmodifiable_cast_test;

import "package:expect/expect.dart";
import 'dart:collection';

void main() {
  testNum(const {1: 37}, "const");
  testNum(const <num, num>{1: 37}.cast<int, int>(), "const.cast");

  testNum(new UnmodifiableMapView({1: 37}), "unmod");
  testNum(new UnmodifiableMapView<num, num>(<num, num>{1: 37}), "unmod.cast");
  testNum(new UnmodifiableMapView<num, num>(<num, num>{1: 37}).cast<int, int>(),
      "unmodView<num>(num).cast<int>");
  testNum(new UnmodifiableMapView<num, num>(<int, int>{1: 37}).cast<int, int>(),
      "unmodView<num>(int).cast<int>");
  testNum(
      new UnmodifiableMapView<Object, Object>(<num, num>{1: 37})
          .cast<int, int>(),
      "unmodView<Object>(num).cast<int>");
  testNum(
      new UnmodifiableMapView<Object, Object>(<int, int>{1: 37})
          .cast<num, num>(),
      "unmodView<Object>(int).cast<num>");

  var m2 = new Map<num, num>.unmodifiable({1: 37});
  testNum(m2, "Map<num>.unmod");
  testNum(m2.cast<int, int>(), "Map<num>.unmod.cast<int>");

  Map<Symbol, dynamic> nsm = new NsmMap().foo(a: 0);
  test<Symbol, dynamic>(nsm, #a, 0, "nsm", noSuchMethodMap: true);
  test<Object, int>(nsm.cast<Object, int>(), #a, 0, "nsm.cast",
      noSuchMethodMap: true);
}

void testNum(Map<Object, Object> map, String name) {
  test<int, int>(map, 1, 37, name);
}

void test<K, V>(map, firstKey, firstValue, String name,
    {bool noSuchMethodMap: false}) {
  if (!noSuchMethodMap) {
    Expect.isTrue(map.containsKey(firstKey), "$name.containsKey");
    Expect.equals(1, map.length, "$name.length");
    Expect.equals(firstKey, map.keys.first, "$name.keys.first");
    Expect.equals(firstValue, map.values.first, "$name.values.first");
  }

  Expect.throwsUnsupportedError(map.clear, "$name.clear");
  Expect.throwsUnsupportedError(() {
    map.remove(firstKey);
  }, "$name.remove");
  Expect.throwsUnsupportedError(() {
    map[firstKey] = firstValue;
  }, "$name[]=");
  Expect.throwsUnsupportedError(() {
    map.addAll(<K, V>{firstKey: firstValue});
  }, "$name.addAll");
}

class NsmMap {
  noSuchMethod(i) => i.namedArguments;
  foo({a, b, c, d});
}
