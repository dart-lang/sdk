// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the proper errors are generated if both `var` and a type are used
// in a wildcard pattern.

void inAssignmentContext() {
  // No need for a separate error here, since it's already illegal for a
  // wildcard pattern using `var` and/or a type to appear in an assignment
  // context.
  var x;
  [x, var int _] = [0, 1];
  //          ^
  // [analyzer] SYNTACTIC_ERROR.PATTERN_ASSIGNMENT_DECLARES_VARIABLE
  // [cfe] Variable '_' can't be declared in a pattern assignment.
}

void inDeclarationContext() {
  // No need for a separate error here, since it's already illegal for `var` to
  // appear in a declaration context.
  var [var int _] = [0];
  //   ^^^
  // [analyzer] SYNTACTIC_ERROR.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT
  // [cfe] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}

void inMatchingContext() {
  if ([0] case [var int _]) {}
  //            ^^^
  // [analyzer] SYNTACTIC_ERROR.VAR_AND_TYPE
  // [cfe] Variables can't be declared using both 'var' and a type name.
}

main() {}
