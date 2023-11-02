// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionTest1);
    defineReflectiveTests(SwitchExpressionTest2);
  });
}

@reflectiveTest
class SwitchExpressionTest1 extends AbstractCompletionDriverTest
    with SwitchExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class SwitchExpressionTest2 extends AbstractCompletionDriverTest
    with SwitchExpressionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin SwitchExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_body_afterArrow() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    1 => ^
  };
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
  p01
    kind: parameter
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_body_afterComma() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    1 => 2,
    ^
  };
}

class A1 {}
''');
    assertResponse(r'''
suggestions
  A1
    kind: class
  A1
    kind: constructorInvocation
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

  Future<void> test_body_empty() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    ^
  };
}

class A1 {
  A1.named();
}

const c01 = 0;

final v01 = 0;

int f01() => 0;
''');
    assertResponse(r'''
suggestions
  A1
    kind: class
  A1.named
    kind: constructorInvocation
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

  Future<void> test_body_partial() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    A^
  };
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
''');
    }
  }

  Future<void> test_body_partial2() async {
    await computeSuggestions('''
void f(Object p01) {
  (switch (p01) {
    A^
  });
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
''');
    }
  }

  Future<void> test_expression() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (^) {};
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
  p01
    kind: parameter
  switch
    kind: keyword
  true
    kind: keyword
''');
  }
}
