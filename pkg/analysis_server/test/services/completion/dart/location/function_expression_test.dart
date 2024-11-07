// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionTest);
  });
}

@reflectiveTest
class FunctionExpressionTest extends AbstractCompletionDriverTest
    with FunctionExpressionTestCases {}

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
''');
  }

  Future<void> test_afterRightParen_beforeRightBrace() async {
    // TODO(brianwilkerson): Not clear that this is testing what the author
    //  thought it would test. Note the '}' where ')' is expected.
    await computeSuggestions('''
void f() {foo(() ^}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  true
    kind: keyword
  async
    kind: keyword
  async*
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void> test_contextType_return_explicit_record_namedField() async {
    await computeSuggestions('''
void f(({int i}) Function() callback) {
  f(() { return (^); });
}
''');
    assertResponse(r'''
suggestions
  |i: |
    kind: namedArgument
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

  Future<void> test_contextType_return_implicit_record_namedField() async {
    await computeSuggestions('''
void f(({int i}) Function() callback) {
  f(() => (^));
}
''');
    assertResponse(r'''
suggestions
  |i: |
    kind: namedArgument
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
