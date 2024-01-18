// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNeverTest);
    defineReflectiveTests(InvalidUseOfNeverTest_Legacy);
  });
}

@reflectiveTest
class InvalidUseOfNeverTest extends PubPackageResolutionTest {
  test_binaryExpression_never_eqEq() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x == 1 + 2;
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 25, 6),
    ]);

    assertResolvedNodeText(findNode.binary('x =='), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  operator: ==
  rightOperand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticType: int
    parameter: <null>
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_binaryExpression_never_plus() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x + (1 + 2);
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 24, 8),
    ]);

    assertResolvedNodeText(findNode.binary('x +'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  operator: +
  rightOperand: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: IntegerLiteral
        literal: 1
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 2
        parameter: dart:core::@class::num::@method::+::@parameter::other
        staticType: int
      staticElement: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_binaryExpression_neverQ_eqEq() async {
    await assertNoErrorsInCode(r'''
void f(Never? x) {
  x == 1 + 2;
}
''');

    assertResolvedNodeText(findNode.binary('x =='), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  operator: ==
  rightOperand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticType: int
    parameter: dart:core::@class::Object::@method::==::@parameter::other
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  staticElement: dart:core::@class::Object::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_binaryExpression_neverQ_plus() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x + (1 + 2);
}
''', [
      error(
          CompileTimeErrorCode.UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE,
          23,
          1),
    ]);

    assertResolvedNodeText(findNode.binary('x +'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  operator: +
  rightOperand: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: IntegerLiteral
        literal: 1
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 2
        parameter: dart:core::@class::num::@method::+::@parameter::other
        staticType: int
      staticElement: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_conditionalExpression_falseBranch() async {
    await assertNoErrorsInCode(r'''
void f(bool c, Never x) {
  c ? 0 : x;
}
''');
  }

  test_conditionalExpression_trueBranch() async {
    await assertNoErrorsInCode(r'''
void f(bool c, Never x) {
  c ? x : 0;
}
''');
  }

  test_functionExpressionInvocation_never() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x();
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 21, 3),
    ]);
  }

  test_functionExpressionInvocation_neverQ() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE, 21, 1),
    ]);
  }

  test_indexExpression_never_read() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x[0];
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 22, 3),
    ]);

    assertResolvedNodeText(findNode.index('x[0]'), r'''
IndexExpression
  target: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  rightBracket: ]
  staticElement: <null>
  staticType: Never
''');
  }

  test_indexExpression_never_readWrite() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x[0] += 1 + 2;
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 22, 12),
    ]);

    var assignment = findNode.assignment('[0] +=');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Never
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticType: int
    parameter: <null>
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_never_write() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x[0] = 1 + 2;
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 22, 11),
    ]);

    assertResolvedNodeText(findNode.assignment('x[0]'), r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Never
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticType: int
    parameter: <null>
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_neverQ_read() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x[0];
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          22, 1),
    ]);

    assertResolvedNodeText(findNode.index('x[0]'), r'''
IndexExpression
  target: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  rightBracket: ]
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_neverQ_readWrite() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x[0] += 1 + 2;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          22, 1),
    ]);

    var assignment = findNode.assignment('[0] +=');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Never?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticType: int
    parameter: <null>
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_neverQ_write() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x[0] = 1 + 2;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          22, 1),
    ]);

    assertResolvedNodeText(findNode.assignment('x[0]'), r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Never?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticType: int
    parameter: <null>
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_invocationArgument() async {
    await assertNoErrorsInCode(r'''
void f(g, Never x) {
  g(x);
}
''');
  }

  test_methodInvocation_never() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x.foo(1 + 2);
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 25, 8),
    ]);

    var node = findNode.methodInvocation('.foo(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          parameter: dart:core::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_methodInvocation_never_toString() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x.toString(1 + 2);
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 30, 8),
    ]);

    var node = findNode.methodInvocation('.toString(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          parameter: dart:core::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_methodInvocation_neverQ_toString() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x.toString(1 + 2);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 32, 5),
    ]);

    var node = findNode.methodInvocation('.toString(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: dart:core::@class::Object::@method::toString
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          parameter: dart:core::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_postfixExpression_never_plusPlus() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x++;
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
    ]);

    assertResolvedNodeText(findNode.postfix('x++'), r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: Never
  writeElement: self::@function::f::@parameter::x
  writeType: Never
  staticElement: <null>
  staticType: Never
''');
  }

  test_postfixExpression_neverQ_plusPlus() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x++;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          22, 2),
    ]);

    assertResolvedNodeText(findNode.postfix('x++'), r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ++
  readElement: self::@function::f::@parameter::x
  readType: Never?
  writeElement: self::@function::f::@parameter::x
  writeType: Never?
  staticElement: <null>
  staticType: Never?
''');
  }

  test_prefixExpression_never_plusPlus() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(r'''
void f(Never x) {
  ++x;
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 22, 1),
    ]);

    assertResolvedNodeText(findNode.prefix('++x'), r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  readElement: self::@function::f::@parameter::x
  readType: Never
  writeElement: self::@function::f::@parameter::x
  writeType: Never
  staticElement: <null>
  staticType: Never
''');
  }

  test_prefixExpression_neverQ_plusPlus() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  ++x;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          21, 2),
    ]);

    assertResolvedNodeText(findNode.prefix('++x'), r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  readElement: self::@function::f::@parameter::x
  readType: Never?
  writeElement: self::@function::f::@parameter::x
  writeType: Never?
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_never_read() async {
    await assertNoErrorsInCode(r'''
void f(Never x) {
  x.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: Never
  staticElement: <null>
  staticType: Never
''');
  }

  test_propertyAccess_never_read_hashCode() async {
    await assertNoErrorsInCode(r'''
void f(Never x) {
  x.hashCode;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::@class::Object::@getter::hashCode
    staticType: Never
  staticElement: dart:core::@class::Object::@getter::hashCode
  staticType: Never
''');
  }

  test_propertyAccess_never_readWrite() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x.foo += 0;
}
''', [
      error(WarningCode.DEAD_CODE, 29, 2),
    ]);

    var assignment = findNode.assignment('foo += 0');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Never
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_never_tearOff_toString() async {
    await assertNoErrorsInCode(r'''
