// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationTest1);
    defineReflectiveTests(FunctionDeclarationTest2);
  });
}

@reflectiveTest
class FunctionDeclarationTest1 extends AbstractCompletionDriverTest
    with FunctionDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class FunctionDeclarationTest2 extends AbstractCompletionDriverTest
    with FunctionDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin FunctionDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterDocComment_beforeName_extraClosingBrace() async {
    await computeSuggestions('''
/// comment
 ^ foo() {}}
''');
    assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  void
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
    if (isProtocolVersion2) {
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
    } else {
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
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  mixin
    kind: keyword
  sealed
    kind: keyword
  sync*
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
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
  sync*
    kind: keyword
''');
  }

  Future<void> test_afterRightParent_beforeVariable_partial() async {
    await computeSuggestions('''
void f()a^ Foo foo;
''');
    if (isProtocolVersion2) {
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
    } else {
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
  base
    kind: keyword
  class
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  extension
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  interface
    kind: keyword
  late
    kind: keyword
  mixin
    kind: keyword
  sealed
    kind: keyword
  sync*
    kind: keyword
  typedef
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }
}
