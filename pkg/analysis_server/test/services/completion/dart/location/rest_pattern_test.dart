// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RestPatternTest);
  });
}

@reflectiveTest
class RestPatternTest extends AbstractCompletionDriverTest
    with RestPatternTestCases {}

mixin RestPatternTestCases on AbstractCompletionDriverTest {
  void test_afterRest() async {
    await computeSuggestions('''
void f(Object o) {
  if(o case [int first, ... ^]) {}
}
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
''');
  }

  void test_afterRest_partial() async {
    await computeSuggestions('''
void f(Object o) {
  if(o case [int first, ... f^]) {}
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
