// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrefixExpressionResolutionTest extends PubPackageResolutionTest {
  test_bang_bool_context() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>() {
  throw 42;
}

main() {
  !f();
}
''');

    var node = result.findNode.methodInvocation('f();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_bang_bool_localVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  !x;
}
''');

    var node = result.findNode.logicalNot('!x');
    assertResolvedNodeText(node, r'''
LogicalNot
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: bool
  staticType: bool
V1: PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: bool
  element: <null>
  staticType: bool
''');
  }

  test_bang_int_localVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  !x;
// ^
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
}
''');

    var node = result.findNode.logicalNot('!x');
    assertResolvedNodeText(node, r'''
LogicalNot
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  staticType: bool
V1: PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  element: <null>
  staticType: bool
''');
  }

  test_bang_no_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool get foo => true;
}

void f(A? a) {
  !a?.foo;
// ^^^^^^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');

    var node = result.findNode.logicalNot('!a');
    assertResolvedNodeText(node, r'''
LogicalNot
  operator: !
  operand: PropertyAccess
    target2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: bool
    staticType: bool?
  staticType: bool
V1: PrefixExpression
  operator: !
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: bool
    staticType: bool?
  element: <null>
  staticType: bool
''');
  }

  test_bang_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    !super;
//   ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.nonBoolNegationExpression] A negation operand must have a static type of 'bool'.
  }
}
''');

    var node = result.findNode.singleLogicalNot;
    assertResolvedNodeText(node, r'''
LogicalNot
  operator: !
  operand: SuperExpression
    superKeyword: super
    staticType: A
  staticType: bool
V1: PrefixExpression
  operator: !
  operand: SuperExpression
    superKeyword: super
    staticType: A
  element: <null>
  staticType: bool
''');
  }

  test_formalParameter_inc_inc() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  ++ ++ x;
//      ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');

    var node = result.findNode.prefixIncrement('++ ++ x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: InvalidExpressionAssignmentTarget
    expression: PrefixIncrement
      operator: ++
      target: UnqualifiedNameAssignmentTarget
        name: x
        read: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          type: int
        write: VariableWriteResolution
          element: <testLibrary>::@function::f::@formalParameter::x
          acceptedType: int
      element: dart:core::@class::num::@method::+
      operatorResultType: int
      staticType: int
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: int
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: int
    element: dart:core::@class::num::@method::+
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_formalParameter_inc_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A a) {
  ++a;
//^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.prefixIncrement('++a');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: a
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      acceptedType: A
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::a
  readType: A
  writeElement: <testLibrary>::@function::f::@formalParameter::a
  writeType: A
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_indexExpression_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  ++a[0];
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_indexExpression_instance_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A? a) {
  ++a?[0];
}
''');

    var node = result.findNode.prefixIncrement('++a?[0]');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverIndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int?
V1: PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int?
''');
  }

  test_inc_indexExpression_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    ++super[0];
  }
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverIndexAssignmentTarget
    receiver: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_indexExpression_this() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    ++this[0];
  }
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverIndexAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_inc_unresolvedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  ++x;
//  ^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
      recovery: <null>
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_minus_dynamicIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  -a;
}
''');

    var node = result.findNode.singleUnaryOperatorInvocation;
    assertResolvedNodeText(node, r'''
UnaryOperatorInvocation
  operator: -
  operand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  unaryOperator: negate
  element: <null>
  staticType: dynamic
V1: PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_minus_no_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  -a?.foo;
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'unary-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.unaryOperatorInvocation('-a');
    assertResolvedNodeText(node, r'''
UnaryOperatorInvocation
  operator: -
  operand: PropertyAccess
    target2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  unaryOperator: negate
  element: dart:core::@class::int::@method::unary-
  staticType: int
V1: PrefixExpression
  operator: -
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  element: dart:core::@class::int::@method::unary-
  staticType: int
''');
  }

  test_minus_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  -x;
}
''');

    var node = result.findNode.unaryOperatorInvocation('-x');
    assertResolvedNodeText(node, r'''
UnaryOperatorInvocation
  operator: -
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  unaryOperator: negate
  element: dart:core::@class::int::@method::unary-
  staticType: int
V1: PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  element: dart:core::@class::int::@method::unary-
  staticType: int
''');
  }

  test_plusPlus_depromote() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  Object operator +(int _) => this;
}

void f(Object x) {
  if (x is A) {
    ++x;
  }
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: A
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: Object
  element: <testLibrary>::@class::A::@method::+
  operatorResultType: Object
  staticType: Object
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: A
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object
  element: <testLibrary>::@class::A::@method::+
  staticType: Object
''');
  }

  test_plusPlus_notLValue_extensionOverride() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension Ext on C {
  int operator +(int _) {
    return 0;
  }
}

