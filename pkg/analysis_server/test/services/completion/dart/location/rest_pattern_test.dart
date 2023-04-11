// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RestPatternTest1);
    defineReflectiveTests(RestPatternTest2);
  });
}

@reflectiveTest
class RestPatternTest1 extends AbstractCompletionDriverTest
    with RestPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class RestPatternTest2 extends AbstractCompletionDriverTest
    with RestPatternTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin RestPatternTestCases on AbstractCompletionDriverTest {
  void test_afterRest() async {
    await computeSuggestions('''
void f(Object o) {
  if(o case [int first, ... ^]) {}
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

  void test_afterRest_partial() async {
    await computeSuggestions('''
void f(Object o) {
  if(o case [int first, ... f^]) {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  false
    kind: keyword
  final
    kind: keyword
''');
    } else {
      assertResponse(r'''
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
