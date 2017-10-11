// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test symbol literals.

library symbol_literal_test;

import 'package:expect/expect.dart';

foo(a, b) => Expect.isTrue(identical(a, b));

var check = foo; // Indirection used to avoid inlining.

testSwitch(Symbol s) {
  switch (s) {
    case #abc:
      return 1;
    case const Symbol("def"):
      return 2;
    default:
      return 0;
  }
}

main() {
  check(const Symbol("a"), #a);
  check(const Symbol("a"), #a);
  check(const Symbol("ab"), #ab);
  check(const Symbol("ab"), #ab);
  check(const Symbol("a.b"), #a.b);
  check(const Symbol("a.b"), #a.b);
  check(const Symbol("=="), #==);
  check(const Symbol("=="), #==);
  check(const Symbol("a.toString"), #a.toString);

  Expect.equals(1, testSwitch(#abc));

  const m = const <Symbol, int>{#A: 0, #B: 1};
  Expect.equals(1, m[#B]);

  // Tries to call the symbol literal #a.toString
  Expect.throws(() => #a.toString(), (e) => e is NoSuchMethodError); //# 01: compile-time error
}
