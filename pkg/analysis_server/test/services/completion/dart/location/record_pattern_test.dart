// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordPatternTest1);
    defineReflectiveTests(RecordPatternTest2);
  });
}

@reflectiveTest
class RecordPatternTest1 extends AbstractCompletionDriverTest
    with RecordPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class RecordPatternTest2 extends AbstractCompletionDriverTest
    with RecordPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin RecordPatternTestCases on AbstractCompletionDriverTest {
  Future<void> test_empty() async {
    await computeSuggestions('''
void f(Object o) {
  switch (o) {
    case (^)
  }
}
''');
    assertResponse('''
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
}
