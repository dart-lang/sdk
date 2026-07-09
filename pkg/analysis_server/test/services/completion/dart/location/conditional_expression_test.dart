// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalExpressionTest);
  });
}

@reflectiveTest
class ConditionalExpressionTest extends AbstractCompletionDriverTest
    with ConditionalExpressionTestCases {}

mixin ConditionalExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_elseExpression() async {
    await computeSuggestions('''
class A { foo() {return b == true ? 1 : ^}}
''');
    assertResponse(r'''
suggestions
  null
    kind: keyword
  const
    kind: keyword
  false
    kind: keyword
  this
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_thenExpression_noElse() async {
    await computeSuggestions('''
class A { foo() {return b == true ? ^}}
''');
    assertResponse(r'''
suggestions
  null
    kind: keyword
  const
    kind: keyword
  true
    kind: keyword
  false
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
''');
  }
}
