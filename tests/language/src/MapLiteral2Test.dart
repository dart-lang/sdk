// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for map literals.

final AA = 1;
final BB = 2;

int nextValCtr;

get nextVal() {
  return nextValCtr++;
}

class MapLiteral2Test {
  static testMain() {
    // Map literals with string interpolation in keys.
    var map = const { "a$AA": 88, "b$BB": 99 };
    Expect.equals(2, map.length);
    Expect.equals("a1", "a$AA");
    Expect.equals(88, map["a1"]);
    Expect.equals("b2", "b$BB");
    Expect.equals(99, map["b2"]);

    nextValCtr = 0;
    map = {"a$nextVal": "Grey", "a$nextVal": "Poupon" };
    Expect.equals(true, map.containsKey("a0"));
    Expect.equals(true, map.containsKey("a1"));
    Expect.equals("Grey", map["a0"]);
    Expect.equals("Poupon", map["a1"]);
  }
}



main() {
  MapLiteral2Test.testMain();
}
