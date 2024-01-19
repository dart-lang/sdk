// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndPatternTest);
  });
}

@reflectiveTest
class LogicalAndPatternTest extends AbstractCompletionDriverTest
    with LogicalAndPatternTestCases {}

mixin LogicalAndPatternTestCases on AbstractCompletionDriverTest {
  void test_afterOperator() async {
    await computeSuggestions('''
void f(int i) {
  if (i case < 3 && ^ ) ];
}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
''');
  }
}
