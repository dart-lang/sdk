// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class E {
  static final String a = "get a";
  static void set a(String o) {
    printx("set a: $o");
  }

  static const String b = "get b";
  static void set b(String o) {
    printx("set b: $o");
  }

  static void set c(String o) {
    printx("set c: $o");
  }

  final String d = "get d";
  void set d(String o) {
    printx("set d: $o");
  }

  final String e = "get e";

  static const String f = "get f";

  set g(v) {
    printx("set g: $v");
  }

  set h(v) {
    printx("set h: $v");
  }

  foo() {
    printx(e);
    e = "set e"; // //# 01: compile-time error
    printx(e);

    printx(f);
    f = "set f"; // //# 02: compile-time error
    printx(f);

    printx(g); //   //# 03: compile-time error
    g = "set g";
    printx(g); //   //# 04: compile-time error

    printx(h); //   //# 05: compile-time error
    h = "set h";
    printx(h); //   //# 06: compile-time error
  }
}

set e(v) {
  printx("Setting top-level e: $v");
}

set f(v) {
  printx("Setting top-level f: $v");
}

final String g = "get g";

const String h = "get h";

const x = 42;
final y = 42;

set x(v) {
  printx("Setting top-level x: $v");
}

set y(v) {
  printx("Setting top-level y: $v");
}

main() {
  printx(E.a);
  E.a = "set E";
  printx(E.a);

  printx(E.b);
  E.b = "set E";
  printx(E.b);

  E.c = "set E";

  E eInstance = new E();
  printx(eInstance.d);
  eInstance.d = "set eInstance";
  printx(eInstance.d);
  eInstance.foo();

  printx(e); //     //# 07: compile-time error
  e = "set e";
  printx(e); //     //# 08: compile-time error

  printx(f); //     //# 09: compile-time error
  f = "set f";
  printx(f); //     //# 10: compile-time error

  printx(g);
  g = "set g"; //   //# 11: compile-time error
  printx(g);

  printx(h);
  h = "set h"; //   //# 12: compile-time error
  printx(h);

  printx(x);
  x = "Hello world!";
  printx(x);

  printx(y);
  y = "Hello world!";
  printx(y);

  Expect.listEquals(expected, actual);
}

List<String> actual = <String>[];
void printx(Object x) {
  actual.add(x.toString());
}

List<String> expected = <String>[
  "get a",
  "set a: set E",
  "get a",
  "get b",
  "set b: set E",
  "get b",
  "set c: set E",
  "get d",
  "set d: set eInstance",
  "get d",
  "get e",
  "get e",
  "get f",
  "get f",
  "set g: set g",
  "set h: set h",
  "Setting top-level e: set e",
  "Setting top-level f: set f",
  "get g",
  "get g",
  "get h",
  "get h",
  "42",
  "Setting top-level x: Hello world!",
  "42",
  "42",
  "Setting top-level y: Hello world!",
  "42",
];
