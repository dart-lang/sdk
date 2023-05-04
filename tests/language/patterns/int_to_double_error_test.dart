// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

/// Test where a pattern does and does not create a context type that leads to
/// int-to-double conversion.

import "package:expect/expect.dart";

main() {
  // No coercion during runtime destructuring.
  (int, int) record = (1, 2);
  var (double x, double y) = record;
  //   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT
  //          ^
  // [cfe] The matched value of type 'int' isn't assignable to the required type 'double'.
  //             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT
  //                    ^
  // [cfe] The matched value of type 'int' isn't assignable to the required type 'double'.

  // Non-exhaustive since double case doesn't cover uncoerced int type.
  var result = switch (123) {
    //         ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
    //                 ^
    // [cfe] The type 'int' is not exhaustively matched by the switch cases since it doesn't match 'int()'.
    double d => 'wrong'
  };
}
