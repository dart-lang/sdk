// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous usages of variance in unapplicable type parameters.

// SharedOptions=--enable-experiment=variance

void A(out int foo) {
//     ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] 'out' isn't a type.
//     ^
// [cfe] Type 'out' not found.
//             ^^^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ')' before this.
  List<out String> bar;
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '<' isn't defined for the class 'Type'.
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Expected ';' after this.
  //   ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Getter not found: 'out'.
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '>' isn't defined for the class 'Type'.
  //               ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Getter not found: 'bar'.
}

void B(out foo) {}
//     ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] 'out' isn't a type.
//     ^
// [cfe] Type 'out' not found.

class C<in out X, out out Y> {}
//         ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//                    ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.

class D<in out inout in out X> {}
//         ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//             ^^^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//                   ^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.
//                      ^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_VARIANCE_MODIFIERS
// [cfe] Each type parameter can have at most one variance modifier.

typedef E<out T> = T Function(T a);
//            ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
// [cfe] Expected ',' before this.
