// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for map literals.

import "package:expect/expect.dart";

class MapLiteralTest {
  static testMain() {
    var map = {"a": 1, "b": 2, "c": 3};

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

    // Make map grow. We currently don't have a way to construct
    // strings from an integer value, so we can't use a loop here.
    var m = new Map();
    Expect.equals(m.length, 0);
    m["1"] = 1;
    m["2"] = 2;
    m["3"] = 3;
    m["4"] = 4;
    m["5"] = 5;
    m["6"] = 6;
    m["7"] = 7;
    m["8"] = 8;
    m["9"] = 9;
    m["10"] = 10;
    m["11"] = 11;
    m["12"] = 12;
    m["13"] = 13;
    m["14"] = 14;
    m["15"] = 15;
    m["16"] = 16;
    Expect.equals(16, m.length);
    m.remove("1");
    m.remove("1"); // Remove element twice.
    m.remove("16");
    Expect.equals(14, m.length);

    // Check that last value of duplicate key wins for const maps.
    final cmap = const <String, num>{"a": 10, "b": 100, "a": 1000}; //# static type warning
    Expect.equals(2, cmap.length);
    Expect.equals(1000, cmap["a"]);
    Expect.equals(100, cmap["b"]);

    final cmap2 = const <String, num>{"a": 10, "a": 100, "a": 1000}; //# static type warning
    Expect.equals(1, cmap2.length);
    Expect.equals(1000, cmap["a"]);

    // Check that last value of duplicate key wins for mutable maps.
    var mmap = <String, num>{"a": 10, "b": 100, "a": 1000}; //# static type warning

    Expect.equals(2, mmap.length);
    Expect.equals(1000, mmap["a"]);
    Expect.equals(100, mmap["b"]);

    // Check that even if a key gets eliminated (the first "a"), all values
    // are still evaluated, including side effects.
    int counter = 0;
    int ctr() {
      counter += 10;
      return counter;
    }

    mmap = <String, num>{"a": ctr(), "b": ctr(), "a": ctr()}; //# static type warning
    Expect.equals(2, mmap.length);
    Expect.equals(40, ctr());
    Expect.equals(30, mmap["a"]);
    Expect.equals(20, mmap["b"]);

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
