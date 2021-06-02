// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test verifies that `EXPR<a,b>-x` is properly parsed as a pair of
// expressions separated by a `,`, for all types of expressions that may appear
// as EXPR.  We try to pay extra attention to expressions that will become
// ambiguous when the "constructor tearoffs" feature is enabled (that is, where
// interpreting the `<` and `>` as delimiting a list of type arguments would
// also have led to a valid parse).

import '../syntax_helper.dart';

class C extends SyntaxTracker {
  C([Object x = absent, Object y = absent])
      : super('new C${SyntaxTracker.args(x, y)}');

  C.syntax(String s) : super(s);

  Object operator <(Object other) =>
      SyntaxTracker('(${syntax(this)} < ${syntax(other)})');
}

class ThisTest extends C {
  ThisTest() : super.syntax('this');

  void test() {
    checkSyntax(f(this < C, C > -x), 'f((this < C), (C > (-x)))');
    // Note: SyntaxTracker can't see the parens around `this` in the line below
    checkSyntax(f((this) < C, C > -x), 'f((this < C), (C > (-x)))');
  }
}

class SuperTest extends C {
  SuperTest() : super.syntax('super');

  void test() {
    checkSyntax(f(super < C, C > -x), 'f((super < C), (C > (-x)))');
  }
}

main() {
  const y = 123;
  SyntaxTracker.known[C] = 'C';
  SyntaxTracker.known[#x] = '#x';
  SyntaxTracker.known[y] = 'y';
  checkSyntax(f(x < C, C > -x), 'f((x < C), (C > (-x)))');
  checkSyntax(f(x.getter < C, C > -x), 'f((x.getter < C), (C > (-x)))');
  checkSyntax(f(C() < C, C > -x), 'f((new C() < C), (C > (-x)))');
  checkSyntax(f(new C() < C, C > -x), 'f((new C() < C), (C > (-x)))');
  checkSyntax(f(f() < C, C > -x), 'f((f() < C), (C > (-x)))');
  checkSyntax(f(x.method() < C, C > -x), 'f((x.method() < C), (C > (-x)))');
  checkSyntax(f(x[0]() < C, C > -x), 'f((x[0]() < C), (C > (-x)))');
  checkSyntax(f(#x < C, C > -x), 'f((#x < C), (C > (-x)))');
  checkSyntax(f(null < C, C > -x), 'f((null < C), (C > (-x)))');
  checkSyntax(f(0 < y, C > -x), 'f(true, (C > (-x)))');
  checkSyntax(f(0.5 < y, C > -x), 'f(true, (C > (-x)))');
  checkSyntax(f([] < C, C > -x), 'f(([] < C), (C > (-x)))');
  checkSyntax(f([0] < C, C > -x), 'f(([0] < C), (C > (-x)))');
  checkSyntax(f({} < C, C > -x), 'f(({} < C), (C > (-x)))');
  checkSyntax(f({0} < C, C > -x), 'f(({0} < C), (C > (-x)))');
  checkSyntax(f({0: 0} < C, C > -x), 'f(({ 0: 0 } < C), (C > (-x)))');
  checkSyntax(f(true < C, C > -x), 'f((true < C), (C > (-x)))');
  checkSyntax(f("s" < C, C > -x), 'f(("s" < C), (C > (-x)))');
  checkSyntax(f(r"s" < C, C > -x), 'f(("s" < C), (C > (-x)))');
  checkSyntax(f(x[0] < C, C > -x), 'f((x[0] < C), (C > (-x)))');
  // Note: SyntaxTracker can't see the parens around `x` in the line below
  checkSyntax(f((x) < C, C > -x), 'f((x < C), (C > (-x)))');
  checkSyntax(f(-x < C, C > -x), 'f(((-x) < C), (C > (-x)))');
  checkSyntax(f(!true < C, C > -x), 'f((false < C), (C > (-x)))');
  checkSyntax(f(!(true) < C, C > -x), 'f((false < C), (C > (-x)))');
  checkSyntax(f(~x < C, C > -x), 'f(((~x) < C), (C > (-x)))');
  checkSyntax(f(x * x < C, C > -x), 'f(((x * x) < C), (C > (-x)))');
  checkSyntax(f(x / x < C, C > -x), 'f(((x / x) < C), (C > (-x)))');
  checkSyntax(f(x ~/ x < C, C > -x), 'f(((x ~/ x) < C), (C > (-x)))');
  checkSyntax(f(x % x < C, C > -x), 'f(((x % x) < C), (C > (-x)))');
  checkSyntax(f(x + x < C, C > -x), 'f(((x + x) < C), (C > (-x)))');
  checkSyntax(f(x - x < C, C > -x), 'f(((x - x) < C), (C > (-x)))');
  checkSyntax(f(x << x < C, C > -x), 'f(((x << x) < C), (C > (-x)))');
  checkSyntax(f(x >> x < C, C > -x), 'f(((x >> x) < C), (C > (-x)))');
  checkSyntax(f(x & x < C, C > -x), 'f(((x & x) < C), (C > (-x)))');
  checkSyntax(f(x ^ x < C, C > -x), 'f(((x ^ x) < C), (C > (-x)))');
  checkSyntax(f(x | x < C, C > -x), 'f(((x | x) < C), (C > (-x)))');
  ThisTest().test();
  SuperTest().test();
}
