// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedInstanceMemberWriteTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedInstanceMemberWriteTest extends PubPackageResolutionTest {
  test_const_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  const int foo = 0;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
}

void f(C c) {
  c.foo = 0;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_extensionField_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  final int foo = 0;
//          ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}

void f() {
  0.foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: IntegerLiteral
      literal: 0
      staticType: int
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@extension::E::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: IntegerLiteral
      literal: 0
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_extensionField_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  final int foo = 0;
//          ^^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}

void f() {
  0.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: IntegerLiteral
      literal: 0
      staticType: int
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: IntegerLiteral
      literal: 0
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_extensionTypeField_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type X(int it) {
  final int foo = 0;
//          ^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}

void f(X x) {
  x.foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: x
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::x
        type: X
      staticType: X
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@extensionType::X::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extensionType::X::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: X
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extensionType::X::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extensionType::X::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_extensionTypeField_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type X(int it) {
  final int foo = 0;
//          ^^^
// [diag.extensionTypeDeclaresInstanceField] Extension types can't declare instance fields.
}

void f(X x) {
  x.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: x
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::x
        type: X
      staticType: X
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extensionType::X::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: X
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extensionType::X::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_cascadeCompoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
}

void f(C c) {
  c..foo += 1;
//   ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_cascadeDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
}

void f(C c) {
  c..foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
}

void f(C c) {
  c.foo += 1;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_abstractFinalField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  abstract final int foo;
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_extensionTypeRepresentation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type C(int foo) {}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extensionType::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extensionType::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_externalFinalField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  external final int foo;
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_lateFinalField_hasInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  late final int foo = 0;
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
}

void f(C c) {
  c.foo ??= 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
//          ^^
// [diag.deadCode] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
}

void f(C c) {
  c.foo++;
//  ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_nullAwareDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final int foo = 0;
}

void f(C? c) {
  c?.foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteFinal] The field 'foo' of the type 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C?
      staticType: C?
    operator: ?.
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int?
''');
  }

  test_found_cascadeDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
}

void f(C c) {
  c..foo = 0;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
}

void f(C c) {
  c.foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
}

void f(C c) {
  c.foo = 0;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_abstractField() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
void f(A a, int x) {
  a.x = x;
}
''');
  }

  test_found_directAssignment_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on C {
  set foo(int _) {}
}

void f(C c) {
  c.foo = 0;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::#0::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::#0::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
    correspondingParameter: <testLibrary>::@extension::#0::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::#0::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_externalField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
void f(A a, int x) {
  a.x = x;
}
''');
  }

  test_found_directAssignment_lateFinalField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  late final int foo;
}

void f(C c) {
  c.foo = 0;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_typeLiteralExtension() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');
  }

  test_getterOnly_cascadeCompoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f(C c) {
  c..foo += 1;
//   ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_cascadeDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f(C c) {
  c..foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f(C c) {
  c.foo += 1;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on C {
  int get foo => 0;
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::#0::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::#0::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension on void Function() {
  int get foo => 0;
}

void f(void Function() c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'void Function()', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: void Function()
      staticType: void Function()
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::#0::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: void Function()
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::#0::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_inherited() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

class C extends A {}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_object() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.hashCode = 0;
//  ^^^^^^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'hashCode' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: hashCode
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: dart:core::@class::Object::@getter::hashCode
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: dart:core::@class::Object::@getter::hashCode
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_recordField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, {int foo}) c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type '(int, {int foo})', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: (int, {int foo})
      staticType: (int, {int foo})
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: (int, {int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_getterOnly_directAssignment_recordField_extensionHasSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension on (int, {int foo}) {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f((int, {int foo}) c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type '(int, {int foo})', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: (int, {int foo})
      staticType: (int, {int foo})
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: (int, {int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_getterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f(C c) {
  c.foo ??= 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
//          ^^
// [diag.deadCode] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f(C c) {
  c.foo++;
//  ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_nullAwareDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f(C? c) {
  c?.foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteGetterOnly] There's a getter 'foo' for the type 'C', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C?
      staticType: C?
    operator: ?.
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int?
''');
  }

  test_notFound_cascadeCompoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c..foo += 1;
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
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

  test_notFound_cascadeDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c..foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_notFound_cascadeDirectAssignment_new() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c..new = 1;
//   ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'new' isn't defined for the type 'C?'.
}
''');
  }

  test_notFound_cascadeDirectAssignment_typeLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
class T {
  static void set foo(_) {}
}
main() {
  T..foo = 42;
//   ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'Type'.
}
''');
  }

  test_notFound_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.foo += 1;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
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

  test_notFound_compoundAssignment_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
}

