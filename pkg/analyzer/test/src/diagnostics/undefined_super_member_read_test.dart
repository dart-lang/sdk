// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperMemberReadTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedSuperMemberReadTest extends PubPackageResolutionTest {
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

  test_found_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
class B extends A {
  void f() {
    super.foo();
  }
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::A::@method::foo
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_invocation_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  var foo;
}
class B extends A {
  void f() {
    super.foo();
  }
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: ReceiverPropertyExtraction
    receiver: SuperReference
      superKeyword: super
    operator: .
    name: foo
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::A::@getter::foo
      invokeType: dynamic Function()
      type: dynamic
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: DynamicInvocationResolution
    type: dynamic
  staticType: dynamic
V1: FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: dynamic
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_found_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
class B extends A {
  void f() {
    super.foo;
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_found_propertyExtraction_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}
enum E with M {
  v;
  void f() {
    super.foo;
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@mixin::M::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_found_propertyExtraction_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  void f() {
    super.foo;
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_found_propertyExtraction_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get _foo => 0;
}
class B extends A {
  void f() {
    super._foo;
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: _foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::_foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <testLibrary>::@class::A::@getter::_foo
    staticType: int
  staticType: int
''');
  }

  test_notFound_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  void f() {
    super.foo += 1;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'B'.
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  void f() {
    super.foo ??= 1;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'B'.
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
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
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
  operator: ??=
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

  test_notFound_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  void f() {
    super.foo++;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'B'.
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  void f() {
    super.foo();
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_invocation_interfaceHasMethod_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
mixin M implements A {
  void f() {
    super.foo();
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'M'.
  }
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'E'.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M on A {
  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'M'.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_interfaceHasGetter_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'M'.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_interfaceHasSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class I {
  set foo(int _) {}
}
abstract class B extends A implements I {
  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperMemberReadNotFound] The member 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  void f() {
    super._foo;
//        ^^^^
// [diag.undefinedSuperMemberReadNotFound] The member '_foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_privateStatic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int get _foo => 0;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo;
//        ^^^^
// [diag.undefinedSuperMemberReadNotFound] The member '_foo' isn't defined in a superclass of 'B'.
  }
}
''');
  }

  test_private_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo += 1;
//        ^^^^
// [diag.undefinedSuperMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
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
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
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

  test_private_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int? _foo;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo ??= 1;
//        ^^^^
// [diag.undefinedSuperMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
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
    name: _foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
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
  operator: ??=
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

  test_private_increment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo++;
//        ^^^^
// [diag.undefinedSuperMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
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
    target: SuperExpression
      superKeyword: super
      staticType: B
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

  test_private_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo();
//        ^^^^
// [diag.undefinedSuperMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
  }
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: _foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo;
//        ^^^^
// [diag.undefinedSuperMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_setterOnly() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  void f() {
    super._foo;
//        ^^^^
// [diag.undefinedSuperMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_setterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
class B extends A {
  void f() {
    super.foo += 1;
//        ^^^
// [diag.undefinedSuperMemberReadSetterOnly] There's a setter 'foo' in a superclass of 'B', but no getter.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::A::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int? _) {}
}
class B extends A {
  void f() {
    super.foo ??= 1;
//        ^^^
// [diag.undefinedSuperMemberReadSetterOnly] There's a setter 'foo' in a superclass of 'B', but no getter.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::A::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int?
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
    staticType: int
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
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int?
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
class B extends A {
  void f() {
    super.foo++;
//        ^^^
// [diag.undefinedSuperMemberReadSetterOnly] There's a setter 'foo' in a superclass of 'B', but no getter.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::A::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@class::A::@setter::foo
      acceptedType: int
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
class B extends A {
  void f() {
    super.foo();
//        ^^^
// [diag.undefinedSuperMemberReadSetterOnly] There's a setter 'foo' in a superclass of 'B', but no getter.
  }
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_setterOnly_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}
class B extends A {
  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperMemberReadSetterOnly] There's a setter 'foo' in a superclass of 'B', but no getter.
  }
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: SuperReference
    superKeyword: super
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
