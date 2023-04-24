// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionTest1);
    defineReflectiveTests(FunctionExpressionTest2);
  });
}

@reflectiveTest
class FunctionExpressionTest1 extends AbstractCompletionDriverTest
    with FunctionExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class FunctionExpressionTest2 extends AbstractCompletionDriverTest
    with FunctionExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin FunctionExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterAsync_beforeLeftBrace() async {
    await computeSuggestions('''
void f() {foo(() async ^ {}}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterRightParen_beforeArrow() async {
    await computeSuggestions('''
void f() {foo(() ^ => 2}}
''');
    assertResponse(r'''
suggestions
  async
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeArrow_partial() async {
    await computeSuggestions('''
void f() {foo("bar", () as^ => null
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  async
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeLeftBrace() async {
    await computeSuggestions('''
void f() {foo(() ^ {})}}
''');
    assertResponse(r'''
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeLeftBrace_missingRightParen() async {
    await computeSuggestions('''
void f() {foo(() ^ {}}}
''');
    assertResponse(r'''
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void>
      test_afterRightParen_beforeLeftBrace_missingRightParen_partial_a() async {
    await computeSuggestions('''
void f() {foo(() a^ {}}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeLeftBrace_partial_a() async {
    await computeSuggestions('''
void f() {foo(() a^ {})}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeLeftBrace_partial_as() async {
    await computeSuggestions('''
void f() {foo("bar", () as^{}}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeRightBrace() async {
    // TODO(brianwilkerson) Not clear that this is testing what the author
    //  thought it would test. Note the '}' where ')' is expected.
    await computeSuggestions('''
void f() {foo(() ^}}
''');
    assertResponse(r'''
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  sync*
    kind: keyword
  true
    kind: keyword
''');
  }
}
