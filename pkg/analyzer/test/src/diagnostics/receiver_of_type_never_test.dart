// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNeverTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidUseOfNeverTest extends PubPackageResolutionTest {
  test_binaryExpression_eqEq() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (throw '') == 1 + 2;
//^^^^^^^^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//           ^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.binaryOperatorInvocation('==');
    assertResolvedNodeText(node, r'''
BinaryOperatorInvocation
  leftOperand: ParenthesizedExpression
    leftParenthesis: (
    expression2: ThrowExpression
      throwKeyword: throw
      expression2: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: ==
  rightOperand: BinaryOperatorInvocation
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  binaryOperator: equal
  element: <null>
  staticType: Never
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
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_binaryExpression_never_eqEq() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x == 1 + 2;
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//  ^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.binaryOperatorInvocation('x ==');
    assertResolvedNodeText(node, r'''
BinaryOperatorInvocation
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  operator: ==
  rightOperand: BinaryOperatorInvocation
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  binaryOperator: equal
  element: <null>
  staticType: Never
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
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_binaryExpression_never_plus() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x + (1 + 2);
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.binaryOperatorInvocation('x +');
    assertResolvedNodeText(node, r'''
BinaryOperatorInvocation
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  operator: +
  rightOperand: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryOperatorInvocation
      leftOperand: IntegerLiteral
        literal: 1
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 2
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      binaryOperator: add
      element: dart:core::@class::num::@method::+
      staticType: int
    expression(v1): BinaryExpression
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
  binaryOperator: add
  element: <null>
  staticType: Never
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x == 1 + 2;
}
''');

    var node = result.findNode.binaryOperatorInvocation('x ==');
    assertResolvedNodeText(node, r'''
BinaryOperatorInvocation
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  operator: ==
  rightOperand: BinaryOperatorInvocation
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  binaryOperator: equal
  element: dart:core::@class::Object::@method::==
  staticType: bool
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
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  element: dart:core::@class::Object::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_binaryExpression_neverQ_plus() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x + (1 + 2);
//  ^
// [diag.uncheckedOperatorInvocationOfNullableValue] The operator '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.binaryOperatorInvocation('x +');
    assertResolvedNodeText(node, r'''
BinaryOperatorInvocation
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  operator: +
  rightOperand: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryOperatorInvocation
      leftOperand: IntegerLiteral
        literal: 1
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 2
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      binaryOperator: add
      element: dart:core::@class::num::@method::+
      staticType: int
    expression(v1): BinaryExpression
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
  binaryOperator: add
  element: <null>
  staticType: InvalidType
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (throw '') + (1 + 2);
//^^^^^^^^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//           ^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.binaryOperatorInvocation('+ (');
    assertResolvedNodeText(node, r'''
BinaryOperatorInvocation
  leftOperand: ParenthesizedExpression
    leftParenthesis: (
    expression2: ThrowExpression
      throwKeyword: throw
      expression2: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: +
  rightOperand: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryOperatorInvocation
      leftOperand: IntegerLiteral
        literal: 1
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 2
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      binaryOperator: add
      element: dart:core::@class::num::@method::+
      staticType: int
    expression(v1): BinaryExpression
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
  binaryOperator: add
  element: <null>
  staticType: Never
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

    assertType(result.findNode.binaryOperatorInvocation('1 + 2'), 'int');
  }

  test_conditionalExpression_falseBranch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c, Never x) {
  c ? 0 : x;
}
''');
  }

  test_conditionalExpression_trueBranch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c, Never x) {
  c ? x : 0;
}
''');
  }

  test_functionExpressionInvocation_never() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x();
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
// ^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_functionExpressionInvocation_neverQ() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x();
//^
// [diag.uncheckedInvocationOfNullableValue] The function can't be unconditionally invoked because it can be 'null'.
}
''');
  }

  test_indexExpression_never_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x[0];
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//  ^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.index('x[0]');
    assertResolvedNodeText(node, r'''
IndexExpression
  target2: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
  leftBracket: [
  index2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: Never
''');
  }

  test_indexExpression_never_readWrite() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x[0] += 1 + 2;
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//  ^^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.assignment('[0] +=');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: IndexExpression
    target2: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
    leftBracket: [
    index2: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: BinaryOperatorInvocation
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  rightHandSide(v1): BinaryExpression
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_never_write() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x[0] = 1 + 2;
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//  ^^^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.assignment('x[0]');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: IndexExpression
    target2: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
    leftBracket: [
    index2: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: BinaryOperatorInvocation
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  rightHandSide(v1): BinaryExpression
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_neverQ_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x[0];
// ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '[]' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.index('x[0]');
    assertResolvedNodeText(node, r'''
IndexExpression
  target2: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
  leftBracket: [
  index2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_neverQ_readWrite() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x[0] += 1 + 2;
// ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '[]' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.assignment('[0] +=');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: IndexExpression
    target2: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never?
    leftBracket: [
    index2: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: BinaryOperatorInvocation
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  rightHandSide(v1): BinaryExpression
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_indexExpression_neverQ_write() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x[0] = 1 + 2;
// ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '[]' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.assignment('x[0]');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: IndexExpression
    target2: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never?
    leftBracket: [
    index2: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: BinaryOperatorInvocation
    leftOperand: IntegerLiteral
      literal: 1
      staticType: int
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      staticType: int
    correspondingParameter: <null>
    binaryOperator: add
    element: dart:core::@class::num::@method::+
    staticType: int
  rightHandSide(v1): BinaryExpression
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_invocationArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(g, Never x) {
  g(x);
}
''');
  }

  test_methodInvocation_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x.foo(1 + 2);
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//     ^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.methodInvocation('.foo(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target2: SimpleIdentifier
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
    arguments2
      BinaryOperatorInvocation
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        binaryOperator: add
        element: dart:core::@class::num::@method::+
        staticType: int
    arguments(v1)
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x.toString(1 + 2);
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//          ^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.methodInvocation('.toString(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target2: SimpleIdentifier
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
    arguments2
      BinaryOperatorInvocation
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        binaryOperator: add
        element: dart:core::@class::num::@method::+
        staticType: int
    arguments(v1)
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x.toString(1 + 2);
//           ^^^^^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
}
''');

    var node = result.findNode.methodInvocation('.toString(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target2: SimpleIdentifier
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
    arguments2
      BinaryOperatorInvocation
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        binaryOperator: add
        element: dart:core::@class::num::@method::+
        staticType: int
    arguments(v1)
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (throw '').toString();
//^^^^^^^^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//                   ^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target2: ParenthesizedExpression
    leftParenthesis: (
    expression2: ThrowExpression
      throwKeyword: throw
      expression2: SimpleStringLiteral
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

  test_postfixIncrement_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x++;
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  element: <null>
  operatorResultType: Never
  staticType: Never
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: Never
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never
  element: <null>
  staticType: Never
''');
  }

  test_postfixIncrement_neverQ() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x++;
// ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.postfixIncrement('x++');
    assertResolvedNodeText(node, r'''
PostfixIncrement
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  element: <null>
  operatorResultType: dynamic
  staticType: Never?
PostfixExpression
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ++
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: Never?
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never?
  element: <null>
  staticType: Never?
''');
  }

  test_prefixExpression_never_plusPlus() async {
    // Reports 'undefined operator'
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  ++x;
//  ^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  element: <null>
  operatorResultType: Never
  staticType: Never
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: Never
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never
  element: <null>
  staticType: Never
''');
  }

  test_prefixExpression_neverQ_plusPlus() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  ++x;
//^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: Never?
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Never?
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_never_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x.foo;
//  ^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.singlePrefixedIdentifier;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x.hashCode;
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.singlePrefixedIdentifier;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x.foo += 0;
//         ^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.assignment('foo += 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
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
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_never_tearOff_toString() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x.toString;
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.singlePrefixedIdentifier;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x.foo = 0;
//        ^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.assignment('foo = 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
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
  rightHandSide2: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_neverQ_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x.foo;
//  ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
}
''');

    var node = result.findNode.singlePrefixedIdentifier;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x.hashCode;
}
''');

    var node = result.findNode.singlePrefixedIdentifier;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x.toString;
}
''');

    var node = result.findNode.singlePrefixedIdentifier;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (throw '').toString;
//^^^^^^^^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: ThrowExpression
      throwKeyword: throw
      expression2: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: .
  propertyName: toString
  resolution: <null>
  staticType: Never
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
    element: <null>
    staticType: Never
  staticType: Never
''');
  }

  test_throw_getter_hashCode() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (throw '').hashCode;
//^^^^^^^^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: ThrowExpression
      throwKeyword: throw
      expression2: SimpleStringLiteral
        literal: ''
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: .
  propertyName: hashCode
  resolution: <null>
  staticType: Never
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
    element: <null>
    staticType: Never
  staticType: Never
''');
  }
}
