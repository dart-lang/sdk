// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test program for the HashMap class.

class HashMapTest {

  static testMain() {
    // TODO(srdjan/ngeoffray): Add more meaningful testing below. For now this
    // is used to verify that the test script is picking up these tests.
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
