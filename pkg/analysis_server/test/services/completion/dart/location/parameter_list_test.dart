// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParameterListInConstructorTest);
    defineReflectiveTests(ParameterListInFunctionTest);
    defineReflectiveTests(ParameterListInMethodTest);
  });
}

@reflectiveTest
class ParameterListInConstructorTest extends AbstractCompletionDriverTest
    with ParameterListInConstructorTestCases {}

mixin ParameterListInConstructorTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftParen_beforeFunctionType() async {
    await computeSuggestions('''
class A { A(^ Function() f) {}}
''');
    assertResponse(r'''
suggestions
  this
    kind: keyword
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen() async {
    await computeSuggestions('''
class A { A(^) {}}
''');
    assertResponse(r'''
suggestions
  this
    kind: keyword
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_language215() async {
    await computeSuggestions('''
// @dart = 2.15
class A {
  A(^);
}
''');
    assertResponse(r'''
suggestions
  this
    kind: keyword
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_partial() async {
    await computeSuggestions('''
class A { A(t^) {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  this
    kind: keyword
  covariant
    kind: keyword
''');
  }

  Future<void> test_afterRequired_beforeVariableName() async {
    allowedIdentifiers = {'int', 'String'};
    await computeSuggestions('''
class A {
  A({required ^ s});
}
  ''');
    assertResponse(r'''
suggestions
  String
    kind: class
  int
    kind: class
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
''');
  }

  Future<void> test_afterRequired_withoutVariableName() async {
    allowedIdentifiers = {'int', 'String'};
    await computeSuggestions('''
class A {
  A({required ^});
}
''');
    assertResponse(r'''
suggestions
  String
    kind: class
  int
    kind: class
  this
    kind: keyword
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
''');
  }

  Future<void> test_afterRequiredVariableName() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class A {
  A({required S^});
}
  ''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  String
    kind: class
  this
    kind: keyword
  super
    kind: keyword
''');
  }

  // TODO(keertip): Do not suggest 'covariant'.
  Future<void> test_afterType() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(T^ k);T m(T a, T b){}final T f = null;}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  T
    kind: typeParameter
  covariant
    kind: keyword
''');
  }

  Future<void> test_beforeType() async {
    allowedIdentifiers = {'T'};
    await computeSuggestions('''
class Bar<T extends Foo> {const Bar(^T k);T m(T a, T b){}final T f = null;}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  this
    kind: keyword
  void
    kind: keyword
  T
    kind: typeParameter
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  super
    kind: keyword
''');
  }
}

@reflectiveTest
class ParameterListInFunctionTest extends AbstractCompletionDriverTest
    with ParameterListInFunctionTestCases {}

mixin ParameterListInFunctionTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftParen_beforeFunctionType_partial() async {
    await computeSuggestions('''
void f(^void Function() g) {}
''');
    assertResponse(r'''
replacement
  right: 4
suggestions
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
''');
  }

  Future<void> test_named_last_afterCovariant() async {
    await computeSuggestions('''
void f({covariant ^}) {}
''');
    assertResponse('''
suggestions
  void
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  required
    kind: keyword
''');
  }

  Future<void> test_named_last_afterRequired() async {
    await computeSuggestions('''
void f({required ^}) {}
''');
    assertResponse('''
suggestions
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
''');
  }
}

@reflectiveTest
class ParameterListInMethodTest extends AbstractCompletionDriverTest
    with ParameterListInMethodTestCases {}

mixin ParameterListInMethodTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterColon_beforeRightBrace() async {
    await computeSuggestions('''
class A { foo({bool bar: ^}) {}}
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  null
    kind: keyword
''');
  }

  Future<void> test_afterColon_beforeRightBrace_partial() async {
    await computeSuggestions('''
class A { foo({bool bar: f^}) {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
''');
  }

  Future<void> test_afterEqual_beforeRightBracket() async {
    await computeSuggestions('''
class A { foo([bool bar = ^]) {}}
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  null
    kind: keyword
''');
  }

  Future<void> test_afterEqual_beforeRightBracket_partial() async {
    await computeSuggestions('''
class A { foo([bool bar = f^]) {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeFunctionType() async {
    await computeSuggestions('''
class A { foo(^ Function(){}) {}}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen() async {
    await computeSuggestions('''
class A { foo(^) {}}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
''');
  }

  Future<void> test_afterLeftParen_beforeRightParen_partial() async {
    await computeSuggestions('''
class A { foo(s^) {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }
}
