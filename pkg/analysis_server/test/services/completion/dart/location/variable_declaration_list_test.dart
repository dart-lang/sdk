// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableDeclarationListTest);
  });
}

@reflectiveTest
class VariableDeclarationListTest extends AbstractCompletionDriverTest
    with VariableDeclarationListTestCases {}

mixin VariableDeclarationListTestCases on AbstractCompletionDriverTest {
  Future<void> test_inForParts_afterFinal() async {
    await computeSuggestions('''
void f(Object x) {
  for (final ^)
}

class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
  A01
    kind: class
  A02
    kind: class
  B01
    kind: class
  dynamic
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_inForParts_afterVar() async {
    await computeSuggestions('''
void f(Object x) {
  for (var ^)
}

class A01 {}
class A02 {}
class B01 {}
''');
    assertResponse(r'''
suggestions
''');
  }
}
