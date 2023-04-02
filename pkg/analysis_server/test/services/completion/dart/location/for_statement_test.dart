// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForStatementTest1);
    defineReflectiveTests(ForStatementTest2);
  });
}

/// Tests specific to a for-each statement.
mixin ForEachPartsTestCases on AbstractCompletionDriverTest {
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
}

/// Tests specific to a traditional for statement.
mixin ForPartsTestCases on AbstractCompletionDriverTest {}

@reflectiveTest
class ForStatementTest1 extends AbstractCompletionDriverTest
    with ForEachPartsTestCases, ForPartsTestCases, ForStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ForStatementTest2 extends AbstractCompletionDriverTest
    with ForEachPartsTestCases, ForPartsTestCases, ForStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

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
''');
  }
}
