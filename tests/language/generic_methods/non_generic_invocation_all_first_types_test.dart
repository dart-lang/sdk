// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that `f<EXPR,b>(x)` is properly parsed as a pair of
// expressions separated by a `,`, for all types of expressions that may appear
// as EXPR that can't be parsed as types.

import '../syntax_helper.dart';

class C extends SyntaxTracker {
  C([Object? x = absent, Object? y = absent])
      : super('new C${SyntaxTracker.args(x, y)}');

  C.syntax(String s) : super(s);
}

class ThisTest extends C {
  ThisTest() : super.syntax('this');

  void test() {
    checkSyntax(f(x < this, C > (x)), 'f((x < this), (C > x))');
    // Note: SyntaxTracker can't see the parens around `this` in the line below
    checkSyntax(f(x < (this), C > (x)), 'f((x < this), (C > x))');
  }
}

main() {
  SyntaxTracker.known[C] = 'C';
  SyntaxTracker.known[#x] = '#x';
  checkSyntax(
      f(x < x.getter.getter, C > (x)), 'f((x < x.getter.getter), (C > x))');
  checkSyntax(f(x < C(), C > (x)), 'f((x < new C()), (C > x))');
  checkSyntax(f(x < new C(), C > (x)), 'f((x < new C()), (C > x))');
  checkSyntax(f(x < f(), C > (x)), 'f((x < f()), (C > x))');
  checkSyntax(f(x < x.method(), C > (x)), 'f((x < x.method()), (C > x))');
  checkSyntax(f(x < x[0](), C > (x)), 'f((x < x[0]()), (C > x))');
  checkSyntax(f(x < #x, C > (x)), 'f((x < #x), (C > x))');
  checkSyntax(f(x < null, C > (x)), 'f((x < null), (C > x))');
  checkSyntax(f(x < 0, C > (x)), 'f((x < 0), (C > x))');
  checkSyntax(f(x < 0.5, C > (x)), 'f((x < 0.5), (C > x))');
  checkSyntax(f(x < [], C > (x)), 'f((x < []), (C > x))');
  checkSyntax(f(x < [0], C > (x)), 'f((x < [0]), (C > x))');
  checkSyntax(f(x < {}, C > (x)), 'f((x < {}), (C > x))');
  checkSyntax(f(x < {0}, C > (x)), 'f((x < {0}), (C > x))');
  checkSyntax(f(x < {0: 0}, C > (x)), 'f((x < { 0: 0 }), (C > x))');
  checkSyntax(f(x < true, C > (x)), 'f((x < true), (C > x))');
  checkSyntax(f(x < "s", C > (x)), 'f((x < "s"), (C > x))');
  checkSyntax(f(x < r"s", C > (x)), 'f((x < "s"), (C > x))');
  checkSyntax(f(x < x[0], C > (x)), 'f((x < x[0]), (C > x))');
  // Note: SyntaxTracker can't see the `!` in the line below
  checkSyntax(f(x < x!, C > (x)), 'f((x < x), (C > x))');
  // Note: SyntaxTracker can't see the parens around `x` in the line below
  checkSyntax(f(x < (x), C > (x)), 'f((x < x), (C > x))');
  checkSyntax(f(x < -x, C > (x)), 'f((x < (-x)), (C > x))');
  checkSyntax(f(x < !true, C > (x)), 'f((x < false), (C > x))');
  checkSyntax(f(x < !(true), C > (x)), 'f((x < false), (C > x))');
  checkSyntax(f(x < ~x, C > (x)), 'f((x < (~x)), (C > x))');
  checkSyntax(f(x < x * x, C > (x)), 'f((x < (x * x)), (C > x))');
  checkSyntax(f(x < x / x, C > (x)), 'f((x < (x / x)), (C > x))');
  checkSyntax(f(x < x ~/ x, C > (x)), 'f((x < (x ~/ x)), (C > x))');
  checkSyntax(f(x < x % x, C > (x)), 'f((x < (x % x)), (C > x))');
  checkSyntax(f(x < x + x, C > (x)), 'f((x < (x + x)), (C > x))');
  checkSyntax(f(x < x - x, C > (x)), 'f((x < (x - x)), (C > x))');
  checkSyntax(f(x < x << x, C > (x)), 'f((x < (x << x)), (C > x))');
  checkSyntax(f(x < x >> x, C > (x)), 'f((x < (x >> x)), (C > x))');
  checkSyntax(f(x < x & x, C > (x)), 'f((x < (x & x)), (C > x))');
  checkSyntax(f(x < x ^ x, C > (x)), 'f((x < (x ^ x)), (C > x))');
  checkSyntax(f(x < x | x, C > (x)), 'f((x < (x | x)), (C > x))');
  ThisTest().test();
}
