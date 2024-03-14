// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentExpressionTest);
  });
}

@reflectiveTest
class AssignmentExpressionTest extends AbstractCompletionDriverTest
    with AssignmentExpressionTestCases {}

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
  true
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterEqual_beforeRightBrace_async_partial() async {
    await computeSuggestions('''
void f() async {var foo = n^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
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
  true
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterEqual_beforeRightBrace_sync_partial() async {
    await computeSuggestions('''
void f() {var foo = n^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
  }
}
