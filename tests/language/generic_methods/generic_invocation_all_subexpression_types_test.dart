// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that `EXPR<typeArguments>(arguments)` is properly parsed
// as a generic invocation, for all types of expressions that may appear as
// EXPR.  We try to pay extra attention to ambiguous expressions (that is, where
// interpreting the `<` and `>` as operators would also have led to a valid
// parse).

import '../syntax_helper.dart';

class C extends SyntaxTracker {
  C([Object? x = absent, Object? y = absent])
      : super('new C${SyntaxTracker.args(x, y)}');

  C.syntax(String s) : super(s);
}

class ThisTest extends C {
  ThisTest() : super.syntax('this');

  void test() {
    checkSyntax(f(this<C, C>(0)), 'f(this<C, C>(0))');
    // Note: SyntaxTracker can't see the parens around `this` in the line below
    checkSyntax(f((this)<C, C>(0)), 'f(this<C, C>(0))');
  }
}

main() {
  SyntaxTracker.known[C] = 'C';
  SyntaxTracker.known[#x] = '#x';
  checkSyntax(f(f<C, C>(0)), 'f(f<C, C>(0))');
  checkSyntax(f(x.method<C, C>(0)), 'f(x.method<C, C>(0))');
  checkSyntax(f(C()<C, C>(0)), 'f(new C()<C, C>(0))');
  checkSyntax(f(new C()<C, C>(0)), 'f(new C()<C, C>(0))');
  checkSyntax(f(f()<C, C>(0)), 'f(f()<C, C>(0))');
  checkSyntax(f(x.method()<C, C>(0)), 'f(x.method()<C, C>(0))');
  checkSyntax(f(x[0]()<C, C>(0)), 'f(x[0]()<C, C>(0))');
  checkSyntax(f(#x<C, C>(0)), 'f(#x<C, C>(0))');
  checkSyntax(f(null<C, C>(0)), 'f(null<C, C>(0))');
  checkSyntax(f(0<C, C>(0)), 'f(0<C, C>(0))');
  checkSyntax(f(0.5<C, C>(0)), 'f(0.5<C, C>(0))');
  checkSyntax(f([]<C, C>(0)), 'f([]<C, C>(0))');
  checkSyntax(f([0]<C, C>(0)), 'f([0]<C, C>(0))');
  checkSyntax(f({}<C, C>(0)), 'f({}<C, C>(0))');
  checkSyntax(f({0}<C, C>(0)), 'f({0}<C, C>(0))');
  checkSyntax(f({0: 0}<C, C>(0)), 'f({ 0: 0 }<C, C>(0))');
  checkSyntax(f(true<C, C>(0)), 'f(true<C, C>(0))');
  checkSyntax(f("s"<C, C>(0)), 'f("s"<C, C>(0))');
  checkSyntax(f(r"s"<C, C>(0)), 'f("s"<C, C>(0))');
  checkSyntax(f(x[0]<C, C>(0)), 'f(x[0]<C, C>(0))');
  // Note: SyntaxTracker can't see the `!` in the line below
  checkSyntax(f(x!<C, C>(0)), 'f(x<C, C>(0))');
  // Note: SyntaxTracker can't see the parens around `x` in the line below
  checkSyntax(f((x)<C, C>(0)), 'f(x<C, C>(0))');
  ThisTest().test();
}
