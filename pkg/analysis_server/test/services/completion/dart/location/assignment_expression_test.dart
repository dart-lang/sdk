// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentExpressionTest1);
    defineReflectiveTests(AssignmentExpressionTest2);
  });
}

@reflectiveTest
class AssignmentExpressionTest1 extends AbstractCompletionDriverTest
    with AssignmentExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class AssignmentExpressionTest2 extends AbstractCompletionDriverTest
    with AssignmentExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin AssignmentExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterEqual_beforeRightBrace_async() async {
    await computeSuggestions('''
void f() async {var foo = ^}
''');
    assertResponse(r'''
suggestions
  await
    kind: keyword
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterEqual_beforeRightBrace_async_partial() async {
    await computeSuggestions('''
void f() async {var foo = n^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  await
    kind: keyword
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_afterEqual_beforeRightBrace_sync() async {
    await computeSuggestions('''
void f() {var foo = ^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterEqual_beforeRightBrace_sync_partial() async {
    await computeSuggestions('''
void f() {var foo = n^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
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
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }
}
