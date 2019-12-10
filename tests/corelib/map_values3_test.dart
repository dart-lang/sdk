// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var map1 = <int, String>{1: "42", 2: "499"};
  var map2 = <int, String>{};
  var map3 = const <int, String>{3: "42", 4: "499"};
  var map4 = const <int, String>{};
  var map5 = new Map<int, String>();
  map5[5] = "43";
  map5[6] = "500";
  var map6 = new Map<int, String>();

  Expect.isTrue(map1.values is Iterable<String>);
  Expect.isFalse(map1.values is Iterable<bool>);
  Expect.isFalse(map1.values is List);
  Expect.equals(2, map1.values.length);
  Expect.equals("42", map1.values.first);
  Expect.equals("499", map1.values.last);

  Expect.isTrue(map2.values is Iterable<String>);
  Expect.isFalse(map2.values is Iterable<bool>);
  Expect.isFalse(map2.values is List);
  Expect.equals(0, map2.values.length);

  Expect.isTrue(map3.values is Iterable<String>);
  Expect.isFalse(map3.values is Iterable<bool>);
  Expect.isFalse(map3.values is List);
  Expect.equals(2, map3.values.length);
  Expect.equals("42", map3.values.first);
  Expect.equals("499", map3.values.last);

  Expect.isTrue(map4.values is Iterable<String>);
  Expect.isFalse(map4.values is Iterable<bool>);
  Expect.isFalse(map4.values is List);
  Expect.equals(0, map4.values.length);

  Expect.isTrue(map5.values is Iterable<String>);
  Expect.isFalse(map5.values is Iterable<bool>);
  Expect.isFalse(map5.values is List);
  Expect.equals(2, map5.values.length);
  // new Map gives a LinkedHashMap, so we know the order.
  Expect.isTrue(map5.values.first == "43");
  Expect.isTrue(map5.values.last == "500");

  Expect.isTrue(map6.values is Iterable<String>);
  Expect.isFalse(map6.values is Iterable<bool>);
  Expect.isFalse(map6.values is List);
  Expect.equals(0, map6.values.length);
}
