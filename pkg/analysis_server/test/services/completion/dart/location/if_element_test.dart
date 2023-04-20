// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfElementTest1);
    defineReflectiveTests(IfElementTest2);
  });
}

@reflectiveTest
class IfElementTest1 extends AbstractCompletionDriverTest
    with IfElementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class IfElementTest2 extends AbstractCompletionDriverTest
    with IfElementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin IfElementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterPattern() async {
    await computeSuggestions('''
void f(Object o) {
  var v = [ if (o case var x ^) ];
}
''');
    assertResponse(r'''
suggestions
  when
    kind: keyword
''');
  }

  Future<void> test_afterPattern_partial() async {
    await computeSuggestions('''
void f(Object o) {
  var v = [ if (o case var x w^) ];
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  when
    kind: keyword
''');
  }

  Future<void> test_afterWhen() async {
    await computeSuggestions('''
void f(Object o) {
  var v = [ if (o case var x when ^) ];
}
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

  Future<void> test_afterWhen_partial() async {
    await computeSuggestions('''
void f(Object o) {
  var v = [ if (o case var x when c^) ];
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
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
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }

  Future<void> test_rightParen_withCondition_withoutCase() async {
    await computeSuggestions('''
var v = [ if (o ^) ];
''');
    assertResponse(r'''
suggestions
  case
    kind: keyword
  is
    kind: keyword
''');
  }

  Future<void> test_rightParen_withoutCondition() async {
    await computeSuggestions('''
var v = [ if (^) ];
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
