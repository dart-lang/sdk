// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachPartsTest1);
    defineReflectiveTests(ForEachPartsTest2);
    defineReflectiveTests(ForPartsTest1);
    defineReflectiveTests(ForPartsTest2);
    defineReflectiveTests(ForStatementTest1);
    defineReflectiveTests(ForStatementTest2);
  });
}

@reflectiveTest
class ForEachPartsTest1 extends AbstractCompletionDriverTest
    with ForEachPartsTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ForEachPartsTest2 extends AbstractCompletionDriverTest
    with ForEachPartsTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

/// Tests specific to a for-each statement.
mixin ForEachPartsTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterEquals_beforeRightParen_partial_i() async {
    await computeSuggestions('''
void f() {for (int x = i^)}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_afterEquals_beforeRightParen_partial_in() async {
    await computeSuggestions('''
void f() {for (int x = in^)}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_afterIn() async {
    await computeSuggestions('''
void f(List<(int, int)> x01) {
  for (final (a, b) in ^)
}
''');
    assertResponse(r'''
suggestions
  await
    kind: keyword
  x01
    kind: parameter
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
class ForPartsTest1 extends AbstractCompletionDriverTest
    with ForPartsTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ForPartsTest2 extends AbstractCompletionDriverTest
    with ForPartsTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

/// Tests specific to a traditional for statement.
mixin ForPartsTestCases on AbstractCompletionDriverTest {}

@reflectiveTest
class ForStatementTest1 extends AbstractCompletionDriverTest
    with ForStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ForStatementTest2 extends AbstractCompletionDriverTest
    with ForStatementTestCases {
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
  final
    kind: keyword
  var
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
  final
    kind: keyword
  var
    kind: keyword
''');
  }
}
