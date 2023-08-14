// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeTestTest1);
    defineReflectiveTests(TypeTestTest2);
  });
}

@reflectiveTest
class TypeTestTest1 extends AbstractCompletionDriverTest
    with TypeTestTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class TypeTestTest2 extends AbstractCompletionDriverTest
    with TypeTestTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin TypeTestTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterIs_beforeEnd() async {
    await computeSuggestions('''
void f() {if (x is^)}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  is
    kind: keyword
''');
  }

  Future<void> test_afterLeftOperand_beforeEnd_ifWithBody_partial() async {
    await computeSuggestions('''
void f() { if (v i^) {} }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  is
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
  is
    kind: keyword
''');
    }
  }

  Future<void> test_afterLeftOperand_beforeEnd_ifWithoutBody_partial() async {
    await computeSuggestions('''
void f() {if (x i^)}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  is
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
  is
    kind: keyword
''');
    }
  }

  Future<void> test_afterLeftOperand_beforeLogicalAnd_partial() async {
    await computeSuggestions('''
void f() { if (v i^ && false) {} }
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
  is
    kind: keyword
''');
  }
}
