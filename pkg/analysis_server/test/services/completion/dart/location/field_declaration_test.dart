// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldDeclarationInClassTest);
    defineReflectiveTests(FieldDeclarationInExtensionTest);
  });
}

@reflectiveTest
class FieldDeclarationInClassTest extends AbstractCompletionDriverTest
    with FieldDeclarationInClassTestCases {}

mixin FieldDeclarationInClassTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterStatic_beforeEnd_partial_c() async {
    await computeSuggestions('''
class C {
  static c^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
''');
  }

  Future<void> test_afterStatic_beforeEnd_partial_f() async {
    await computeSuggestions('''
class C {
  static f^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  final
    kind: keyword
''');
  }

  Future<void> test_final_typeName_fieldName_in() async {
    allowedIdentifiers = {'inputValue'};

    await computeSuggestions(r'''
class InputValue {}

class A {
  final InputValue in^
}
''');

    assertResponse('''
replacement
  left: 2
suggestions
  inputValue
    kind: identifier
''');
  }

  Future<void> test_final_typeName_fieldName_is() async {
    allowedIdentifiers = {'isValue'};

    await computeSuggestions(r'''
class IsValue {}

class A {
  final IsValue is^
}
''');

    assertResponse('''
replacement
  left: 2
suggestions
  isValue
    kind: identifier
''');
  }

  Future<void> test_initializer() async {
    await computeSuggestions('''
class A {var foo = ^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  true
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_initializer_partial() async {
    await computeSuggestions('''
class A {var foo = n^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }
}

@reflectiveTest
class FieldDeclarationInExtensionTest extends AbstractCompletionDriverTest
    with FieldDeclarationInExtensionTestCases {}

mixin FieldDeclarationInExtensionTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterStatic_partial_c() async {
    await computeSuggestions('''
extension E on int {
  static c^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
''');
  }

  Future<void> test_afterStatic_partial_f() async {
    await computeSuggestions('''
extension E on int {
  static f^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  final
    kind: keyword
''');
  }
}
