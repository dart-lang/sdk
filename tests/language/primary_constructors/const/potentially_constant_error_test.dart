// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if a class, mixin class, enum, or extension type
// declaration has a constant generative constructor, and a non-late instance
// variable declaration in the body of the declaration has an initializing
// expression which is not potentially constant.
//
// A compile-time error also occurs if the body of a declaration contains a
// body part for the primary constructor, and it has an initializer list, and
// the initializer list contains an expression which is not potentially
// constant.

// SharedOptions=--enable-experiment=primary-constructors

int fn(int x) => x;

class const C(int p) {
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST
  // TODO(cfe): Avoid having multiple errors here and make sure the error
  // message is accurate. i.e. "Not a potentially constant expression."
  final int x = fn(p);
  //            ^
  // [cfe] unspecified
}

class const C2(int p) {
  final int y;
  this : y = fn(p);
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Method invocation is not a constant expression.
}

enum const E(int p) {
//   ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST
  e(1);

  final int x = fn(p);
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  // [cfe] Static invocation is not a constant expression.
}

extension type const Ext(int p) {
  this : assert(fn(p) > 0);
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Method invocation is not a constant expression.
}

// A compile-time error occurs if the result of substituting actual arguments of
// the constructor invocation into one of the above mentioned initializing
// expressions or initializer list elements yields an expression which is not
// constant.

class const A(dynamic d) {
  // TODO(cfe): Avoid having multiple errors here and make sure the error
  // message is accurate. i.e. "Not a potentially constant expression."
  final int i = d.length;
  //            ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_PROPERTY_ACCESS
  // [cfe] unspecified
}

void main() {
  const A([]); // Error because `[].length` isn't constant.
}
