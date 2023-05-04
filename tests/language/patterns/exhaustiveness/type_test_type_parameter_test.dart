// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

// Test that using a type parameter as a type test in a pattern doesn't
// incorrectly use the bound for exhaustiveness.
//
// The bound isn't a correct approximation because the type argument could be
// a subtype of the bound (including `Never`), which will cause the type test
// to match fewer values than the bound.

void test<T extends int>(num value) {
  // Object pattern.
  var result = switch (value) {
    //         ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
    //                 ^
    // [cfe] The type 'num' is not exhaustively matched by the switch cases since it doesn't match 'int()'.
    T() => 'T',
    double() => 'double'
  };

  // Variable type.
  result = switch (value) {
    //     ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
    //             ^
    // [cfe] The type 'num' is not exhaustively matched by the switch cases since it doesn't match 'int()'.
    T _ => 'T',
    double _ => 'double'
  };
}
