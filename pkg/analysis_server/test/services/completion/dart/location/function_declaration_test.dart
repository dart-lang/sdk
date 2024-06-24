// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationTest);
  });
}

@reflectiveTest
class FunctionDeclarationTest extends AbstractCompletionDriverTest
    with FunctionDeclarationTestCases {}

mixin FunctionDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterDocComment_beforeName_extraClosingBrace() async {
    await computeSuggestions('''
/// comment
 ^ foo() {}}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeEnd() async {
    await computeSuggestions('''
void f()^
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

  Future<void> test_afterRightParen_beforeEnd_partial() async {
    await computeSuggestions('''
void f()a^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  abstract
    kind: keyword
  async
    kind: keyword
  async*
    kind: keyword
''');
  }

  Future<void> test_afterRightParen_beforeLeftBrace() async {
    await computeSuggestions('''
void f()^{}
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

  Future<void> test_afterRightParen_beforeLeftBrace_partial() async {
    await computeSuggestions('''
void f()a^{}
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

  Future<void> test_afterRightParen_beforeVariable_partial() async {
    await computeSuggestions('''
void f()a^ Foo foo;
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
}
