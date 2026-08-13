// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the proper errors are generated if a declared variable appears
// inside a pattern assignment.

void usingFinal() {
  var [final y] = [0];
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT
  // [cfe] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}

void usingFinalAndType() {
  var [final int y] = [0, 1];
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT
  // [cfe] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}

void usingVar() {
  var [var y] = [0, 1];
  //   ^^^
  // [analyzer] SYNTACTIC_ERROR.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT
  // [cfe] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}

main() {}
