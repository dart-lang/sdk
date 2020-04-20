// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for map literals.

import "package:expect/expect.dart";

class MapLiteralTest {
  static testMain() {
    var map = <dynamic, dynamic>{"a": 1, "b": 2, "c": 3};

    Expect.equals(map.length, 3);
    Expect.equals(map["a"], 1);
    Expect.equals(map["z"], null);
    Expect.equals(map["c"], 3);

    map["foo"] = 42;
    Expect.equals(map.length, 4);
    Expect.equals(map["foo"], 42);
    map["foo"] = 55;
    Expect.equals(map.length, 4);
    Expect.equals(map["foo"], 55);

    map.remove("foo");
    Expect.equals(map.length, 3);
    Expect.equals(map["foo"], null);

    map["foo"] = "bar";
    Expect.equals(map.length, 4);
    Expect.equals(map["foo"], "bar");

    map.clear();
    Expect.equals(map.length, 0);

    var b = 22;
    Expect.equals(
        22,
        {
          "a": 11,
          "b": b,
        }["b"]);

    var m = new Map();
    Expect.equals(m.length, 0);
    for (var i = 1; i <= 16; i++) {
      m[i.toString()] = i;
    }
    Expect.equals(16, m.length);
    Expect.equals(1, m.remove("1"));
    Expect.isNull(m.remove("1")); // Remove element twice.
    Expect.equals(16, m.remove("16"));
    Expect.equals(14, m.length);

    final cmap = const <String, num>{"a": 10, "b": 100, "a": 1000}; //# 01: compile-time error
    final cmap2 = const <String, num>{"a": 10, "a": 100, "a": 1000}; //# 02: compile-time error
    var mmap = <String, num>{"a": 10, "b": 100, "a": 1000}; //# 03: ok
    var mmap = <String, num>{"a": ctr(), "b": ctr(), "a": ctr()}; //# 04: compile-time error

    Expect.equals(10, {"beta": 100, "alpha": 9 + 1}["alpha"]);
    Expect.equals(
        10,
        <String, Map>{
          "beta": {"delta": 10},
          "alpha": {"gamma": 10}
        }["alpha"]["gamma"]);

    // Map literals at beginning of statement.
    <String, num>{"pink": 100};
    const <String, num>{"floyd": 100};
  }
}

main() {
  MapLiteralTest.testMain();
}