void f(C c) {
  c.foo += 1;
//  ^^^
// [diag.instanceAccessToStaticMember] The static getter 'foo' can't be accessed through an instance.
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_notFound_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_ambiguousExtensions() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E1 on C {
  set foo(int _) {}
}

extension E2 on C {
  set foo(int _) {}
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'foo' is defined in 'extension E1 on C' and 'extension E2 on C', and neither is more specific.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_extensionNotApplicable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on String {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_extensionStatic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}

extension E on C {
  static set a(int v) {}
}

f(C c) {
  c.a = 2;
//  ^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'a' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.directAssignment('a =');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: a
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: a
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
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

  test_notFound_directAssignment_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type C(int it) {}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_extensionWithoutMember() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E on C {}

f(C c) {
  c.a = 1;
//  ^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'a' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_directAssignment_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(void Function() c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'void Function()'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: void Function()
      staticType: void Function()
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: void Function()
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_mixinThis() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  f() { this.m = 0; }
//           ^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'm' isn't defined for the type 'M'.
}
''');
  }

  test_notFound_directAssignment_new() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C c) {
  c.new = 1;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_directAssignment_new_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f(dynamic d) {
  d.new = 1;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'new' isn't defined for the type 'dynamic'.
}
''');
  }

  test_notFound_directAssignment_new_typeParameter() async {
    await resolveTestCodeWithDiagnostics('''
f<T>(T t) {
  t.new = 1;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'new' isn't defined for the type 'T'.
}
''');
  }

  test_notFound_directAssignment_nullableReceiver() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C? c) {
  c.foo = 0;
//  ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C?
      staticType: C?
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C?
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c._foo = 0;
//  ^^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter '_foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_notFound_directAssignment_promotedDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(a) {
  if(a is A) {
    a.m = 0;
//    ^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'm' isn't defined for the type 'A'.
  }
}
''');
  }

  test_notFound_directAssignment_record() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, {int bar}) c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type '(int, {int bar})'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: (int, {int bar})
      staticType: (int, {int bar})
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: (int, {int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_notFound_directAssignment_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_subtypeHasSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(a) {
  if (a is A) {
    a.b = 0;
//    ^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'b' isn't defined for the type 'A'.
  }
}
''');
  }

  test_notFound_directAssignment_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f<T extends C>(T c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'T'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: T
      staticType: T
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: T
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.foo ??= 0;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
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

  test_notFound_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.foo++;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_nullAwareDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C? c) {
  c?.foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C?
      staticType: C?
    operator: ?.
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int?
''');
  }

  test_notFound_nullAwareDirectAssignment_new() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c?.new = 1;
//   ^^^
// [diag.undefinedInstanceMemberWriteNotFound] The setter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_private_cascadeCompoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c.._foo += 1;
//   ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: CascadePropertyAssignmentTarget
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
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

  test_private_cascadeDirectAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c.._foo = 0;
//   ^^^^
// [diag.undefinedInstanceMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: CascadePropertyAssignmentTarget
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_private_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c._foo += 1;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
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

  test_private_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c._foo = 0;
//  ^^^^
// [diag.undefinedInstanceMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_private_directAssignment_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.

void f(int c) {
  c._foo = 0;
//  ^^^^
// [diag.undefinedInstanceMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: int
      staticType: int
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_private_directAssignment_getterOnly() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f(C c) {
  c._foo = 0;
//  ^^^^
// [diag.undefinedInstanceMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_private_directAssignment_inherited() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

class C extends A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';

void f(C c) {
  c._foo = 0;
//  ^^^^
// [diag.undefinedInstanceMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
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

  test_private_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c._foo ??= 0;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
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

  test_private_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c._foo++;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_nullAwareDirectAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C? c) {
  c?._foo = 0;
//   ^^^^
// [diag.undefinedInstanceMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C?
      staticType: C?
    operator: ?.
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int?
''');
  }

  test_wrongKind_cascadeCompoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c..foo += 1;
//   ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::C::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_cascadeDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c..foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_cascadeIfNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c..foo ??= 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: CascadePropertyAssignmentTarget
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::C::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c.foo += 1;
//  ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::C::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_compoundAssignment_parenthesizedReceiver() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  (c).foo += 1;
//    ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');
  }

  test_wrongKind_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on C {
  void foo() {}
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::#0::@method::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::#0::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_extensionHasSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

extension on C {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f(C c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_directAssignment_extensionHasSetter_explicitThis() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

extension E on C {
  void set foo(int _) {}

  f() {
    this.foo = 0;
//       ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
  }
}
''');
  }

  test_wrongKind_directAssignment_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension on void Function() {
  void foo() {}
}

void f(void Function() c) {
  c.foo = 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'void Function()' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: void Function()
      staticType: void Function()
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::#0::@method::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: void Function()
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::#0::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c.foo ??= 0;
//  ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::C::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c.foo++;
//  ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    operator: .
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::C::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::C::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_nullAwareDirectAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C? c) {
  c?.foo = 0;
//   ^^^
// [diag.undefinedInstanceMemberWriteWrongKind] The method 'foo' of the type 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C?
      staticType: C?
    operator: ?.
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int?
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: int?
''');
  }
}
