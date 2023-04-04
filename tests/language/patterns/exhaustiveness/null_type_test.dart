// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

// Test that a both a Null-typed variable pattern and a `null` literal pattern
// will cover the null part of a nullable type.

void test(int? maybeInt) {
  // OK.
  var result = switch (maybeInt) {
    Null _ => 'null',
    int _ => 'int',
  };

  // OK.
  result = switch (maybeInt) {
    null => 'null',
    int _ => 'int',
  };

  // The two nulls overlap.
  result = switch (maybeInt) {
    null => 'null',
    Null _ => 'null',
//         ^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
    int _ => 'int',
  };

  // The two nulls overlap.
  result = switch (maybeInt) {
    Null _ => 'null',
    null => 'null',
//       ^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
    int _ => 'int',
  };

  // Must cover null somehow.
  result = switch (maybeInt) {
    //     ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
    //             ^
    // [cfe] The type 'int?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    int _ => 'int',
  };
}
