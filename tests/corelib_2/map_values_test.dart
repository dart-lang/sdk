// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var map1 = {"foo": 42, "bar": 499};
  var map2 = {};
  var map3 = const {"foo": 42, "bar": 499};
  var map4 = const {};
  var map5 = new Map<String, int>();
  map5["foo"] = 43;
  map5["bar"] = 500;
  var map6 = new Map<String, bool>();

  Expect.isTrue(map1.values is Iterable);
  Expect.isFalse(map1.values is List);
  Expect.equals(2, map1.values.length);
  Expect.equals(42, map1.values.first);
  Expect.equals(499, map1.values.last);

  Expect.isTrue(map2.values is Iterable);
  Expect.isFalse(map2.values is List);
  Expect.equals(0, map2.values.length);

  Expect.isTrue(map3.values is Iterable);
  Expect.isFalse(map3.values is List);
  Expect.equals(2, map3.values.length);
  Expect.equals(42, map3.values.first);
  Expect.equals(499, map3.values.last);

  Expect.isTrue(map4.values is Iterable);
  Expect.isFalse(map4.values is List);
  Expect.equals(0, map4.values.length);

  Expect.isTrue(map5.values is Iterable);
  Expect.isFalse(map5.values is List);
  Expect.equals(2, map5.values.length);
  Expect.isTrue(map5.values.first == 43 || map5.values.first == 500);
  Expect.isTrue(map5.values.last == 43 || map5.values.last == 500);
  Expect.notEquals(map5.values.first, map5.values.last);

  Expect.isTrue(map6.values is Iterable);
  Expect.isFalse(map6.values is List);
  Expect.equals(0, map6.values.length);
}
