// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing string interpolation of expressions.

import "package:expect/expect.dart";

class StringInterpolate2Test {
  static var F1;

  static void testMain() {
    F1 = "1 + 5 = ${1+5}";

    Expect.equals("1 + 5 = 6", F1);

    var fib = [1, 1, 2, 3, 5, 8, 13, 21];

    var i = 5;
    var s = "${i}";
    Expect.equals("5", s);

    s = "fib(${i}) = ${fib[i]}";
    Expect.equals("fib(5) = 8", s);

    i = 5;
    s = "$i squared is ${((x) => x*x)(i)}";
    Expect.equals("5 squared is 25", s);

    Expect.equals("8", "${fib.length}");
    // test single quote
    Expect.equals("8", '${fib.length}');
    // test multi-line
    Expect.equals(
        "8",
        '${fib.
    length}');

    var map = {"red": 1, "green": 2, "blue": 3};
    s = "green has value ${map["green"]}";
    Expect.equals("green has value 2", s);

    i = 0;
    b() => "${++i}";
    s = "aaa ${"bbb ${b()} bbb"} aaa ${b()}";
    Expect.equals("aaa bbb 1 bbb aaa 2", s);

    // test multiple levels of nesting, including changing quotes and
    // multiline string types
    s = "a ${(){ return 'b ${(){ return """
c""";}()}'; }()} d";
    Expect.equals("a b c d", s);
  }
}

main() {
  StringInterpolate2Test.testMain();
}
