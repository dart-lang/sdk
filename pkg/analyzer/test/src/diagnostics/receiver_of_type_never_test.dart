// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNeverTest);
  });
}

@reflectiveTest
class InvalidUseOfNeverTest extends PubPackageResolutionTest {
  test_binaryExpression_eqEq() async {
    await assertErrorsInCode(
      r'''
void f() {
  (throw '') == 1 + 2;
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 13, 10),
        error(WarningCode.deadCode, 24, 8),
      ],
    );

    assertResolvedNodeText(findNode.binary('=='), r'''
BinaryExpression
  leftOperand: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: ==
  rightOperand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_binaryExpression_never_eqEq() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x == 1 + 2;
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 22, 8),
      ],
    );

    assertResolvedNodeText(findNode.binary('x =='), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  operator: ==
  rightOperand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_binaryExpression_never_plus() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x + (1 + 2);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 22, 9),
      ],
    );

    assertResolvedNodeText(findNode.binary('x +'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    correspondingParameter: <null>
    staticType: int
  element: <null>
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
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  operator: ==
  rightOperand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  element: dart:core::@class::Object::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_binaryExpression_neverQ_plus() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x + (1 + 2);
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedOperatorInvocationOfNullableValue,
          23,
          1,
        ),
      ],
    );

    assertResolvedNodeText(findNode.binary('x +'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_binaryExpression_plus() async {
    await assertErrorsInCode(
      r'''
void f() {
  (throw '') + (1 + 2);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 13, 10),
        error(WarningCode.deadCode, 24, 9),
      ],
    );

    assertResolvedNodeText(findNode.binary('+ ('), r'''
BinaryExpression
  leftOperand: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
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
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: Never
''');

    assertType(findNode.binary('1 + 2'), 'int');
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
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x();
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 21, 3),
      ],
    );
  }

  test_functionExpressionInvocation_neverQ() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x();
}
''',
      [error(CompileTimeErrorCode.uncheckedInvocationOfNullableValue, 21, 1)],
    );
  }

  test_indexExpression_never_read() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x[0];
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 22, 3),
      ],
    );

    assertResolvedNodeText(findNode.index('x[0]'), r'''
IndexExpression
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: Never
''');
  }

  test_indexExpression_never_readWrite() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x[0] += 1 + 2;
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 22, 12),
      ],
    );

    var assignment = findNode.assignment('[0] +=');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_never_write() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x[0] = 1 + 2;
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 22, 11),
      ],
    );

    assertResolvedNodeText(findNode.assignment('x[0]'), r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_neverQ_read() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x[0];
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          22,
          1,
        ),
      ],
    );

    assertResolvedNodeText(findNode.index('x[0]'), r'''
IndexExpression
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_neverQ_readWrite() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x[0] += 1 + 2;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          22,
          1,
        ),
      ],
    );

    var assignment = findNode.assignment('[0] +=');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_neverQ_write() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x[0] = 1 + 2;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          22,
          1,
        ),
      ],
    );

    assertResolvedNodeText(findNode.assignment('x[0]'), r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
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
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x.foo(1 + 2);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 25, 8),
      ],
    );

    var node = findNode.methodInvocation('.foo(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
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
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        element: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_methodInvocation_never_toString() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x.toString(1 + 2);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 30, 8),
      ],
    );

    var node = findNode.methodInvocation('.toString(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
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
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        element: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_methodInvocation_neverQ_toString() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x.toString(1 + 2);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 32, 5)],
    );

    var node = findNode.methodInvocation('.toString(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: dart:core::@class::Object::@method::toString
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
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        element: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_methodInvocation_toString() async {
    await assertErrorsInCode(
      r'''
void f() {
  (throw '').toString();
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 13, 10),
        error(WarningCode.deadCode, 32, 3),
      ],
    );

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_postfixExpression_never_plusPlus() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x++;
}
''',
      [error(WarningCode.receiverOfTypeNever, 20, 1)],
    );

    assertResolvedNodeText(findNode.postfix('x++'), r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: Never
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never
  element: <null>
  staticType: Never
''');
  }

  test_postfixExpression_neverQ_plusPlus() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x++;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          22,
          2,
        ),
      ],
    );

    assertResolvedNodeText(findNode.postfix('x++'), r'''
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: Never?
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never?
  element: <null>
  staticType: Never?
''');
  }

  test_prefixExpression_never_plusPlus() async {
    // Reports 'undefined operator'
    await assertErrorsInCode(
      r'''
void f(Never x) {
  ++x;
}
''',
      [error(WarningCode.receiverOfTypeNever, 22, 1)],
    );

    assertResolvedNodeText(findNode.prefix('++x'), r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: Never
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never
  element: <null>
  staticType: Never
''');
  }

  test_prefixExpression_neverQ_plusPlus() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  ++x;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          21,
          2,
        ),
      ],
    );

    assertResolvedNodeText(findNode.prefix('++x'), r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: Never?
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never?
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_never_read() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x.foo;
}
''',
      [error(WarningCode.deadCode, 22, 4)],
    );

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: Never
  element: <null>
  staticType: Never
''');
  }

  test_propertyAccess_never_read_hashCode() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x.hashCode;
}
''',
      [error(WarningCode.deadCode, 22, 9)],
    );

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
    staticType: Never
  element: dart:core::@class::Object::@getter::hashCode
  staticType: Never
''');
  }

  test_propertyAccess_never_readWrite() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x.foo += 0;
}
''',
      [error(WarningCode.deadCode, 29, 2)],
    );

    var assignment = findNode.assignment('foo += 0');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_never_tearOff_toString() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x.toString;
}
''',
      [error(WarningCode.deadCode, 22, 9)],
    );

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  period: .
  identifier: SimpleIdentifier
    token: toString
    element: dart:core::@class::Object::@method::toString
    staticType: Never
  element: dart:core::@class::Object::@method::toString
  staticType: Never
''');
  }

  test_propertyAccess_never_write() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x.foo = 0;
}
''',
      [error(WarningCode.deadCode, 28, 2)],
    );

    var assignment = findNode.assignment('foo = 0');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_neverQ_read() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x.foo;
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue,
          23,
          3,
        ),
      ],
    );

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_neverQ_read_hashCode() async {
    await assertNoErrorsInCode(r'''
void f(Never? x) {
  x.hashCode;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
    staticType: int
  element: dart:core::@class::Object::@getter::hashCode
  staticType: int
''');
  }

  test_propertyAccess_neverQ_tearOff_toString() async {
    await assertNoErrorsInCode(r'''
void f(Never? x) {
  x.toString;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  period: .
  identifier: SimpleIdentifier
    token: toString
    element: dart:core::@class::Object::@method::toString
    staticType: String Function()
  element: dart:core::@class::Object::@method::toString
  staticType: String Function()
''');
  }

  test_propertyAccess_toString() async {
    await assertErrorsInCode(
      r'''
void f() {
  (throw '').toString;
}
''',
      [error(WarningCode.deadCode, 24, 9)],
    );

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: .
  propertyName: SimpleIdentifier
    token: toString
    element: dart:core::@class::Object::@method::toString
    staticType: String Function()
  staticType: String Function()
''');
  }

  test_throw_getter_hashCode() async {
    await assertErrorsInCode(
      r'''
void f() {
  (throw '').hashCode;
}
''',
      [error(WarningCode.deadCode, 24, 9)],
    );

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: ThrowExpression
      throwKeyword: throw
      expression: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticType: int
''');
  }
}
