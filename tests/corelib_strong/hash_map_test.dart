// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--use_internal_hash_map

import "package:expect/expect.dart";

// Test program for the HashMap class.

class HashMapTest {
  static testMain() {
    var m = new Map();
    Expect.equals(0, m.length);
    Expect.equals(true, m.isEmpty);
    m["one"] = 1;
    Expect.equals(1, m.length);
    Expect.equals(false, m.isEmpty);
    Expect.equals(1, m["one"]);
  }
}

main() {
  HashMapTest.testMain();
}
