// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map_unmodifiable_cast_test;

import "package:expect/expect.dart";
import 'dart:collection';

void main() {
  test(const {1: 37});
  test(new UnmodifiableMapView({1: 37}));

  test(new UnmodifiableMapView<num, num>(<num, num>{1: 37}));
  test(new UnmodifiableMapView<num, num>(<int, int>{1: 37}));

  test(new UnmodifiableMapView<num, num>(<num, num>{1: 37}).cast<int, int>());
  test(new UnmodifiableMapView<num, num>(<int, int>{1: 37}).cast<int, int>());
  test(new UnmodifiableMapView<Object, Object>(<num, num>{1: 37})
      .cast<int, int>());
  test(new UnmodifiableMapView<Object, Object>(<int, int>{1: 37})
      .cast<num, num>());

  test(new UnmodifiableMapView<num, num>(<num, num>{1: 37}).retype<int, int>());
  test(new UnmodifiableMapView<num, num>(<int, int>{1: 37}).retype<int, int>());
  test(new UnmodifiableMapView<Object, Object>(<num, num>{1: 37})
      .retype<int, int>());
  test(new UnmodifiableMapView<Object, Object>(<int, int>{1: 37})
      .retype<num, num>());

  var m2 = new Map<num, num>.unmodifiable({1: 37});
  test(m2);
  test(m2.cast<int, int>());
}

void test(Map map) {
  Expect.isTrue(map.containsKey(1));
  Expect.equals(1, map.length);
  Expect.equals(1, map.keys.first);
  Expect.equals(37, map.values.first);

  Expect.throws(map.clear);
  Expect.throws(() {
    map.remove(1);
  });
  Expect.throws(() {
    map[2] = 42;
  });
  Expect.throws(() {
    map.addAll(<int, int>{2: 42});
  });
}
