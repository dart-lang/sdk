// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParenthesizedPatternTest1);
    defineReflectiveTests(ParenthesizedPatternTest2);
  });
}

@reflectiveTest
class ParenthesizedPatternTest1 extends AbstractCompletionDriverTest
    with ParenthesizedPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ParenthesizedPatternTest2 extends AbstractCompletionDriverTest
    with ParenthesizedPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ParenthesizedPatternTestCases on AbstractCompletionDriverTest {
  void test_empty() async {
    await computeSuggestions('''
void f(int i) {
  if (i case (^) ) ];
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

  void test_partial() async {
    await computeSuggestions('''
void f(int i) {
  if (i case (f^) ) ];
}
''');
    if (isProtocolVersion2) {
      assertResponse('''
replacement
  left: 1
suggestions
  false
    kind: keyword
  final
    kind: keyword
''');
    } else {
      assertResponse('''
replacement
  left: 1
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
}
