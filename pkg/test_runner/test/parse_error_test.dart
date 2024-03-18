// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;
import 'package:test_runner/src/command_output.dart';
import 'package:test_runner/src/static_error.dart';

void _checkError(StaticError error,
    {required String path,
    required int line,
    required int column,
    required String message}) {
  Expect.equals(p.relative(path, from: Directory.current.path), error.path);
  Expect.equals(line, error.line);
  Expect.equals(column, error.column);
  Expect.equals(message, error.message);
}

void main() {
  // TODO(55202): Add general testing of CFE and analyzer error parsing.
  testCfeErrors();
  testDart2jsCompilerErrors();
  testDart2WasmCompilerErrors();
  testDevCompilerErrors();
}

void testCfeErrors() {
  _testMultipleCfeErrors();
}

/// Regression test for parsing multiple errors.
void _testMultipleCfeErrors() {
  var errors = <StaticError>[];
  var warnings = <StaticError>[];
  FastaCommandOutput.parseErrors('''
tests/language/explicit_type_instantiation_parsing_test.dart:171:26: Error: Cannot access static member on an instantiated generic class.
Try removing the type arguments or placing them after the member name.
  expect1<Class>(Z<X, X>.instance);
                         ^^^^^^^^
tests/language/explicit_type_instantiation_parsing_test.dart:232:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<2>(2);
     ^
tests/language/explicit_type_instantiation_parsing_test.dart:236:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<2>;
     ^
tests/language/explicit_type_instantiation_parsing_test.dart:236:7: Error: Expected an identifier, but got ';'.
Try inserting an identifier before ';'.
  X<2>;
      ^
tests/language/explicit_type_instantiation_parsing_test.dart:242:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<2>.instance; // Not type argument.
     ^
tests/language/explicit_type_instantiation_parsing_test.dart:242:7: Error: Expected an identifier, but got '.'.
Try inserting an identifier before '.'.
  X<2>.instance; // Not type argument.
      ^
tests/language/explicit_type_instantiation_parsing_test.dart:248:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<2>.any;
     ^
tests/language/explicit_type_instantiation_parsing_test.dart:248:7: Error: Expected an identifier, but got '.'.
Try inserting an identifier before '.'.
  X<2>.any;
      ^
tests/language/explicit_type_instantiation_parsing_test.dart:255:8: Error: Member not found: 'any'.
  X<X>.any; // Invalid, Class does not have any static `any` member.
       ^^^
tests/language/explicit_type_instantiation_parsing_test.dart:259:8: Error: Cannot access static member on an instantiated generic class.
Try removing the type arguments or placing them after the member name.
  X<X>.instance; // Does have static `instance` member, can't access this way.
       ^^^^^^^^
tests/language/explicit_type_instantiation_parsing_test.dart:265:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<X>2;
     ^
tests/language/explicit_type_instantiation_parsing_test.dart:272:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<X>-1;
     ^
tests/language/explicit_type_instantiation_parsing_test.dart:277:7: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  f1<X> - 1;
      ^
tests/language/explicit_type_instantiation_parsing_test.dart:207:12: Warning: Operand of null-aware operation '!' has type 'Type' which excludes null.
 - 'Type' is from 'dart:core'.
  expect1((Z<X, X>)![1].asBool);  // ignore: unnecessary_non_null_assertion
           ^
''', errors, warnings);

  var path = 'tests/language/explicit_type_instantiation_parsing_test.dart';

  Expect.equals(13, errors.length);
  Expect.equals(1, warnings.length);

  _checkError(errors[0],
      path: path,
      line: 171,
      column: 26,
      message: "Cannot access static member on an instantiated generic class.");

  _checkError(errors[1],
      path: path,
      line: 232,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");

  _checkError(errors[2],
      path: path,
      line: 236,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");

  _checkError(errors[3],
      path: path,
      line: 236,
      column: 7,
      message: "Expected an identifier, but got ';'.");

  _checkError(errors[4],
      path: path,
      line: 242,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");

  _checkError(errors[5],
      path: path,
      line: 242,
      column: 7,
      message: "Expected an identifier, but got '.'.");

  _checkError(errors[6],
      path: path,
      line: 248,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");

  _checkError(errors[7],
      path: path,
      line: 248,
      column: 7,
      message: "Expected an identifier, but got '.'.");

  _checkError(errors[8],
      path: path, line: 255, column: 8, message: "Member not found: 'any'.");

  _checkError(errors[9],
      path: path,
      line: 259,
      column: 8,
      message: "Cannot access static member on an instantiated generic class.");

  _checkError(errors[10],
      path: path,
      line: 265,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");

  _checkError(errors[11],
      path: path,
      line: 272,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");

  _checkError(errors[12],
      path: path,
      line: 277,
      column: 7,
      message:
          "A comparison expression can't be an operand of another comparison expression.");

  _checkError(warnings[0],
      path: path,
      line: 207,
      column: 12,
      message:
          "Operand of null-aware operation '!' has type 'Type' which excludes null.");
}

void testDart2jsCompilerErrors() {
  _testMultipleDart2jsCompilerErrors();
}

void _testMultipleDart2jsCompilerErrors() {
  var errors = <StaticError>[];
  Dart2jsCompilerCommandOutput.parseErrors('''
tests/language/explicit_type_instantiation_parsing_test.dart:171:26:
Error: Cannot access static member on an instantiated generic class.
Try removing the type arguments or placing them after the member name.
  expect1<Class>(Z<X, X>.instance);
                         ^^^^^^^^
tests/language/explicit_type_instantiation_parsing_test.dart:232:6:
Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<2>(2);
     ^
''', errors);

  var path = 'tests/language/explicit_type_instantiation_parsing_test.dart';

  Expect.equals(2, errors.length);

  _checkError(errors[0],
      path: path,
      line: 171,
      column: 26,
      message: "Cannot access static member on an instantiated generic class.");

  _checkError(errors[1],
      path: path,
      line: 232,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");
}

void testDart2WasmCompilerErrors() {
  _testMultipleDart2WasmCompilerErrors();
}

void _testMultipleDart2WasmCompilerErrors() {
  var errors = <StaticError>[];
  Dart2WasmCompilerCommandOutput.parseErrors('''
tests/language/explicit_type_instantiation_parsing_test.dart:171:26: Error: Cannot access static member on an instantiated generic class.
Try removing the type arguments or placing them after the member name.
  expect1<Class>(Z<X, X>.instance);
                         ^^^^^^^^
tests/language/explicit_type_instantiation_parsing_test.dart:232:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<2>(2);
     ^
''', errors);

  var path = 'tests/language/explicit_type_instantiation_parsing_test.dart';

  Expect.equals(2, errors.length);

  _checkError(errors[0],
      path: path,
      line: 171,
      column: 26,
      message: "Cannot access static member on an instantiated generic class.");

  _checkError(errors[1],
      path: path,
      line: 232,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");
}

void testDevCompilerErrors() {
  _testMultipleDevCompilerErrors();
}

void _testMultipleDevCompilerErrors() {
  var errors = <StaticError>[];
  DevCompilerCommandOutput.parseErrors('''
org-dartlang-app:/tests/language/explicit_type_instantiation_parsing_test.dart:171:26: Error: Cannot access static member on an instantiated generic class.
Try removing the type arguments or placing them after the member name.
  expect1<Class>(Z<X, X>.instance);
                         ^^^^^^^^
org-dartlang-app:/tests/language/explicit_type_instantiation_parsing_test.dart:232:6: Error: A comparison expression can't be an operand of another comparison expression.
Try putting parentheses around one of the comparisons.
  X<2>(2);
     ^
''', errors);

  var path = 'tests/language/explicit_type_instantiation_parsing_test.dart';

  Expect.equals(2, errors.length);

  _checkError(errors[0],
      path: path,
      line: 171,
      column: 26,
      message: "Cannot access static member on an instantiated generic class.");

  _checkError(errors[1],
      path: path,
      line: 232,
      column: 6,
      message:
          "A comparison expression can't be an operand of another comparison expression.");
}
