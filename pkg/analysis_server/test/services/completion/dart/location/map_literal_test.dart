// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapLiteralTest);
  });
}

@reflectiveTest
class MapLiteralTest extends AbstractCompletionDriverTest
    with MapLiteralTestCases {}

mixin MapLiteralTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterComma_beforeComma() async {
    await computeSuggestions('''
f() => <String, int>{'a' : 1, ^, 'b' : 2];
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterComma_beforeRightBrace() async {
    await computeSuggestions('''
f() => <String, int>{'a' : 1, 'b' : 2, ^};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeKey() async {
    await computeSuggestions('''
f() => <String, int>{^'a' : 1};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
f() => <String, int>{^};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }
}
