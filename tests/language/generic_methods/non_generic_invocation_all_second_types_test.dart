// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that `f<a,EXPR>(x)` is properly parsed as a pair of
// expressions separated by a `,`, for all types of expressions that may appear
// as EXPR that can't be parsed as types.

import '../syntax_helper.dart';

class C extends SyntaxTracker {
  C([Object? x = absent, Object? y = absent])
      : super('new C${SyntaxTracker.args(x, y)}');

  C.syntax(String s) : super(s);

  Object? operator >(Object? other) =>
      SyntaxTracker('(${syntax(this)} > ${syntax(other)})');
}

class ThisTest extends C {
  ThisTest() : super.syntax('this');

  void test() {
    checkSyntax(f(x < C, this > (x)), 'f((x < C), (this > x))');
    // Note: SyntaxTracker can't see the parens around `this` in the line below
    checkSyntax(f(x < C, (this) > (x)), 'f((x < C), (this > x))');
  }
}

class SuperTest extends C {
  SuperTest() : super.syntax('super');

  void test() {
    checkSyntax(f(x < C, super > (x)), 'f((x < C), (super > x))');
  }
}

main() {
  const y = 123;
  SyntaxTracker.known[C] = 'C';
  SyntaxTracker.known[#x] = '#x';
  SyntaxTracker.known[y] = 'y';
  checkSyntax(
      f(x < C, x.getter.getter > (x)), 'f((x < C), (x.getter.getter > x))');
  checkSyntax(f(x < C, C() > (x)), 'f((x < C), (new C() > x))');
  checkSyntax(f(x < C, new C() > (x)), 'f((x < C), (new C() > x))');
  checkSyntax(f(x < C, f() > (x)), 'f((x < C), (f() > x))');
  checkSyntax(f(x < C, x.method() > (x)), 'f((x < C), (x.method() > x))');
  checkSyntax(f(x < C, x[0]() > (x)), 'f((x < C), (x[0]() > x))');
  checkSyntax(f(x < C, #x > (x)), 'f((x < C), (#x > x))');
  checkSyntax(f(x < C, null > (x)), 'f((x < C), (null > x))');
  checkSyntax(f(x < C, 0 > (y)), 'f((x < C), false)');
  checkSyntax(f(x < C, 0.5 > (y)), 'f((x < C), false)');
  checkSyntax(f(x < C, [] > (x)), 'f((x < C), ([] > x))');
  checkSyntax(f(x < C, [0] > (x)), 'f((x < C), ([0] > x))');
  checkSyntax(f(x < C, {} > (x)), 'f((x < C), ({} > x))');
  checkSyntax(f(x < C, {0} > (x)), 'f((x < C), ({0} > x))');
  checkSyntax(f(x < C, {0: 0} > (x)), 'f((x < C), ({ 0: 0 } > x))');
  checkSyntax(f(x < C, true > (x)), 'f((x < C), (true > x))');
  checkSyntax(f(x < C, "s" > (x)), 'f((x < C), ("s" > x))');
  checkSyntax(f(x < C, r"s" > (x)), 'f((x < C), ("s" > x))');
  checkSyntax(f(x < C, x[0] > (x)), 'f((x < C), (x[0] > x))');
  // Note: SyntaxTracker can't see the `!` in the line below
  checkSyntax(f(x < C, x! > (x)), 'f((x < C), (x > x))');
  // Note: SyntaxTracker can't see the parens around `x` in the line below
  checkSyntax(f(x < C, (x) > (x)), 'f((x < C), (x > x))');
  checkSyntax(f(x < C, -x > (x)), 'f((x < C), ((-x) > x))');
  checkSyntax(f(x < C, !true > (x)), 'f((x < C), (false > x))');
  checkSyntax(f(x < C, !(true) > (x)), 'f((x < C), (false > x))');
  checkSyntax(f(x < C, ~x > (x)), 'f((x < C), ((~x) > x))');
  checkSyntax(f(x < C, x * x > (x)), 'f((x < C), ((x * x) > x))');
  checkSyntax(f(x < C, x / x > (x)), 'f((x < C), ((x / x) > x))');
  checkSyntax(f(x < C, x ~/ x > (x)), 'f((x < C), ((x ~/ x) > x))');
  checkSyntax(f(x < C, x % x > (x)), 'f((x < C), ((x % x) > x))');
  checkSyntax(f(x < C, x + x > (x)), 'f((x < C), ((x + x) > x))');
  checkSyntax(f(x < C, x - x > (x)), 'f((x < C), ((x - x) > x))');
  checkSyntax(f(x < C, x << x > (x)), 'f((x < C), ((x << x) > x))');
  checkSyntax(f(x < C, x >> x > (x)), 'f((x < C), ((x >> x) > x))');
  checkSyntax(f(x < C, x & x > (x)), 'f((x < C), ((x & x) > x))');
  checkSyntax(f(x < C, x ^ x > (x)), 'f((x < C), ((x ^ x) > x))');
  checkSyntax(f(x < C, x | x > (x)), 'f((x < C), ((x | x) > x))');
  ThisTest().test();
  SuperTest().test();
}
