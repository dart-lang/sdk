// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelationalPatternResolutionTest);
  });
}

@reflectiveTest
class RelationalPatternResolutionTest extends PubPackageResolutionTest {
  test_equal_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::==
  matchedValueType: A
''');
  }

  test_equal_ofObject() async {
    await assertNoErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: dart:core::@class::Object::@method::==
  matchedValueType: A
''');
  }

  test_greaterThan_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator >(_) => true;
}

void f(A x) {
  switch (x) {
    case > 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::>
  matchedValueType: A
''');
  }

  test_greaterThan_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator >(_) => true;
}

void f(A x) {
  switch (x) {
    case > 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@extension::E::@method::>
  matchedValueType: A
''');
  }

  test_greaterThan_unresolved() async {
    await assertErrorsInCode(
      r'''
class A {}

void f(A x) {
  switch (x) {
    case > 0:
      break;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 50, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <null>
  matchedValueType: A
''');
  }

  test_greaterThanOrEqualTo_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator >=(_) => true;
}

void f(A x) {
  switch (x) {
    case >= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::>=
  matchedValueType: A
''');
  }

  test_greaterThanOrEqualTo_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator >=(_) => true;
}

void f(A x) {
  switch (x) {
    case >= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@extension::E::@method::>=
  matchedValueType: A
''');
  }

  test_greaterThanOrEqualTo_unresolved() async {
    await assertErrorsInCode(
      r'''
class A {}

void f(A x) {
  switch (x) {
    case >= 0:
      break;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 50, 2)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <null>
  matchedValueType: A
''');
  }

  test_ifCase() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  if (x case == 0) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::==
  matchedValueType: A
''');
  }

  test_lessThan_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator <(_) => true;
}

void f(A x) {
  switch (x) {
    case < 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::<
  matchedValueType: A
''');
  }

  test_lessThan_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator <(_) => true;
}

void f(A x) {
  switch (x) {
    case < 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@extension::E::@method::<
  matchedValueType: A
''');
  }

  test_lessThan_unresolved() async {
    await assertErrorsInCode(
      r'''
class A {}

void f(A x) {
  switch (x) {
    case < 0:
      break;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 50, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <null>
  matchedValueType: A
''');
  }

  test_lessThanOrEqualTo_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator <=(_) => true;
}

void f(A x) {
  switch (x) {
    case <= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::<=
  matchedValueType: A
''');
  }

  test_lessThanOrEqualTo_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator <=(_) => true;
}

void f(A x) {
  switch (x) {
    case <= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@extension::E::@method::<=
  matchedValueType: A
''');
  }

  test_lessThanOrEqualTo_unresolved() async {
    await assertErrorsInCode(
      r'''
class A {}

void f(A x) {
  switch (x) {
    case <= 0:
      break;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedOperator, 50, 2)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <null>
  matchedValueType: A
''');
  }

  test_notEqual_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  switch (x) {
    case != 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: !=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::==
  matchedValueType: A
''');
  }

  test_notEqual_ofObject() async {
    await assertNoErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case != 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: !=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: dart:core::@class::Object::@method::==
  matchedValueType: A
''');
  }

  test_rewrite_operand() async {
    await assertErrorsInCode(
      r'''
void f(x, int Function() a) {
  switch (x) {
    case == a():
      break;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.nonConstantRelationalPatternExpression,
          57,
          3,
        ),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  element2: dart:core::@class::Object::@method::==
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element2: <testLibrary>::@class::A::@method::==
  matchedValueType: A
''');
  }
}
