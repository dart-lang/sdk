// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the proper errors are generated if a declared variable appears
// inside a pattern assignment.

void usingFinal() {
  var x;
  [x, final y] = [0, 1];
  //        ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable 'y' can't be declared in a pattern assignment.
}

void usingFinalAndType() {
  var x;
  [x, final int y] = [0, 1];
  //            ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable 'y' can't be declared in a pattern assignment.
}

void usingType() {
  var x;
  [x, int y] = [0, 1];
  //      ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable 'y' can't be declared in a pattern assignment.
}

void usingVar() {
  var x;
  [x, var y] = [0, 1];
  //      ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable 'y' can't be declared in a pattern assignment.
}

main() {}
