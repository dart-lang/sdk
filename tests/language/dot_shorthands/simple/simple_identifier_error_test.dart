// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Erroneous ways to use shorthands for simple identifiers and const simple
// identifiers.

import '../dot_shorthand_helper.dart';

void main() {
  var color = .blue;
  //          ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //           ^
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  const constColor = .blue;
  //                 ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                  ^
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  var integer = .one;
  //            ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //             ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  const constInteger = .one;
  //                   ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                    ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  Integer i = .one();
  //          ^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
  // [cfe] The method 'call' isn't defined for the type 'Integer'.
}
