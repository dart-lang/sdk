// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachPartsTest);
    defineReflectiveTests(ForPartsTest);
    defineReflectiveTests(ForStatementTest);
  });
}

@reflectiveTest
class ForEachPartsTest extends AbstractCompletionDriverTest
    with ForEachPartsTestCases {}

/// Tests specific to a for-each statement.
mixin ForEachPartsTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterEquals_beforeRightParen_partial_i() async {
    await computeSuggestions('''
void f() {for (int x = i^)}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_afterEquals_beforeRightParen_partial_in() async {
    await computeSuggestions('''
void f() {for (int x = in^)}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
''');
  }

  Future<void> test_afterIn() async {
    await computeSuggestions('''
void f(List<(int, int)> x01) {
  for (final (a, b) in ^)
}
''');
    assertResponse(r'''
suggestions
  x01
    kind: parameter
  await
    kind: keyword
''');
  }

  Future<void> test_afterPattern() async {
    await computeSuggestions('''
void f(Object x) {
  for (final (a, b) ^)
}
''');
    assertResponse(r'''
suggestions
  in
    kind: keyword
''');
  }

  Future<void> test_afterPattern_partial() async {
    await computeSuggestions('''
void f(List<(int, int)> rl) {
  for (final (a, b) i^)
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  in
    kind: keyword
''');
  }

  Future<void> test_afterTypeName_beforeRightParen_partial() async {
    await computeSuggestions('''
void f() {for (int i^)}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void>
  test_afterVariableDeclaration_beforeRightParen_partial_i() async {
    await computeSuggestions('''
void f() {for (int x i^)}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  in
    kind: keyword
''');
  }

  Future<void>
  test_afterVariableDeclaration_beforeRightParen_partial_in() async {
    await computeSuggestions('''
void f() {for (int x in^)}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  in
    kind: keyword
''');
  }
}

@reflectiveTest
class ForPartsTest extends AbstractCompletionDriverTest
    with ForPartsTestCases {}

/// Tests specific to a traditional for statement.
mixin ForPartsTestCases on AbstractCompletionDriverTest {}

@reflectiveTest
class ForStatementTest extends AbstractCompletionDriverTest
    with ForStatementTestCases {}

/// Tests that apply to both traditional for statements and for-each statements.
mixin ForStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_forParts_empty() async {
    await computeSuggestions('''
void f(Object x) {
  for (^)
}
''');
    assertResponse(r'''
suggestions
  var
    kind: keyword
  final
    kind: keyword
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_statements_empty() async {
    await computeSuggestions('''
void f(Object x) {
  for (^)
}
''');
    assertResponse(r'''
suggestions
  var
    kind: keyword
  final
    kind: keyword
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }
}
