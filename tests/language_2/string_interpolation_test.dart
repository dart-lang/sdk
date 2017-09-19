// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests for string interpolation
class StringInterpolationTest {
  StringInterpolationTest() {}

  static void m() {}

  static const int i = 1;
  static const String a = "<hi>";

  int j;
  int k;

  static testMain(bool alwaysFalse) {
    var test = new StringInterpolationTest();
    test.j = 3;
    test.k = 5;

    // simple string
    Expect.equals(" hi ", " hi ");

    var c1 = '1';
    var c2 = '2';
    var c3 = '3';
    var c4 = '4';
    // no chars before/after/between embedded expressions
    Expect.equals(" 1", " ${c1}");
    Expect.equals("1 ", "${c1} ");
    Expect.equals("1", "${c1}");
    Expect.equals("12", "${c1}${c2}");
    Expect.equals("12 34", "${c1}${c2} ${c3}${c4}");

    // embedding static fields
    Expect.equals(" hi 1 ", " hi ${i} ");
    Expect.equals(" hi <hi> ", " hi ${a} ");

    // embedding method parameters
    Expect.equals("param = 9", test.embedParams(9));

    // embedding a class field
    Expect.equals("j = 3", test.embedSingleField());

    // embedding more than one (non-constant) expression
    Expect.equals(" hi 1 <hi>", " hi ${i} ${a}");
    Expect.equals("j = 3; k = 5", test.embedMultipleFields());

    // escaping $ - doesn't start the embedded expression
    Expect.equals("\$", "escaped     \${3+2}"[12]);
    Expect.equals("{", "escaped     \${3+2}"[13]);
    Expect.equals("3", "escaped     \${3+2}"[14]);
    Expect.equals("+", "escaped     \${3+2}"[15]);
    Expect.equals("2", "escaped     \${3+2}"[16]);
    Expect.equals("}", "escaped     \${3+2}"[17]);

    if (alwaysFalse) {
      "${i.toHorse()}"; //# 01: compile-time error
    }

    Expect.equals("${m}", "$m");
  }

  String embedParams(int z) {
    return "param = ${z}";
  }

  String embedSingleField() {
    return "j = ${j}";
  }

  String embedMultipleFields() {
    return "j = ${j}; k = ${k}";
  }
}

main() {
  StringInterpolationTest.testMain(false);
}
