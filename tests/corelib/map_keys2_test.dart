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

  Expect.isTrue(map1.keys is Iterable<String>);
  Expect.isTrue(map1.keys is Iterable<bool>);

  Expect.isTrue(map2.keys is Iterable<String>);
  Expect.isTrue(map2.keys is Iterable<bool>);

  Expect.isTrue(map3.keys is Iterable<String>);
  Expect.isTrue(map3.keys is Iterable<bool>);

  Expect.isTrue(map4.keys is Iterable<String>);
  Expect.isTrue(map4.keys is Iterable<bool>);

  Expect.isTrue(map5.keys is Iterable<String>);
  Expect.isFalse(map5.keys is Iterable<bool>);

  Expect.isTrue(map6.keys is Iterable<String>);
  Expect.isFalse(map6.keys is Iterable<bool>);
}
