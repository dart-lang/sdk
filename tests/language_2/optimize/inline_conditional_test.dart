// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js. There was a bug in the variable
// allocator when a pure (side-effect free) instruction stand
// in-between an inlined `if` and its inlined expression.

import "package:expect/expect.dart";

var topLevel;

// Make [foo] an inlineable expression with a return type check.
Function foo(c) {
  // Use [c] twice to make sure it is stored in a local.
  return (c is Function ? null : c);
}

bar() {
  var b = new Object();
  f() {
    // Inside a closure, locals that escape are stored in a closure
    // class. By using [b] in both branches, the optimizers will move
    // the fetching of [b] before the `if`. This puts the fetching
    // instruction in between the `if` and the expression of the `if`.
    // This instruction being pure, the variable allocator was dealing
    // with it in a special way.
    //
    // Because the expression in the `if` is being recognized by the
    // optimizers as being also a JavaScript expression, we do not
    // allocate a name for it. But some expressions that it uses still
    // can have a name, and our variable allocator did not handle live
    // variables due to the inlining of the ternary expression in [foo].
    if (foo(topLevel) == null) {
      return b.toString();
    } else {
      return b.hashCode;
    }
  }

  return f();
}

main() {
  // Make sure the inferrer does not get an exact type for [topLevel].
  topLevel = new Object();
  topLevel = main;
  var res = bar();
  Expect.isTrue(res is String);
}
