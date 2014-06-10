// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String FIB = r"""
fib(n) {
  if (n <= 1) return 1;
  return add(fib(n - 1), fib(n - 2));
}

// We need this artificial add method because
// our optimizer will actually add type checks
// for the result of recursively calling fib
// which introduces new variables because we
// now have multiple users.
// The 'if' has been added to avoid inlining of add.
add(x, y) {
  if (x == -1) return x;
  return x + y;
}
""";

const String BAR = r"""
bar() {
  var isLeaf = (bar() != null) && bar();
  // Because we're using a local variable, the graph gets an empty
  // block between the [isLeaf] phi and the next instruction that uses
  // it. The optimizer must take that new block into account in order
  // to have the phi be generate at use uste.
  if (isLeaf) return null;
  return true;
}
""";

// Test that a synthesized [HTypeConversion] node added due to the is
// check is code motion invariant. No 'else' should be generated in
// this code snippet (the new [HTypeConversion] is put in the else
// branch, but the else branch dominates the rest of the code in this
// snippet).
const String TEST = r"""
foo(a) {
  if (a is !int) throw a;
  if (a < 0) throw a;
  return a + a;
}
""";

main() {
  asyncTest(() => Future.wait([
    // Make sure we don't introduce a new variable.
    compileAndDoNotMatch(FIB, 'fib', new RegExp("var $anyIdentifier =")),

    compileAndDoNotMatch(BAR, 'bar', new RegExp("isLeaf")),

    compile(TEST, entry: 'foo', check: (String generated) {
      Expect.isFalse(generated.contains('else'));
      // Regression check to ensure that there is no floating variable
      // expression.
      Expect.isFalse(new RegExp('^[ ]*a;').hasMatch(generated));
    }),
  ]));
}
