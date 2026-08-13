// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that errors are generated if an improperly formed wildcard pattern
// appears inside a pattern assignment.

void usingFinal() {
  var x;
  [x, final _] = [0, 1];
  //        ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable '_' can't be declared in a pattern assignment.
}

void usingFinalAndType() {
  var x;
  [x, final int _] = [0, 1];
  //            ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable '_' can't be declared in a pattern assignment.
}

void usingType() {
  var x;
  [x, int _] = [0, 1];
  //      ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable '_' can't be declared in a pattern assignment.
}

void usingVar() {
  var x;
  [x, var _] = [0, 1];
  //      ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable '_' can't be declared in a pattern assignment.
}

main() {}
