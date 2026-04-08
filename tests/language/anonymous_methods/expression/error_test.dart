// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

// This test confirms that compile-time errors specific to the
// 'anonymous-methods' feature are emitted as expected.

void main() {
  // Zero parameters.
  1.() => 1;
//  ^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // Multiple parameters.
  1.(a, b) => 1;
//  ^^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // An optional positional parameter.
  1.([a]) => 1;
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // An optional named parameter.
  1.({a}) => 1;
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // A required named parameter.
  1.({required a}) => 1;
//  ^^^^^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_LIST
// [cfe] An anonymous method with a parameter list must have exactly one required, positional parameter.

  // A parameter type mismatch.
  "".(int i) => 1;
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.ANONYMOUS_METHOD_WRONG_PARAMETER_TYPE
// [cfe] The receiver type 'String' must be assignable to the formal parameter type 'int' of an anonymous method.
}
