// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnStatementTest);
  });
}

@reflectiveTest
class ReturnStatementTest extends AbstractCompletionDriverTest
    with ReturnStatementTestCases {}

mixin ReturnStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterReturn_beforeEnd() async {
    await computeSuggestions('''
class A { foo() {return ^}}
''');
    assertResponse(r'''
suggestions
  true
    kind: keyword
  null
    kind: keyword
  false
    kind: keyword
  this
    kind: keyword
  const
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
''');
  }
}
