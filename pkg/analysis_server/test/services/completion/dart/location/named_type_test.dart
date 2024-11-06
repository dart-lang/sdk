// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedTypeTest);
  });
}

@reflectiveTest
class NamedTypeTest extends AbstractCompletionDriverTest
    with NamedTypeTestCases {}

mixin NamedTypeTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComment_beforeFunctionName_partial() async {
    await computeSuggestions('''
/// comment
 d^ foo() {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeIdentifier_syncStar_partial() async {
    await computeSuggestions('''
void f() sync* {n^ foo}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }

  Future<void>
  test_afterLeftParen_beforeFunction_inConstructor_partial() async {
    await computeSuggestions('''
class A { A(v^ Function(){}) {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeFunction_inMethod_partial() async {
    await computeSuggestions('''
class A { foo(v^ Function(){}) {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  void
    kind: keyword
''');
  }
}
