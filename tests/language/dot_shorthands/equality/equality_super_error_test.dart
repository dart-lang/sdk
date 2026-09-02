// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with `super ==` and `super !=`.

class SuperClass {
  const SuperClass();
}

class SubClass extends SuperClass {
  static const member = SubClass();
  static SubClass method() => SubClass();
  const SubClass();
  const SubClass.named();

  void test() {
    super == .member;
    //       ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'member'.
    super != .member;
    //       ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'member'.

    super == .method();
    //       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'method'.
    super != .method();
    //       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'method'.

    super == .named();
    //       ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'named'.
    super != .named();
    //       ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'named'.

    super == .new();
    //       ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'new'.
    super != .new();
    //       ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //        ^
    // [cfe] No type was provided to find the dot shorthand 'new'.
  }
}
