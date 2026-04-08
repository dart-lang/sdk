// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

// This test confirms that compile-time errors specific to the
// 'anonymous-methods' feature are emitted as expected.

void main() {
  // Zero parameters.
  1.() {};
//  ^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // Multiple parameters.
  1.(a, b) {};
//  ^^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // An optional positional parameter.
  1.([a]) {};
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // An optional named parameter.
  1.({a}) {};
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // A required named parameter.
  1.({required a}) {};
//  ^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // A parameter type mismatch.
  "".(int i) {};
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_TYPE
// [cfe] The receiver type 'String' must be assignable to the formal parameter type 'int' of an anonymous method.

  // Break outside of loop/switch.
  1.{
    break;
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.BREAK_OUTSIDE_OF_LOOP
// [cfe] A break statement can't be used outside of a loop or switch statement.
  };

  // Continue outside of loop.
  1.{
    continue;
//  ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.CONTINUE_OUTSIDE_OF_LOOP
// [cfe] A continue statement can't be used outside of a loop or switch statement.
  };
}
