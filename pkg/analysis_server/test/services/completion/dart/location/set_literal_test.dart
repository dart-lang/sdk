// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetLiteralTest1);
    defineReflectiveTests(SetLiteralTest2);
  });
}

@reflectiveTest
class SetLiteralTest1 extends AbstractCompletionDriverTest
    with SetLiteralTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class SetLiteralTest2 extends AbstractCompletionDriverTest
    with SetLiteralTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin SetLiteralTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComma_beforeComma() async {
    await computeSuggestions('''
f() => <int>{1, ^, 2};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterComma_beforeRightBrace() async {
    await computeSuggestions('''
f() => <int>{1, 2, ^};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeElement() async {
    await computeSuggestions('''
f() => <int>{^1, 2};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
f() => <int>{^};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  for
    kind: keyword
  if
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
