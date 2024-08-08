// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on
// tests/language/patterns/switch_expression_using_statement_syntax_error_test.dart

// Test that attempting to use `case`, `default`, `:`, and `;` tokens in a
// switch expression doesn't confuse the parser.

f(x) => switch (x) {
  case 1: 'one'; // Error
  case 2: 'two'; // Error
  default: 'three'; // Error
};
