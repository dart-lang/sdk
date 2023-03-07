// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionTest1);
    defineReflectiveTests(SwitchExpressionTest2);
  });
}

@reflectiveTest
class SwitchExpressionTest1 extends AbstractCompletionDriverTest
    with SwitchExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class SwitchExpressionTest2 extends AbstractCompletionDriverTest
    with SwitchExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

// mixin SwitchCaseTestCases on AbstractCompletionDriverTest {
// }

mixin SwitchExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_body_afterArrow() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    1 => ^
  };
}
''');
    assertResponse('''
suggestions
  p01
    kind: parameter
''');
  }

  Future<void> test_body_afterComma() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    1 => 2,
    ^
  };
}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_body_empty() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    ^
  };
}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_expression() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (^) {};
}
''');
    assertResponse('''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  p01
    kind: parameter
  switch
    kind: keyword
  true
    kind: keyword
''');
  }
}
