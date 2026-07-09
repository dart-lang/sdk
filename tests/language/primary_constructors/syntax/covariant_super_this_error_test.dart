// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if the formal parameter contains a term of the
// form `this.v`, or `super.v` where `v` is an identifier, and the parameter has
// the modifier `covariant`.

// `covariant` with `this.x`

// In-header declaring constructor
class C1(covariant this.x) {
  //     ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
  // [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
  int x;
}


class C2({covariant this.x}) {
  //      ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
  // [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
  int? x;
}

class C3({required covariant this.x}) {
  //               ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
  // [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
  int x;
}

class C4([covariant this.x]) {
  //      ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
  // [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
  int? x;
}

// `covariant` with `super.x`

class A(final int? x);

// In-header declaring constructor
class C9(covariant super.x) extends A;
//       ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.

class C10({covariant super.x}) extends A;
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS
//         ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
//                         ^
// [analyzer] COMPILE_TIME_ERROR.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED
// [cfe] The super constructor has no corresponding named parameter.

class C11({required covariant super.x}) extends A;
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS
//                  ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
//                                  ^
// [analyzer] COMPILE_TIME_ERROR.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED
// [cfe] The super constructor has no corresponding named parameter.

class C12([covariant super.x]) extends A;
//         ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.
