// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that map literals are ordered.

class OrderedMapsTest {
  static testMain() {
    testMaps(const {"a": 1, "c": 2}, const {"c": 2, "a": 1}, true);
    testMaps({"a": 1, "c": 2}, {"c": 2, "a": 1}, false);
  }

  static void testMaps(map1, map2, bool isConst) {
    Expect.isFalse(identical(map1, map2));

    var keys = map1.keys.toList();
    Expect.equals(2, keys.length);
    Expect.equals("a", keys[0]);
    Expect.equals("c", keys[1]);

    keys = map2.keys.toList();
    Expect.equals(2, keys.length);
    Expect.equals("c", keys[0]);
    Expect.equals("a", keys[1]);

    var values = map1.values.toList();
    Expect.equals(2, values.length);
    Expect.equals(1, values[0]);
    Expect.equals(2, values[1]);

    values = map2.values.toList();
    Expect.equals(2, values.length);
    Expect.equals(2, values[0]);
    Expect.equals(1, values[1]);

    if (isConst) return;

    map1["b"] = 3;
    map2["b"] = 3;

    keys = map1.keys.toList();
    Expect.equals(3, keys.length);
    Expect.equals("a", keys[0]);
    Expect.equals("c", keys[1]);
    Expect.equals("b", keys[2]);

    keys = map2.keys.toList();
    Expect.equals(3, keys.length);
    Expect.equals("c", keys[0]);
    Expect.equals("a", keys[1]);
    Expect.equals("b", keys[2]);

    values = map1.values.toList();
    Expect.equals(3, values.length);
    Expect.equals(1, values[0]);
    Expect.equals(2, values[1]);
    Expect.equals(3, values[2]);

    values = map2.values.toList();
    Expect.equals(3, values.length);
    Expect.equals(2, values[0]);
    Expect.equals(1, values[1]);
    Expect.equals(3, values[2]);

    map1["a"] = 4;
    keys = map1.keys.toList();
    Expect.equals(3, keys.length);
    Expect.equals("a", keys[0]);

    values = map1.values.toList();
    Expect.equals(3, values.length);
    Expect.equals(4, values[0]);
  }
}

main() {
  OrderedMapsTest.testMain();
}
