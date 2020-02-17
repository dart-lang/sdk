// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that the new rules for falling over the last statement in a
// case block is detected using flow analysis rather than a pre-determined list
// of statements that should terminate the block.  The new rules can be found at
// the following link:
// https://github.com/dart-lang/language/blob/master/accepted/future-releases/nnbd/feature-specification.md#errors-and-warnings

bar() {}

foo(int x, bool b) {
  switch (x) {
    // The only statement in the following case block doesn't complete normally
    // for any of its possible execution paths, so it's not a compile-time
    // error, even though the statement is not one of the list of statement that
    // should end any case block in pre-NNBD state.
    case 42:
      b ? throw "hest" : throw "fisk";

    // The following is still an error -- the statement completes normally.
    case -42: // Error.
      bar();

    // The following is not an error -- it's the last block in the switch
    // statement.
    default:
      bar();
  }
}
 
abstract class A {
  foo(int x, bool b) {
    switch (x) {
      // The following is not an error -- the expression in the only expression
      // statement of the following case block is of type Never, so it doesn't
      // complete normally.
      case 42:
        neverReturn();

      default:
        bar();
    }
  }

  Never neverReturn();
}

main() {}
