// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsExpressionTest);
  });
}

@reflectiveTest
class IsExpressionTest extends AbstractCompletionDriverTest {
  Future<void> test_expression() async {
    await computeSuggestions('''
void f(Object v01) {
  ^ is int;
}
''');
    assertResponse(r'''
suggestions
  v01
    kind: parameter
  return
    kind: keyword
  if
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  throw
    kind: keyword
  for
    kind: keyword
  switch
    kind: keyword
  try
    kind: keyword
  assert
    kind: keyword
  const
    kind: keyword
  do
    kind: keyword
  dynamic
    kind: keyword
  false
    kind: keyword
  late
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  void
    kind: keyword
  while
    kind: keyword
''');
  }

  Future<void> test_expression_partial() async {
    await computeSuggestions('''
void f(Object v01) {
  v0^ is int;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  v01
    kind: parameter
''');
  }

  Future<void> test_identifierStart() async {
    allowedIdentifiers = {'isFoo'};
    await computeSuggestions('''
static void f(bool isFoo) {
  is^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  isFoo
    kind: parameter
''');
  }

  Future<void> test_identifierStart_notAtEndOfIs() async {
    allowedIdentifiers = {'isFoo'};
    await computeSuggestions('''
static void f(bool isFoo) {
  is ^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_identifierStart_staticContext() async {
    allowedIdentifiers = {'isF1', 'isF2'};
    await computeSuggestions('''
class A {
  static bool get isF1 => false;
  bool get isF2 => false;
  static void f() {
    is^
  }
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  isF1
    kind: getter
''');
  }

  Future<void> test_identifierStart_voidFunction() async {
    allowedIdentifiers = {'isFoo'};
    await computeSuggestions('''
static void isFoo() {
  is^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  isFoo
    kind: functionInvocation
''');
  }

  Future<void> test_type() async {
    await computeSuggestions('''
class A01 {}
void f(Object x) {
  x is ^;
}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
''');
  }

  Future<void> test_type_partial() async {
    await computeSuggestions('''
class A01 {}
void f(Object x) {
  x is A0^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }
}
