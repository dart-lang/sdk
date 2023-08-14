// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnStatementTest1);
    defineReflectiveTests(ReturnStatementTest2);
  });
}

@reflectiveTest
class ReturnStatementTest1 extends AbstractCompletionDriverTest
    with ReturnStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ReturnStatementTest2 extends AbstractCompletionDriverTest
    with ReturnStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ReturnStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterReturn_beforeEnd() async {
    await computeSuggestions('''
class A { foo() {return ^}}
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