void f(C c) {
  ++Ext(c);
//       ^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');

    var node = result.findNode.prefixIncrement('++Ext');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: InvalidExpressionAssignmentTarget
    expression: ExtensionOverride
      name: Ext
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          SimpleIdentifier
            token: c
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::c
            staticType: C
        rightParenthesis: )
      element: <testLibrary>::@extension::Ext
      extendedType: C
      staticType: null
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: ExtensionOverride
    name: Ext
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: c
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::c
          staticType: C
      rightParenthesis: )
    element: <testLibrary>::@extension::Ext
    extendedType: C
    staticType: null
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_notLValue_simpleIdentifier_typeLiteral() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  ++int;
//  ^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.prefixIncrement('++int');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: int
    read: InvalidNamedReadResolution
      type: InvalidType
      candidates
        candidate: dart:core::@class::int
      recovery: <null>
    write: InvalidNamedWriteResolution
      acceptedType: InvalidType
      candidates
        candidate: dart:core::@class::int
      recovery: <null>
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  readElement: dart:core::@class::int
  readType: InvalidType
  writeElement: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  ++a?.foo;
}
''');

    var node = result.findNode.prefixIncrement('++a');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int?
V1: PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int?
''');
  }

  test_plusPlus_ofExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  ++a.foo;
}
''');

    var node = result.findNode.singlePrefixIncrement;
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@extensionType::A::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@extensionType::A::@setter::foo
      acceptedType: int
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@extensionType::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extensionType::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
}

void f(A a) {
  ++a.x;
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: int
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  ++p.x;
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverPropertyAssignmentTarget
    receiver: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: package:test/a.dart::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: package:test/a.dart::@setter::x
      acceptedType: int
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_instance() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
}

void f() {
  ++A().x;
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverPropertyAssignmentTarget
    receiver: ConstructorInvocation
      constructorReference: ConstructorReference2
        typeReference: ConstructorTypeReference
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: int
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++super.x;
  }
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_this() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++this.x;
  }
}
''');

    var node = result.findNode.prefixIncrement('++');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: ReceiverPropertyAssignmentTarget
    receiver: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(double x) {
  ++x;
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: double
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: double
  element: dart:core::@class::double::@method::+
  operatorResultType: double
  staticType: double
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: double
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: double
  element: dart:core::@class::double::@method::+
  staticType: double
''');
  }

  test_plusPlus_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  ++x;
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: int
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: int
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: int
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_num() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  ++x;
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: num
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: num
  staticType: num
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: num
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_parameter_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>(T x) {
  ++x;
//^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      type: T
    write: VariableWriteResolution
      element: <testLibrary>::@function::f::@formalParameter::x
      acceptedType: T
  element: dart:core::@class::num::@method::+
  operatorResultType: num
  staticType: num
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: T
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: T
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_superSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

class B extends A {
  int get x => 0;
  void f() {
    ++x;
  }
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::B::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::B::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_thisSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
  void f() {
    ++x;
  }
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::x
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get x => 0;

set x(num _) {}

void f() {
  ++x;
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter_fromClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    ++x;
  }
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: num
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_plusPlus_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    ++super;
//    ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singlePrefixIncrement;
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: InvalidExpressionAssignmentTarget
    expression: SuperExpression
      superKeyword: super
      staticType: A
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SuperExpression
    superKeyword: super
    staticType: A
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  ++switch (x) {
    _ => 0,
  };
//^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
}
''');

    var node = result.findNode.prefixIncrement('++switch');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: InvalidExpressionAssignmentTarget
    expression: SwitchExpression
      switchKeyword: switch
      leftParenthesis: (
      expression2: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: Object?
      rightParenthesis: )
      leftBracket: {
      cases
        SwitchExpressionCase
          guardedPattern: GuardedPattern
            pattern: WildcardPattern
              name: _
              matchedValueType: Object?
          arrow: =>
          expression2: IntegerLiteral
            literal: 0
            staticType: int
      rightBracket: }
      staticType: int
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PrefixExpression
  operator: ++
  operand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightBracket: }
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Verify that we get all necessary types when building the dependencies
  /// graph during top-level inference.
  test_plusPlus_topLevelInference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = 0;

class A {
  final y = ++x;
}
''');

    var node = result.findNode.prefixIncrement('++x');
    assertResolvedNodeText(node, r'''
PrefixIncrement
  operator: ++
  target: UnqualifiedNameAssignmentTarget
    name: x
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::x
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::x
      acceptedType: int
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_tilde_no_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  ~a?.foo;
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '~' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.unaryOperatorInvocation('~a');
    assertResolvedNodeText(node, r'''
UnaryOperatorInvocation
  operator: ~
  operand: PropertyAccess
    target2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  unaryOperator: bitwiseComplement
  element: dart:core::@class::int::@method::~
  staticType: int
V1: PrefixExpression
  operator: ~
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int?
  element: dart:core::@class::int::@method::~
  staticType: int
''');
  }

  test_tilde_simpleIdentifier_parameter_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  ~x;
}
''');

    var node = result.findNode.unaryOperatorInvocation('~x');
    assertResolvedNodeText(node, r'''
UnaryOperatorInvocation
  operator: ~
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  unaryOperator: bitwiseComplement
  element: dart:core::@class::int::@method::~
  staticType: int
V1: PrefixExpression
  operator: ~
  operand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int
  element: dart:core::@class::int::@method::~
  staticType: int
''');
  }
}
