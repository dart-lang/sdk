// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableDeclarationTest1);
    defineReflectiveTests(PatternVariableDeclarationTest2);
  });
}

@reflectiveTest
class PatternVariableDeclarationTest1 extends AbstractCompletionDriverTest
    with PatternVariableDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class PatternVariableDeclarationTest2 extends AbstractCompletionDriverTest
    with PatternVariableDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin PatternVariableDeclarationTestCases on AbstractCompletionDriverTest {
  void test_afterEqual() async {
    await computeSuggestions('''
void f((int, int) r01) {
  var (a, b) = ^;
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  r01
    kind: parameter
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  void test_afterEqual_partial() async {
    await computeSuggestions('''
void f((int, int) r01) {
  var (a, b) = r^;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  r01
    kind: parameter
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  r01
    kind: parameter
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }
}
