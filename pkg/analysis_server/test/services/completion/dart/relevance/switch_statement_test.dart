// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementTest);
  });
}

@reflectiveTest
class SwitchStatementTest extends CompletionRelevanceTest
    with SwitchStatementTestCases {}

mixin SwitchStatementTestCases on CompletionRelevanceTest {
  Future<void> test_caseBody() async {
    await addTestFile('''
void f(Object? x) {
  switch (x) {
    case 0:
      ^
  }
}
''');

    assertOrder([
      suggestionWith(completion: 'x'),
      suggestionWith(completion: 'return'),
      suggestionWith(completion: 'break'),
    ]);
  }
}
