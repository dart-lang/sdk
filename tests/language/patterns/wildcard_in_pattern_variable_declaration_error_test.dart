// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that errors are generated if an improperly formed wildcard pattern
// appears inside a pattern variable declaration statement.

void usingFinal() {
  var [x, final _] = [0, 1];
  //      ^^^^^
  // [analyzer] SYNTACTIC_ERROR.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT
  // [cfe] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}

void usingFinalAndType() {
  var [x, final int _] = [0, 1];
  //      ^^^^^
  // [analyzer] SYNTACTIC_ERROR.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT
  // [cfe] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}

void usingVar() {
  var [x, var _] = [0, 1];
  //      ^^^
  // [analyzer] SYNTACTIC_ERROR.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT
  // [cfe] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}

main() {}
