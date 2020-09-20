// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to detect syntactically illegal left-hand-side (assignable)
// expressions.

class C {
  static dynamic field = 0;
}

dynamic variable = 0;

main() {
  variable = 0;
  (variable) = 0;
//^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
//         ^
// [cfe] Can't assign to a parenthesized expression.
  (variable)++;
  //       ^
  // [cfe] Can't assign to a parenthesized expression.
  //        ^^
  // [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
  ++(variable);
  //         ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  // [cfe] Can't assign to a parenthesized expression.

  C.field = 0;
  (C.field) = 0;
//^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
//        ^
// [cfe] Can't assign to a parenthesized expression.
  (C.field)++;
  //      ^
  // [cfe] Can't assign to a parenthesized expression.
  //       ^^
  // [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
  ++(C.field);
  //        ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  // [cfe] Can't assign to a parenthesized expression.

  variable = [1, 2, 3];
  variable[0] = 0;
  (variable)[0] = 0;
  (variable[0]) = 0;
//^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
//            ^
// [cfe] Can't assign to a parenthesized expression.
  (variable[0])++;
  //          ^
  // [cfe] Can't assign to a parenthesized expression.
  //           ^^
  // [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
  ++(variable[0]);
  //            ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  // [cfe] Can't assign to a parenthesized expression.

  C.field = [1, 2, 3];
  (C.field[0]) = 0;
//^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
//           ^
// [cfe] Can't assign to a parenthesized expression.
  (C.field[0])++;
  //         ^
  // [cfe] Can't assign to a parenthesized expression.
  //          ^^
  // [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
  ++(C.field[0]);
  //           ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  // [cfe] Can't assign to a parenthesized expression.

  var a = 0;
  (a) = 0;
//^^^
// [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
//^^^
// [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
//  ^
// [cfe] Can't assign to a parenthesized expression.
  (a)++;
  //^
  // [cfe] Can't assign to a parenthesized expression.
  // ^^
  // [analyzer] SYNTACTIC_ERROR.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
  ++(a);
  //  ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  // [cfe] Can't assign to a parenthesized expression.

  // Neat palindrome expression. x is assignable, ((x)) is not.
  var funcnuf = (x) => ((x))=((x)) <= (x);
  //                   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.MISSING_ASSIGNABLE_SELECTOR
  //                       ^
  // [cfe] Can't assign to a parenthesized expression.
}
