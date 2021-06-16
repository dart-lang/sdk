// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test verifies that `f<a,b>EXPR` is properly parsed as a pair of
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
    checkSyntax(f(x < C, C > this), 'f((x < C), (C > this))');
  }
}

main() {
  SyntaxTracker.known[C] = 'C';
  SyntaxTracker.known[#x] = '#x';
  checkSyntax(f(x < C, C > x), 'f((x < C), (C > x))');
  checkSyntax(f(x < C, C > x.getter), 'f((x < C), (C > x.getter))');
  checkSyntax(f(x < C, C > C()), 'f((x < C), (C > new C()))');
  checkSyntax(f(x < C, C > new C()), 'f((x < C), (C > new C()))');
  checkSyntax(f(x < C, C > f()), 'f((x < C), (C > f()))');
  checkSyntax(f(x < C, C > x.method()), 'f((x < C), (C > x.method()))');
  checkSyntax(f(x < C, C > x[0]()), 'f((x < C), (C > x[0]()))');
  checkSyntax(f(x < C, C > #x), 'f((x < C), (C > #x))');
  checkSyntax(f(x < C, C > null), 'f((x < C), (C > null))');
  checkSyntax(f(x < C, C > 0), 'f((x < C), (C > 0))');
  checkSyntax(f(x < C, C > 0.5), 'f((x < C), (C > 0.5))');
  checkSyntax(f(x < C, C > []), 'f((x < C), (C > []))');
  checkSyntax(f(x < C, C > [0]), 'f((x < C), (C > [0]))');
  checkSyntax(f(x < C, C > {}), 'f((x < C), (C > {}))');
  checkSyntax(f(x < C, C > {0}), 'f((x < C), (C > {0}))');
  checkSyntax(f(x < C, C > {0: 0}), 'f((x < C), (C > { 0: 0 }))');
  checkSyntax(f(x < C, C > true), 'f((x < C), (C > true))');
  checkSyntax(f(x < C, C > "s"), 'f((x < C), (C > "s"))');
  checkSyntax(f(x < C, C > r"s"), 'f((x < C), (C > "s"))');
  checkSyntax(f(x < C, C > x[0]), 'f((x < C), (C > x[0]))');
  checkSyntax(f(x < C, C > -x), 'f((x < C), (C > (-x)))');
  checkSyntax(f(x < C, C > !true), 'f((x < C), (C > false))');
  checkSyntax(f(x < C, C > !(true)), 'f((x < C), (C > false))');
  checkSyntax(f(x < C, C > ~x), 'f((x < C), (C > (~x)))');
  checkSyntax(f(x < C, C > x * x), 'f((x < C), (C > (x * x)))');
  checkSyntax(f(x < C, C > x / x), 'f((x < C), (C > (x / x)))');
  checkSyntax(f(x < C, C > x ~/ x), 'f((x < C), (C > (x ~/ x)))');
  checkSyntax(f(x < C, C > x % x), 'f((x < C), (C > (x % x)))');
  checkSyntax(f(x < C, C > x + x), 'f((x < C), (C > (x + x)))');
  checkSyntax(f(x < C, C > x - x), 'f((x < C), (C > (x - x)))');
  checkSyntax(f(x < C, C > x << x), 'f((x < C), (C > (x << x)))');
  checkSyntax(f(x < C, C > x >> x), 'f((x < C), (C > (x >> x)))');
  checkSyntax(f(x < C, C > x & x), 'f((x < C), (C > (x & x)))');
  checkSyntax(f(x < C, C > x ^ x), 'f((x < C), (C > (x ^ x)))');
  checkSyntax(f(x < C, C > x | x), 'f((x < C), (C > (x | x)))');
  ThisTest().test();
}
