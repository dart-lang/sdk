// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorInvocationTest);
  });
}

@reflectiveTest
class ConstructorInvocationTest extends AbstractCompletionDriverTest
    with ConstructorInvocationTestCases {}

mixin ConstructorInvocationTestCases on AbstractCompletionDriverTest {
  Future<void> test_macroGeneratedMethod() async {
    addMacros([declareInTypeMacro()]);
    await computeSuggestions('''
import 'macros.dart';

@DeclareInType('  C.c1();')
class C {}

void f() {
  C.^
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: constructorInvocation
''');
  }
}
