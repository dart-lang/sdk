// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodInvocationTest);
  });
}

@reflectiveTest
class MethodInvocationTest extends AbstractCompletionDriverTest
    with MethodInvocationTestCases {}

mixin MethodInvocationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterField() async {
    await computeSuggestions('''
class A { int x; foo() {x.^ print("foo");}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLocalVariable() async {
    await computeSuggestions('''
class A { foo() {int x; x.^ print("foo");}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_macroGeneratedMethod() async {
    addMacros([declareInTypeMacro()]);
    await computeSuggestions('''
import 'macros.dart';

@DeclareInType('  void m0() {}')
class C {}

void f(C c) {
  c.^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
''');
  }
}
