// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use of '__proto__' keys in maps.

library map_literal10_test;

import "package:expect/expect.dart";

void main() {
  var m1 = const {"__proto__": 0, 1: 1};
  Expect.isTrue(m1.containsKey("__proto__"));
  Expect.equals(0, m1["__proto__"]);
  Expect.isTrue(m1.containsKey(1));
  Expect.equals(1, m1[1]);
  Expect.listEquals(["__proto__", 1], m1.keys.toList());

  var m2 = const {1: 0, "__proto__": 1};
  Expect.isTrue(m2.containsKey(1));
  Expect.equals(0, m2[1]);
  Expect.isTrue(m2.containsKey("__proto__"));
  Expect.equals(1, m2["__proto__"]);
  Expect.listEquals([1, "__proto__"], m2.keys.toList());

  var m3 = const {"1": 0, "__proto__": 1};
  Expect.isTrue(m3.containsKey("1"));
  Expect.equals(0, m3["1"]);
  Expect.isTrue(m3.containsKey("__proto__"));
  Expect.equals(1, m3["__proto__"]);
  Expect.listEquals(["1", "__proto__"], m3.keys.toList());

  var m4 = const {"__proto__": 1, "1": 2};
  Expect.isTrue(m4.containsKey("1"));
  Expect.equals(2, m4["1"]);
  Expect.isTrue(m4.containsKey("__proto__"));
  Expect.equals(1, m4["__proto__"]);
  Expect.listEquals(["__proto__", "1"], m4.keys.toList());
}
