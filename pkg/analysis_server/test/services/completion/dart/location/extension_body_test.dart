// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionBodyTest);
  });
}

@reflectiveTest
class ExtensionBodyTest extends AbstractCompletionDriverTest
    with ExtensionBodyTestCases {}

mixin ExtensionBodyTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterMethod_beforeEnd() async {
    await computeSuggestions('''
extension E on int {foo() {} ^}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  const
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterMethod_beforeMethod() async {
    await computeSuggestions('''
extension E on int {foo() {} ^ void bar() {}}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  const
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterStart_beforeEnd() async {
    await computeSuggestions('''
extension E on int {^}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  const
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterStart_beforeMethod() async {
    await computeSuggestions('''
extension E on int {^ foo() {}}
''');
    assertResponse(r'''
suggestions
  void
    kind: keyword
  const
    kind: keyword
  dynamic
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_inMethod_parameterShadowField() async {
    allowedIdentifiers = {'aaa'};
    await computeSuggestions('''
class A {
  String aaa = '';
}

extension E on A {foo(int aaa) {  a^;} }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  aaa
    kind: parameter
  assert
    kind: keyword
''');
  }
}