void f(Never x) {
  x.toString;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  period: .
  identifier: SimpleIdentifier
    token: toString
    staticElement: dart:core::@class::Object::@method::toString
    staticType: Never
  staticElement: dart:core::@class::Object::@method::toString
  staticType: Never
''');
  }

  test_propertyAccess_never_write() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x.foo = 0;
}
''', [
      error(WarningCode.DEAD_CODE, 28, 2),
    ]);

    var assignment = findNode.assignment('foo = 0');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Never
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_neverQ_read() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE,
          23, 3),
    ]);

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_neverQ_read_hashCode() async {
    await assertNoErrorsInCode(r'''
void f(Never? x) {
  x.hashCode;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticElement: dart:core::@class::Object::@getter::hashCode
  staticType: int
''');
  }

  test_propertyAccess_neverQ_tearOff_toString() async {
    await assertNoErrorsInCode(r'''
void f(Never? x) {
  x.toString;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  period: .
  identifier: SimpleIdentifier
    token: toString
    staticElement: dart:core::@class::Object::@method::toString
    staticType: String Function()
  staticElement: dart:core::@class::Object::@method::toString
  staticType: String Function()
''');
  }
}

@reflectiveTest
class InvalidUseOfNeverTest_Legacy extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_binaryExpression_eqEq() async {
    await assertNoErrorsInCode(r'''
void f() {
  (throw '') == 1 + 2;
}
''');

    assertResolvedNodeText(findNode.binary('=='), r'''
BinaryExpression
  leftOperand: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never*
    rightParenthesis: )
    staticType: Never*
  operator: ==
  rightOperand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int*
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      parameter: root::@parameter::other
      staticType: int*
    parameter: root::@parameter::other
    staticElement: MethodMember
      base: dart:core::@class::num::@method::+
      isLegacy: true
    staticInvokeType: num* Function(num*)*
    staticType: int*
  staticElement: MethodMember
    base: dart:core::@class::Object::@method::==
    isLegacy: true
  staticInvokeType: bool* Function(Object*)*
  staticType: bool*
''');
  }

  test_binaryExpression_plus() async {
    await assertNoErrorsInCode(r'''
void f() {
  (throw '') + (1 + 2);
}
''');

    assertResolvedNodeText(findNode.binary('+ ('), r'''
BinaryExpression
  leftOperand: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never*
    rightParenthesis: )
    staticType: Never*
  operator: +
  rightOperand: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: IntegerLiteral
        literal: 1
        staticType: int*
      operator: +
      rightOperand: IntegerLiteral
        literal: 2
        parameter: root::@parameter::other
        staticType: int*
      staticElement: MethodMember
        base: dart:core::@class::num::@method::+
        isLegacy: true
      staticInvokeType: num* Function(num*)*
      staticType: int*
    rightParenthesis: )
    parameter: <null>
    staticType: int*
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');

    assertType(findNode.binary('1 + 2'), 'int');
  }

  test_methodInvocation_toString() async {
    await assertNoErrorsInCode(r'''
void f() {
  (throw '').toString();
}
''');

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never*
    rightParenthesis: )
    staticType: Never*
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_propertyAccess_toString() async {
    await assertNoErrorsInCode(r'''
void f() {
  (throw '').toString;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never*
    rightParenthesis: )
    staticType: Never*
  operator: .
  propertyName: SimpleIdentifier
    token: toString
    staticElement: MethodMember
      base: dart:core::@class::Object::@method::toString
      isLegacy: true
    staticType: String* Function()*
  staticType: String* Function()*
''');
  }

  test_throw_getter_hashCode() async {
    await assertNoErrorsInCode(r'''
void f() {
  (throw '').hashCode;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never*
    rightParenthesis: )
    staticType: Never*
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: PropertyAccessorMember
      base: dart:core::@class::Object::@getter::hashCode
      isLegacy: true
    staticType: int*
  staticType: int*
''');
  }
}
