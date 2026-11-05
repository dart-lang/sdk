// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with `ExtensionOverride ==` and
// `ExtensionOverride !=`.

extension E on int {}

class C {
  static const member = C();
  static C method() => C();
  const C();
  const C.named();
}

void test() {
  E(0) == .member;
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'member'.
  E(0) != .member;
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'member'.

  E(0) == .method();
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'method'.
  E(0) != .method();
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'method'.

  E(0) == .named();
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'named'.
  E(0) != .named();
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'named'.

  E(0) == .new();
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'new'.
  E(0) != .new();
  // [error column 3]
  // [cfe] Explicit extension application cannot be used as an expression.
  //   ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_EXTENSION_OPERATOR
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'new'.
}
