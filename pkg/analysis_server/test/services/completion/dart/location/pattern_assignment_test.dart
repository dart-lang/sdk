// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternAssignmentTest);
  });
}

@reflectiveTest
class PatternAssignmentTest extends AbstractCompletionDriverTest
    with PatternAssignmentTestCases {}

mixin PatternAssignmentTestCases on AbstractCompletionDriverTest {
  void test_afterEqual() async {
    await computeSuggestions('''
void f((int, int) r01) {
  var a, b;
  (a, b) = ^;
}
''');
    assertResponse(r'''
suggestions
  r01
    kind: parameter
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

  void test_afterEqual_partial() async {
    await computeSuggestions('''
void f((int, int) r01) {
  var a, b;
  (a, b) = r^;
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  r01
    kind: parameter
''');
  }
}
