// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrimaryConstructorDeclarationTest);
  });
}

@reflectiveTest
class PrimaryConstructorDeclarationTest extends AbstractCompletionDriverTest
    with PrimaryConstructorDeclarationTestCases {}

mixin PrimaryConstructorDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCovariant() async {
    await computeSuggestions('''
class C(covariant ^) {}
''');
    assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterFinal() async {
    await computeSuggestions('''
class C(final ^) {}
''');
    assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterFinalAndType() async {
    await computeSuggestions('''
class C(final int ^) {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterRequired() async {
    await computeSuggestions('''
class C({required ^}) {}
''');
    assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterType() async {
    await computeSuggestions('''
class C(int ^) {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterVar() async {
    await computeSuggestions('''
class C(var ^) {}
''');
    assertResponse(r'''
suggestions
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterVarAndType() async {
    await computeSuggestions('''
class C(var int ^) {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_beforeFirstParameter() async {
    await computeSuggestions('''
class C(^) {}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_beforeLastParameter() async {
    await computeSuggestions('''
class C(int x, ^) {}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_beforeMiddleParameter() async {
    await computeSuggestions('''
class C(int x, ^, int z) {}
''');
    assertResponse(r'''
suggestions
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
  this
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_beforeName() async {
    await computeSuggestions('''
class ^ C {}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
''');
  }

  Future<void> test_initializer_last() async {
    await computeSuggestions('''
class A(var int f0) {
  this : ^;

  int f1;
}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  f1
    kind: field
  super
    kind: keyword
  this
    kind: keyword
''');
  }

  Future<void> test_initializer_notLast() async {
    await computeSuggestions('''
class A(var int f0) {
  this : ^, super();

  int f1;
}
''');
    assertResponse(r'''
suggestions
  assert
    kind: keyword
  f1
    kind: field
''');
  }

  Future<void> test_initializerAssertExpression() async {
    await computeSuggestions('''
enum MyEnum(final String f0) {
  first('123');

  this : assert(f^, 'hello');
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
  f0
    kind: field
''');
  }

  Future<void> test_noName() async {
    await computeSuggestions('''
class ^
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
''');
  }
}
