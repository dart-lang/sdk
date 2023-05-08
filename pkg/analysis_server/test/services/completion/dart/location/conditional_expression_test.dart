// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalExpressionTest1);
    defineReflectiveTests(ConditionalExpressionTest2);
  });
}

@reflectiveTest
class ConditionalExpressionTest1 extends AbstractCompletionDriverTest
    with ConditionalExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ConditionalExpressionTest2 extends AbstractCompletionDriverTest
    with ConditionalExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ConditionalExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_elseExpression() async {
    await computeSuggestions('''
class A { foo() {return b == true ? 1 : ^}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
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
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }
}
