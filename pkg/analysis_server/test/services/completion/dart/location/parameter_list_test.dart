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
  switch
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
  switch
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
class A { foo(t^) {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }
}
