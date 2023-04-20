// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementTest1);
    defineReflectiveTests(IfStatementTest2);
  });
}

@reflectiveTest
class IfStatementTest1 extends AbstractCompletionDriverTest
    with IfStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class IfStatementTest2 extends AbstractCompletionDriverTest
    with IfStatementTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin IfStatementTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterCase() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case ^)
}

class A1 {
  A1.named();
}

const c01 = 0;

final v01 = 0;

int f01() => 0;
''');
    // TODO(scheglov) This is wrong.
    // We should not suggest `v01`.
    // We could suggest `f01`, but not as an invocation.
    // We suggest `A1`, but almost always we want `A1()`.
    assertResponse(r'''
suggestions
  A1
    kind: class
  c01
    kind: topLevelVariable
  const
    kind: keyword
  f01
    kind: functionInvocation
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  v01
    kind: topLevelVariable
  var
    kind: keyword
''');
  }

  Future<void> test_afterCase_partial() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case A^)
}

class A01 {}
class B01 {}

const A02 = 0;
const B02 = 0;

final A03 = 0;
final B03 = 0;

int A04() => 0;
int B04() => 0;
''');

    if (isProtocolVersion2) {
      // TODO(scheglov) This is wrong.
      assertResponse(r'''
replacement
  left: 1
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  A02
    kind: topLevelVariable
  A03
    kind: topLevelVariable
  A04
    kind: functionInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A01
    kind: class
  A01
    kind: constructorInvocation
  A02
    kind: topLevelVariable
  A03
    kind: topLevelVariable
  A04
    kind: functionInvocation
  B01
    kind: class
  B01
    kind: constructorInvocation
  B02
    kind: topLevelVariable
  B03
    kind: topLevelVariable
  B04
    kind: functionInvocation
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

  Future<void> test_afterPattern() async {
    await computeSuggestions('''
void f(Object o) {
  if (o case var x ^)
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
  if (o case var x w^)
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
  if (o case var x when ^)
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
  if (o case var x when c^)
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
void f(Object o) {
  if (o ^) {}
}
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
void f() {
  if (^) {}
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
}
