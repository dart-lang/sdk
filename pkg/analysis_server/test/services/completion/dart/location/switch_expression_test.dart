// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionTest);
  });
}

@reflectiveTest
class SwitchExpressionTest extends AbstractCompletionDriverTest
    with SwitchExpressionTestCases {}

mixin SwitchExpressionTestCases on AbstractCompletionDriverTest {
  Future<void> test_beforeArrow() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    ^ => 0,
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
  c01
    kind: topLevelVariable
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
  p01
    kind: parameter
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_body_afterArrow_newVar() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    var v01 => ^
  };
}
''');
    assertResponse(r'''
suggestions
  v01
    kind: localVariable
  p01
    kind: parameter
  const
    kind: keyword
  switch
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

  Future<void> test_body_afterWhen_newVar() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (p01) {
    var v01 when ^
  };
}
''');
    assertResponse(r'''
suggestions
  v01
    kind: localVariable
  false
    kind: keyword
  true
    kind: keyword
  p01
    kind: parameter
  null
    kind: keyword
  const
    kind: keyword
  switch
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
  c01
    kind: topLevelVariable
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
    // TODO(scheglov): This is wrong.
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
  false
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
''');
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
    // TODO(scheglov): This is wrong.
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
  false
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_expression() async {
    await computeSuggestions('''
int f(Object p01) {
  return switch (^) {};
}
''');
    assertResponse(r'''
suggestions
  p01
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
}
