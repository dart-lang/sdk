// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParenthesizedPatternTest);
  });
}

@reflectiveTest
class ParenthesizedPatternTest extends AbstractCompletionDriverTest
    with ParenthesizedPatternTestCases {}

mixin ParenthesizedPatternTestCases on AbstractCompletionDriverTest {
  void test_empty() async {
    await computeSuggestions('''
void f(int i) {
  if (i case (^) ) ];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  dynamic
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

  void test_partial() async {
    await computeSuggestions('''
void f(int i) {
  if (i case (f^) ) ];
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
  final
    kind: keyword
''');
  }
}
