// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementTest1);
    defineReflectiveTests(SwitchStatementTest2);
  });
}

@reflectiveTest
class SwitchStatementTest1 extends AbstractCompletionDriverTest
    with SwitchStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class SwitchStatementTest2 extends AbstractCompletionDriverTest
    with SwitchStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin SwitchStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterLeftBrace_beforeCase() async {
    await computeSuggestions('''
void f() {switch(1) {^ case 1:}}
''');
    assertResponse(r'''
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeDefault_partial() async {
    await computeSuggestions('''
void f() {switch(1) {c^ default:}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeDefault_withoutSpace() async {
    await computeSuggestions('''
void f() {switch(1) {^default:}}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeDefault_withSpace() async {
    await computeSuggestions('''
void f() {switch(1) {^ default:}}
''');
    // TODO(brianwilkerson) We shouldn't be suggesting `default` here.
    assertResponse(r'''
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeEnd_withoutWhitespace_partial() async {
    await computeSuggestions('''
void f() {switch(1) {c^}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
    }
  }

  Future<void> test_afterLeftBrace_beforeEnd_withWhitespace_partial() async {
    await computeSuggestions('''
void f() {switch(1) { c^ }}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
    }
  }

  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
void f() {switch(1) {^}}
''');
    assertResponse(r'''
suggestions
  case
    kind: keyword
  default:
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace_withBody_partial() async {
    await computeSuggestions('''
void f() {switch(n^) {}}
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

  Future<void>
      test_afterLeftBrace_beforeRightBrace_withoutBody_partial() async {
    await computeSuggestions('''
void f() {switch(n^)}
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

  Future<void> test_afterLeftParen_beforeRightParen() async {
    await computeSuggestions('''
void f() {switch(^) {}}
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
}
