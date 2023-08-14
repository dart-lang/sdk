// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralTest1);
    defineReflectiveTests(ListLiteralTest2);
  });
}

@reflectiveTest
class ListLiteralTest1 extends AbstractCompletionDriverTest
    with ListLiteralTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ListLiteralTest2 extends AbstractCompletionDriverTest
    with ListLiteralTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ListLiteralTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComma_beforeComma() async {
    await computeSuggestions('''
f() => [1, ^, 2];
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

  Future<void> test_afterComma_beforeRightBracket() async {
    await computeSuggestions('''
void f() {
  [if (true) 1, ^];
}
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

  Future<void> test_afterComma_beforeRightBracket2() async {
    await computeSuggestions('''
f() => [1, 2, ^];
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

  Future<void> test_afterIntegerLiteral_beforeRightBracket() async {
    await computeSuggestions('''
void f() { var items = [42^]; }
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLeftBracket_beforeInteger() async {
    await computeSuggestions('''
f() => [^1, 2];
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

  Future<void> test_afterLeftBracket_beforeRightBracket() async {
    await computeSuggestions('''
f() => [^];
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

  Future<void> test_afterSpread_beforeRightBracket() async {
    await computeSuggestions('''
f() => [...^];
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
