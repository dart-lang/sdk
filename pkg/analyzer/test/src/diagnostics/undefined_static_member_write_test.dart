// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedStaticMemberWriteTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedStaticMemberWriteTest extends PubPackageResolutionTest {
  test_const_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static const int foo = 0;
}

void f() {
  C.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberWriteConst] The constant 'foo' in the class 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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

  test_const_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static const int foo = 0;
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteConst] The constant 'foo' in the class 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static const int? foo = null;
}

void f() {
  C.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberWriteConst] The constant 'foo' in the class 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static const int foo = 0;
}

void f() {
  C.foo++;
//  ^^^
// [diag.undefinedStaticMemberWriteConst] The constant 'foo' in the class 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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

  test_final_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final int foo = 0;
}

void f() {
  C.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberWriteFinal] The static field 'foo' in the class 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  static final int foo = 0;
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteFinal] The static field 'foo' in the class 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_external() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  external static final int foo;
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteFinal] The static field 'foo' in the class 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_directAssignment_lateFinal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static late final int foo = 0;
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteFinal] The static field 'foo' in the class 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final int? foo = null;
}

void f() {
  C.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberWriteFinal] The static field 'foo' in the class 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static final int foo = 0;
}

void f() {
  C.foo++;
//  ^^^
// [diag.undefinedStaticMemberWriteFinal] The static field 'foo' in the class 'C' is final, so it can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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

  test_found_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int foo = 0;
}

void f() {
  C.foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  static int foo = 0;
}

void f() {
  C.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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

  test_found_directAssignment_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set foo(int _) {}
}

void f() {
  E.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: E
      element: <testLibrary>::@enum::E
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@enum::E::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@enum::E::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@enum::E
      staticType: null
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
    correspondingParameter: <testLibrary>::@enum::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@enum::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_inExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static set foo(int _) {}
}

void f() {
  E.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: E
      element: <testLibrary>::@extension::E
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@extension::E::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
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
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_inExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type X(int it) {
  static set foo(int _) {}
}

void f() {
  X.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: X
      element: <testLibrary>::@extensionType::X
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@extensionType::X::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extensionType::X::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: X
      element: <testLibrary>::@extensionType::X
      staticType: null
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
    correspondingParameter: <testLibrary>::@extensionType::X::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extensionType::X::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static set foo(int _) {}
}

void f() {
  M.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: M
      element: <testLibrary>::@mixin::M
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@mixin::M::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: M
      element: <testLibrary>::@mixin::M
      staticType: null
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
    correspondingParameter: <testLibrary>::@mixin::M::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@mixin::M::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static set foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.C.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: C
      element: package:test/a.dart::@class::C
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: package:test/a.dart::@class::C::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@class::C::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        element: package:test/a.dart::@class::C
        staticType: null
      element: package:test/a.dart::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: package:test/a.dart::@class::C::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set _foo(int _) {}
}

void f() {
  C._foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: _foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::_foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::_foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::_foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::_foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_typeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int _) {}
}
typedef A = C;

void f() {
  A.foo = 1;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@typeAlias::A
      staticType: null
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
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int? foo;
}

void f() {
  C.foo ??= 1;
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int?
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int?
  element: <null>
  staticType: int
''');
  }

  test_found_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int foo = 0;
}

void f() {
  C.foo++;
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
}

void f() {
  C.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberWriteGetterOnly] There's a static getter 'foo' in the class 'C', but no setter.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  static int get foo => 0;
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteGetterOnly] There's a static getter 'foo' in the class 'C', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_directAssignment_inExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
}

void f() {
  E.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteGetterOnly] There's a static getter 'foo' in the extension 'E', but no setter.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: E
      element: <testLibrary>::@extension::E
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
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
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
  writeElement: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int? get foo => null;
}

void f() {
  C.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberWriteGetterOnly] There's a static getter 'foo' in the class 'C', but no setter.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
}

void f() {
  C.foo++;
//  ^^^
// [diag.undefinedStaticMemberWriteGetterOnly] There's a static getter 'foo' in the class 'C', but no setter.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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

  test_instanceMember_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <testLibrary>::@class::C::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_noStaticMembers_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNoStaticMembers] The function type 'F' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: F
      element: <testLibrary>::@typeAlias::F
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: F
      element: <testLibrary>::@typeAlias::F
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_noStaticMembers_directAssignment_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo = 1;
//       ^^^
// [diag.undefinedStaticMemberWriteNoStaticMembers] The function type 'F' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: F
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::F
        type: void Function(int)
          alias: <testLibrary>::@typeAlias::F
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    write: InvalidWriteResolution
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: F
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::F
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
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

  test_noStaticMembers_directAssignment_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F = void Function();
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F.foo = 1;
//    ^^^
// [diag.undefinedStaticMemberWriteNoStaticMembers] The function type 'p.F' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: F
      element: package:test/a.dart::@typeAlias::F
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: F
        element: package:test/a.dart::@typeAlias::F
        staticType: null
      element: package:test/a.dart::@typeAlias::F
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The class 'C' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_constructorName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C.new = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The class 'C' doesn't have a static setter named 'new'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: new
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: new
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
}

void f() {
  E.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The enum 'E' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: E
      element: <testLibrary>::@enum::E
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@enum::E
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_inExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The extension 'E' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: E
      element: <testLibrary>::@extension::E
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_inExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type X(int it) {}

void f() {
  X.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The extension type 'X' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: X
      element: <testLibrary>::@extensionType::X
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: X
      element: <testLibrary>::@extensionType::X
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_inheritedStatic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C extends S {}
class S {
  static set foo(int _) {}
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The class 'C' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}

void f() {
  M.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The mixin 'M' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: M
      element: <testLibrary>::@mixin::M
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: M
      element: <testLibrary>::@mixin::M
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.C.foo = 1;
//    ^^^
// [diag.undefinedStaticMemberWriteNotFound] The class 'C' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: C
      element: package:test/a.dart::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        element: package:test/a.dart::@class::C
        staticType: null
      element: package:test/a.dart::@class::C
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C._foo = 1;
//  ^^^^
// [diag.undefinedStaticMemberWriteNotFound] The class 'C' doesn't have a static setter named '_foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notFound_directAssignment_typeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}
typedef A = C;

void f() {
  A.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteNotFound] The class 'C' doesn't have a static setter named 'foo'.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@typeAlias::A
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_private_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo = 1;
//  ^^^^
// [diag.undefinedStaticMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: package:test/a.dart::@class::C
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: package:test/a.dart::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_private_directAssignment_setterOnly() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo = 1;
//  ^^^^
// [diag.undefinedStaticMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: package:test/a.dart::@class::C
    operator: .
    name: _foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: package:test/a.dart::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
}

void f() {
  C.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberWriteWrongKind] The method 'foo' in the class 'C' can't be assigned to.
//      ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'void Function()'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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

  test_wrongKind_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
}

void f() {
  C.foo = 1;
//  ^^^
// [diag.undefinedStaticMemberWriteWrongKind] The method 'foo' in the class 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_wrongKind_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
}

void f() {
  C.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberWriteWrongKind] The method 'foo' in the class 'C' can't be assigned to.
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
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::C::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@method::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: Object
V1: AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::C::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::C::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: Object
''');
  }

  test_wrongKind_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
}

void f() {
  C.foo++;
//  ^^^
// [diag.undefinedStaticMemberWriteWrongKind] The method 'foo' in the class 'C' can't be assigned to.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
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
      token: C
      element: <testLibrary>::@class::C
      staticType: null
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
}
