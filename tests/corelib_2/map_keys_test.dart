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

  Expect.isTrue(map1.keys is Iterable);
  Expect.isFalse(map1.keys is List);
  Expect.equals(2, map1.keys.length);
  Expect.equals("foo", map1.keys.first);
  Expect.equals("bar", map1.keys.last);

  Expect.isTrue(map2.keys is Iterable);
  Expect.isFalse(map2.keys is List);
  Expect.equals(0, map2.keys.length);

  Expect.isTrue(map3.keys is Iterable);
  Expect.isFalse(map3.keys is List);
  Expect.equals(2, map3.keys.length);
  Expect.equals("foo", map3.keys.first);
  Expect.equals("bar", map3.keys.last);

  Expect.isTrue(map4.keys is Iterable);
  Expect.isFalse(map4.keys is List);
  Expect.equals(0, map4.keys.length);

  Expect.isTrue(map5.keys is Iterable);
  Expect.isFalse(map5.keys is List);
  Expect.equals(2, map5.keys.length);
  Expect.isTrue(map5.keys.first == "foo" || map5.keys.first == "bar");
  Expect.isTrue(map5.keys.last == "foo" || map5.keys.last == "bar");
  Expect.notEquals(map5.keys.first, map5.keys.last);

  Expect.isTrue(map6.keys is Iterable);
  Expect.isFalse(map6.keys is List);
  Expect.equals(0, map6.keys.length);
}
