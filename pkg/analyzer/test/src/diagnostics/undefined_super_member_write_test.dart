// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperMemberWriteTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedSuperMemberWriteTest extends PubPackageResolutionTest {
  test_const_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const int foo = 0;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
}
class B extends A {
  void f() {
    super.foo += 1;
  }
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_const_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const int foo = 0;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
}
class B extends A {
  void f() {
    super.foo = 1;
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_const_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const int? foo = null;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
}
class B extends A {
  void f() {
    super.foo ??= 1;
  }
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_const_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const int foo = 0;
//^^^^^
// [diag.constInstanceField] Only static fields can be declared as const.
}
class B extends A {
  void f() {
    super.foo++;
  }
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int foo = 0;
}
class B extends A {
  void f() {
    super.foo += 1;
//        ^^^
// [diag.undefinedSuperMemberWriteFinal] The field 'foo' in a superclass of 'B' is final, so it can't be assigned to.
  }
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_final_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int foo = 0;
}
class B extends A {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteFinal] The field 'foo' in a superclass of 'B' is final, so it can't be assigned to.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_final_directAssignment_declaringFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int foo);
class B extends A {
  B() : super(0);
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteFinal] The field 'foo' in a superclass of 'B' is final, so it can't be assigned to.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_final_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int? foo = null;
}
class B extends A {
  void f() {
    super.foo ??= 1;
//        ^^^
// [diag.undefinedSuperMemberWriteFinal] The field 'foo' in a superclass of 'B' is final, so it can't be assigned to.
  }
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_final_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int foo = 0;
}
class B extends A {
  void f() {
    super.foo++;
//        ^^^
// [diag.undefinedSuperMemberWriteFinal] The field 'foo' in a superclass of 'B' is final, so it can't be assigned to.
  }
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
class B extends A {
  void f() {
    super.foo += 1;
  }
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
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
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
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
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
class B extends A {
  void f() {
    super.foo = 1;
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_directAssignment_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(int _) {}
}
enum E with M {
  v;
  void f() {
    super.foo = 1;
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: E
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
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

  test_found_directAssignment_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
mixin M on A {
  void f() {
    super.foo = 1;
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: <null>
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: M
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_found_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? foo;
}
class B extends A {
  void f() {
    super.foo ??= 1;
  }
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int? Function()
      type: int?
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int?
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int?
  element: <null>
  staticType: int
''');
  }

  test_found_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
class B extends A {
  void f() {
    super.foo++;
  }
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
class B extends A {
  void f() {
    super.foo += 1;
//        ^^^
// [diag.undefinedSuperMemberWriteGetterOnly] There's a getter 'foo' in a superclass of 'B', but no setter.
  }
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_getterOnly_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
class B extends A {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteGetterOnly] There's a getter 'foo' in a superclass of 'B', but no setter.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_getterOnly_directAssignment_conflictingSetters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int foo;
}
class I {
  set foo(String _) {}
}
abstract class B extends A implements I {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo=': A.foo= (void Function(int)), I.foo= (void Function(String)).
abstract class C extends B {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteGetterOnly] There's a getter 'foo' in a superclass of 'C', but no setter.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: C
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

  test_getterOnly_directAssignment_conflictingSetters_explicitSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
  set foo(int _);
}
class I {
  set foo(String _) {}
}
abstract class B extends A implements I {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo=': A.foo= (void Function(int)), I.foo= (void Function(String)).
abstract class C extends B {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteGetterOnly] There's a getter 'foo' in a superclass of 'C', but no setter.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: C
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

  test_getterOnly_directAssignment_conflictingSetters_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo = 0;
}
class I {
  set foo(String _) {}
}
mixin M on A, I {
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo=': A.foo= (void Function(int)), I.foo= (void Function(String)).
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteGetterOnly] There's a getter 'foo' in a superclass of 'M', but no setter.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: M
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

  test_getterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get foo => null;
}
class B extends A {
  void f() {
    super.foo ??= 1;
//        ^^^
// [diag.undefinedSuperMemberWriteGetterOnly] There's a getter 'foo' in a superclass of 'B', but no setter.
  }
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int? Function()
      type: int?
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int?
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_getterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
class B extends A {
  void f() {
    super.foo++;
//        ^^^
// [diag.undefinedSuperMemberWriteGetterOnly] There's a getter 'foo' in a superclass of 'B', but no setter.
  }
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: int Function()
      type: int
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@getter::foo
  operator: ++
  operation: increment
  position: postfix
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_notFound_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteNotFound] The setter 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_notFound_directAssignment_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteNotFound] The setter 'foo' isn't defined in a superclass of 'E'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: E
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

  test_notFound_directAssignment_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M on A {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteNotFound] The setter 'foo' isn't defined in a superclass of 'M'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: M
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

  test_notFound_directAssignment_interfaceHasGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class I {
  int get foo => 0;
}
abstract class B extends A implements I {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteNotFound] The setter 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_notFound_directAssignment_interfaceHasMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class I {
  void foo() {}
}
abstract class B extends A implements I {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteNotFound] The setter 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_notFound_directAssignment_interfaceHasSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class I {
  set foo(int _) {}
}
abstract class B extends A implements I {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteNotFound] The setter 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_notFound_directAssignment_interfaceHasSetter_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
mixin M implements A {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteNotFound] The setter 'foo' isn't defined in a superclass of 'M'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: M
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

  test_private_directAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo = 1;
//        ^^^^
// [diag.undefinedSuperMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
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

  test_private_directAssignment_setterOnly() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo = 1;
//        ^^^^
// [diag.undefinedSuperMemberWritePrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: _foo
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

  test_wrongKind_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  void f() {
    super.foo += 1;
//        ^^^
// [diag.undefinedSuperMemberWriteWrongKind] The method 'foo' in a superclass of 'B' can't be assigned to.
//            ^^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'void Function()'.
  }
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::A::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@method::foo
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
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
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
  readElement: <testLibrary>::@class::A::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::A::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_wrongKind_directAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  void f() {
    super.foo = 1;
//        ^^^
// [diag.undefinedSuperMemberWriteWrongKind] The method 'foo' in a superclass of 'B' can't be assigned to.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_wrongKind_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  void f() {
    super.foo ??= 1;
//        ^^^
// [diag.undefinedSuperMemberWriteWrongKind] The method 'foo' in a superclass of 'B' can't be assigned to.
//                ^^
// [diag.deadCode] Dead code.
//                ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  }
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::A::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@method::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: Object
V1: AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@class::A::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::A::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: Object
''');
  }

  test_wrongKind_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  void f() {
    super.foo++;
//        ^^^
// [diag.undefinedSuperMemberWriteWrongKind] The method 'foo' in a superclass of 'B' can't be assigned to.
  }
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    read: ExecutableTearOffResolution
      element: <testLibrary>::@class::A::@method::foo
      type: void Function()
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::A::@method::foo
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: ++
  readElement: <testLibrary>::@class::A::@method::foo
  readType: void Function()
  writeElement: <testLibrary>::@class::A::@method::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }
}
