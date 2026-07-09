// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A variable declared by a pattern is in scope in the pattern but can't be
/// used in constant expression inside the pattern.

void testSwitchStatement(int x) {
  switch (x) {
    case var a && == a:
      //             ^
      // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
      // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
      // [cfe] Read of a non-const variable is not a constant expression.
      'error';
    case == b && var b:
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
      // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
      // [cfe] Local variable 'b' can't be referenced before it is declared.
      // [cfe] Undefined name 'b'.
      'error';
  }
}

void testSwitchStatementInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  switch (x) {
    case var a && == a:
      //             ^
      // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
      // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
      // [cfe] Read of a non-const variable is not a constant expression.
      'error';
    case == b && var b:
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
      // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
      // [cfe] Local variable 'b' can't be referenced before it is declared.
      'error';
  }
}

String testSwitchExpression(int x) {
  return switch (x) {
    var a && == a => 'error',
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Read of a non-const variable is not a constant expression.
    == b && var b => 'error',
    // ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Local variable 'b' can't be referenced before it is declared.
    // [cfe] Undefined name 'b'.
    _ => 'other',
  };
}

String testSwitchExpressionInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  return switch (x) {
    var a && == a => 'error',
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Read of a non-const variable is not a constant expression.
    == b && var b => 'error',
    // ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Local variable 'b' can't be referenced before it is declared.
    _ => 'other',
  };
}

void testIfCaseStatement(int x) {
  if (x case var a && == a) {}
  //                     ^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  // [cfe] Read of a non-const variable is not a constant expression.

  if (x case == b && var b) {}
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  // [cfe] Local variable 'b' can't be referenced before it is declared.
  // [cfe] Undefined name 'b'.
}

void testIfCaseStatementInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  if (x case var a && == a) {}
  //                     ^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  // [cfe] Read of a non-const variable is not a constant expression.

  if (x case == b && var b) {}
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  // [cfe] Local variable 'b' can't be referenced before it is declared.
}

List<String> testIfCaseElement(int x) {
  return [
    if (x case var a && == a) 'one',
    //                     ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Read of a non-const variable is not a constant expression.
    if (x case == b && var b) 'two',
    //            ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Local variable 'b' can't be referenced before it is declared.
    // [cfe] Undefined name 'b'.
  ];
}

List<String> testIfCaseElementInScope(int x) {
  const a = 'outer';
  const b = 'outer';

  return [
    if (x case var a && == a) 'one',
    //                     ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Read of a non-const variable is not a constant expression.
    if (x case == b && var b) 'two',
    //            ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    // [cfe] Local variable 'b' can't be referenced before it is declared.
  ];
}
