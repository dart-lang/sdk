// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests getters and setters where one or both is defined
// by an extension.

import "package:expect/expect.dart";

main() {
  C c = C();
  // v1: C get, C set
  expectGet("C.v1", c.v1);
  expectSet("C.v1=1", c.v1 = Result("1"));
  // v2: C get, E1 get/set, C wins.
  expectGet("C.v2", c.v2);
  expectSet("E1.v2=2", E1(c).v2 = Result("2"));
  // v3: E1 get/set, C set, C wins.
  expectGet("E1.v3", E1(c).v3);
  expectSet("C.v3=3", c.v3 = Result("3"));
  // v4: E1 get/set
  expectGet("E1.v4", c.v4);
  expectSet("E1.v4=4", c.v4 = Result("4"));
  // v5: E1 get, E2 set, neither more specific.
  expectGet("E1.v5", E1(c).v5);
  expectSet("E2.v5=5", E2(c).v5 = Result("5"));

  expectSet("C.v1=C.v1+1", c.v1++);
  expectSet("E1.v4=E1.v4+1", c.v4++);

  expectSet("C.v1=C.v1+a", c.v1 += "a");
  expectSet("C.v1=C.v1-b", c.v1 -= "b");
  expectSet("E1.v4=E1.v4-b", c.v4 -= "b");

  // Explicit application used by all accesses of read/write operations
  expectSet("E1.v1=E1.v1+1", E1(c).v1++);
  expectSet("E1.v2=E1.v2+1", E1(c).v2++);
  expectSet("E1.v3=E1.v3+1", E1(c).v3++);
  // Same using `+= 1` instead of `++`.
  expectSet("E1.v1=E1.v1+1", E1(c).v1 += 1);
  expectSet("E1.v2=E1.v2+1", E1(c).v2 += 1);
  expectSet("E1.v3=E1.v3+1", E1(c).v3 += 1);
  // Same fully expanded.
  expectSet("E1.v1=E1.v1+1", E1(c).v1 = E1(c).v1 + 1);
  expectSet("E1.v2=E1.v2+1", E1(c).v2 = E1(c).v2 + 1);
  expectSet("E1.v3=E1.v3+1", E1(c).v3 = E1(c).v3 + 1);

  // Cascades work.
  expectSet(
      "E1.v4=E1.v4+[C.v1=C.v1-[C.v3=a]]",
      c
        ..v3 = Result("a")
        ..v1 -= Result("[$lastSetter]")
        ..v4 += Result("[$lastSetter]"));
}

/// Expect the value of [result] to be the [expected] string
expectGet(String expected, Result result) {
  Expect.equals(expected, result.value);
}

/// Expect the [lastSetter] value set by evaluating [assignment] to be
/// [expected].
expectSet(String expected, void assignment) {
  Expect.equals(expected, lastSetter);
}

/// Last value passed to any of our tested setters.
String lastSetter = null;

/// A type which supports a `+` operation accepting `int`,
/// so we can test `+=` and `++`.
class Result {
  final String value;
  Result(this.value);
  Result operator +(Object o) => Result("$value+$o");
  Result operator -(Object o) => Result("$value-$o");
  String toString() => value;
}

/// Target type for extensions.
///
/// Declares [v1] getter and setter, [v2] getter and [v3] setter.
class C {
  Result get v1 => Result("C.v1");
  void set v1(Result value) {
    lastSetter = "C.v1=$value";
  }

  Result get v2 => Result("C.v2");

  void set v3(Result value) {
    lastSetter = "C.v3=$value";
  }
}

/// Primary extension on [C].
///
/// Declares [v1], [v2] and [v3] getters and setters.
///
/// Declares [v4] getter and setter, and [v5] getter
/// which are supplemented by a setter from the [E2] extension.
extension E1 on C {
  // Same basename as C getter and setter.
  Result get v1 => Result("E1.v1");

  void set v1(Result value) {
    lastSetter = "E1.v1=$value";
  }

  // Same basename as C getter.
  Result get v2 => Result("E1.v2");

  void set v2(Result value) {
    lastSetter = "E1.v2=$value";
  }

  // Same basename as C setter.
  Result get v3 => Result("E1.v3");

  void set v3(Result value) {
    lastSetter = "E1.v3=$value";
  }

  // No other declarations with same basename.
  Result get v4 => Result("E1.v4");

  void set v4(Result value) {
    lastSetter = "E1.v4=$value";
  }

  // Same basename as E2 setter.
  Result get v5 => Result("E1.v5");
}

/// A different extension than [E1] on [C].
///
/// Declares [v5] setter.
extension E2 on C {
  void set v5(Result value) {
    lastSetter = "E2.v5=$value";
  }
}
