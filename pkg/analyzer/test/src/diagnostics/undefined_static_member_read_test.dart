// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedStaticMemberReadTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedStaticMemberReadTest extends PubPackageResolutionTest {
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

  test_found_dotShorthandMethodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C foo() => C();
}

C f() => .foo();
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::foo
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: C Function()
  staticType: C
''');
  }

  test_found_dotShorthandNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static C get foo => C();
}

C f() => .foo;
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::foo
    invokeType: C Function()
    type: C
  staticType: C
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: C
  staticType: C
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

  test_found_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
}

void f() {
  C.foo();
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::C::@method::foo
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_invocation_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void Function() get foo => () {};
}

void f() {
  C.foo();
}
''');

    var node = result.findNode.singleCallInvocation;
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: C
      element: <testLibrary>::@class::C
    operator: .
    name: foo
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::foo
      invokeType: void Function() Function()
      type: void Function()
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: FunctionTypeInvocationResolution
    invokeType: void Function()
    type: void
  staticType: void
V1: FunctionExpressionInvocation
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@getter::foo
      staticType: void Function()
    element: <testLibrary>::@class::C::@getter::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
}

void f() {
  C.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: int
  element: <testLibrary>::@class::C::@getter::foo
  staticType: int
''');
  }

  test_found_propertyExtraction_externalField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static int x;
}
int f() => A.x;
''');
  }

  test_found_propertyExtraction_externalFinalField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static final int x;
}
int f() => A.x;
''');
  }

  test_found_propertyExtraction_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get foo => 0;
}

void f() {
  E.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: E
    element: <testLibrary>::@enum::E
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: E
    element: <testLibrary>::@enum::E
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@getter::foo
    staticType: int
  element: <testLibrary>::@enum::E::@getter::foo
  staticType: int
''');
  }

  test_found_propertyExtraction_inExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int get foo => 0;
}

void f() {
  E.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: E
    element: <testLibrary>::@extension::E
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extension::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: E
    element: <testLibrary>::@extension::E
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: int
  element: <testLibrary>::@extension::E::@getter::foo
  staticType: int
''');
  }

  test_found_propertyExtraction_inExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type X(int it) {
  static int get foo => 0;
}

void f() {
  X.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: X
    element: <testLibrary>::@extensionType::X
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::X::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: X
    element: <testLibrary>::@extensionType::X
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::X::@getter::foo
    staticType: int
  element: <testLibrary>::@extensionType::X::@getter::foo
  staticType: int
''');
  }

  test_found_propertyExtraction_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int get foo => 0;
}

void f() {
  M.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: M
    element: <testLibrary>::@mixin::M
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@mixin::M::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: M
    element: <testLibrary>::@mixin::M
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@getter::foo
    staticType: int
  element: <testLibrary>::@mixin::M::@getter::foo
  staticType: int
''');
  }

  test_found_propertyExtraction_nullAware() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static var x;
}
var a = A?.x;
//       ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
''');
  }

  test_found_propertyExtraction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static int get foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.C.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: C
    element: package:test/a.dart::@class::C
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@class::C::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    element: package:test/a.dart::@class::C::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_found_propertyExtraction_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get _foo => 0;
}

void f() {
  C._foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: _foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::_foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <testLibrary>::@class::C::@getter::_foo
    staticType: int
  element: <testLibrary>::@class::C::@getter::_foo
  staticType: int
''');
  }

  test_found_propertyExtraction_typeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int get foo => 0;
}
typedef A = C;

void f() {
  A.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: int
  element: <testLibrary>::@class::C::@getter::foo
  staticType: int
''');
  }

  test_instanceMember_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
}

void f() {
  C.foo += 1;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_instanceMember_compoundAssignment_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T extends num> {
  late T foo;
}

void f() {
  C.foo += 1;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_instanceMember_compoundAssignment_inExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void f() {
  E.foo += 1;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: E
      element: <testLibrary>::@extension::E
    operator: .
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@extension::E::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@extension::E::@setter::foo
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
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_instanceMember_dotShorthandMethodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C foo() => this;
}

C f() => .foo();
//        ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
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

  test_instanceMember_dotShorthandMethodInvocation_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(C _) {}
}

C f() => .foo();
//        ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
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

  test_instanceMember_dotShorthandNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C get foo => this;
}

C f() => .foo;
//        ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@class::C::@getter::foo
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_instanceMember_dotShorthandNameExpression_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(C _) {}
}

C f() => .foo;
//        ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_instanceMember_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? foo;
}

void f() {
  C.foo ??= 1;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
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
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_instanceMember_ifNullAssignment_generic_topLevelInference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  List<T>? foo;
}

var x = C.foo ??= [];
//        ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
  operator: ??=
  value: ListLiteral
    leftBracket: [
    rightBracket: ]
    correspondingParameter: <null>
    staticType: List<dynamic>
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
  operator: ??=
  rightHandSide: ListLiteral
    leftBracket: [
    rightBracket: ]
    correspondingParameter: <null>
    staticType: List<dynamic>
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_instanceMember_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
}

void f() {
  C.foo++;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_instanceMember_increment_generic_topLevelInference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  List<T> foo = [];
}

var x = C.foo++;
//        ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@getter::foo
    write: InvalidNamedWriteResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_instanceMember_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int get foo => 0;
}

void f() {
  C.foo;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@class::C::@getter::foo
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: InvalidType
  element: <testLibrary>::@class::C::@getter::foo
  staticType: InvalidType
''');
  }

  test_instanceMember_propertyExtraction_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f() {
  C.foo;
//  ^^^
// [diag.staticAccessToInstanceMember] Instance member 'foo' can't be accessed using static access.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The function type 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: F
      element: <testLibrary>::@typeAlias::F
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

  test_noStaticMembers_dotShorthandMethodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void Function() f() => .foo();
//                      ^^^
// [diag.undefinedStaticMemberReadNoStaticMembersDotShorthand] The context type 'void Function()' doesn't have static members or constructors.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: void Function()
    lookupType: void Function()
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
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

  test_noStaticMembers_dotShorthandNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void Function() f() => .foo;
//                      ^^^
// [diag.undefinedStaticMemberReadNoStaticMembersDotShorthand] The context type 'void Function()' doesn't have static members or constructors.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: void Function()
    lookupType: void Function()
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_dotShorthandNameExpression_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Unknown f() => .foo;
// [diag.undefinedClass][column 1][length 7] Undefined class 'Unknown'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: InvalidType
    lookupType: InvalidType
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_dotShorthandNameExpression_record() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
(int,) f() => .foo;
//             ^^^
// [diag.undefinedStaticMemberReadNoStaticMembersDotShorthand] The context type '(int,)' doesn't have static members or constructors.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: (int,)
    lookupType: (int,)
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_dotShorthandNameExpression_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>() => .foo;
//           ^^^
// [diag.undefinedStaticMemberReadNoStaticMembersDotShorthand] The context type 'T' doesn't have static members or constructors.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: T
    lookupType: T
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The function type 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: F
      element: <testLibrary>::@typeAlias::F
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

  test_noStaticMembers_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The function type 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: F
      element: <testLibrary>::@typeAlias::F
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
      token: F
      element: <testLibrary>::@typeAlias::F
      staticType: null
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

  test_noStaticMembers_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo();
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'Type'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: TypeLiteral
    type: NamedType
      name: F
      element: <testLibrary>::@typeAlias::F
      type: void Function()
        alias: <testLibrary>::@typeAlias::F
    staticType: Type
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
  target: TypeLiteral
    type: NamedType
      name: F
      element: <testLibrary>::@typeAlias::F
      type: void Function()
        alias: <testLibrary>::@typeAlias::F
    staticType: Type
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

  test_noStaticMembers_invocation_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo();
//       ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The function type 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  constructorReference: ConstructorReference2
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
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
V1: InstanceCreationExpression
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
      type: void Function(int)
        alias: <testLibrary>::@typeAlias::F
          typeArguments
            int
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The function type 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: F
    element: <testLibrary>::@typeAlias::F
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo;
//       ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The function type 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleConstructorTearOff;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
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
V1: ConstructorReference
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
''');
  }

  test_noStaticMembers_propertyExtraction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F = void Function();
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F.foo;
//    ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The function type 'p.F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: F
    element: package:test/a.dart::@typeAlias::F
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
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
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_dotShorthandMethodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

C f() => .foo();
//        ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthand] The context type 'C' doesn't have a static member or constructor named 'foo'.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
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

  test_notFound_dotShorthandNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

C f() => .foo;
//        ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthand] The context type 'C' doesn't have a static member or constructor named 'foo'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_dotShorthandNameExpression_futureOr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class C {}

FutureOr<C> f() => .foo;
//                  ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthand] The context type 'C' doesn't have a static member or constructor named 'foo'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: FutureOr<C>
    lookupType: C
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_dotShorthandNameExpression_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a }

E f() => .foo;
//        ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthand] The context type 'E' doesn't have a value or static member named 'foo'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: E
    lookupType: E
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_dotShorthandNameExpression_inExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type X(int it) {}

X f() => .foo;
//        ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthand] The context type 'X' doesn't have a static member or constructor named 'foo'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: X
    lookupType: X
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_dotShorthandNameExpression_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}

M f() => .foo;
//        ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthand] The context type 'M' doesn't have a static member named 'foo'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: M
    lookupType: M
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_dotShorthandNameExpression_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

C? f() => .foo;
//         ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthand] The context type 'C' doesn't have a static member or constructor named 'foo'.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C?
    lookupType: C?
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
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

void f() {
  C.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
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
class C {}

void f() {
  C.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
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
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
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

  test_notFound_invocation_mixinApplicationFactory() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}

class A {
  A();
  factory A.foo() = A;
}

class C = A with M;

void f() {
  C.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
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
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
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

  test_notFound_invocation_syntheticName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C.(0);
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: <empty> <synthetic>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: <empty> <synthetic>
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_inEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
}

void f() {
  E.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The enum 'E' doesn't have a value or static member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: E
    element: <testLibrary>::@enum::E
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: E
    element: <testLibrary>::@enum::E
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_inExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  E.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The extension 'E' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: E
    element: <testLibrary>::@extension::E
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: E
    element: <testLibrary>::@extension::E
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_inExtensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type X(int it) {}

void f() {
  X.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The extension type 'X' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: X
    element: <testLibrary>::@extensionType::X
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: X
    element: <testLibrary>::@extensionType::X
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_inheritedStatic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C extends S {}
class S {
  static int get foo => 0;
}

void f() {
  C.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_inMixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}

void f() {
  M.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The mixin 'M' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: M
    element: <testLibrary>::@mixin::M
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: M
    element: <testLibrary>::@mixin::M
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C?.foo;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//   ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: ?.
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.C.foo;
//    ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: C
    element: package:test/a.dart::@class::C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
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
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f() {
  C._foo;
//  ^^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named '_foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_typeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}
typedef A = C;

void f() {
  A.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_compoundAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo += 1;
//  ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: package:test/a.dart::@class::C
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

  test_private_dotShorthandMethodInvocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static C _foo() => C();
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

C f() => ._foo();
//        ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: _foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
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

  test_private_dotShorthandMethodInvocation_privateDeclaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _C {
  static _C foo() => _C();
}

void g(_C c) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  g(.foo());
//   ^^^
// [diag.undefinedStaticMemberReadPrivateDotShorthand] The context type '_C' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _C
    lookupType: _C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  correspondingParameter: package:test/a.dart::@function::g::@formalParameter::c
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: package:test/a.dart::@function::g::@formalParameter::c
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_private_dotShorthandNameExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static C get _foo => C();
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

C f() => ._foo;
//        ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: _foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_private_dotShorthandNameExpression_privateDeclaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
class _C {
  static _C get foo => _C();
}

void g(_C c) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  g(.foo);
//   ^^^
// [diag.undefinedStaticMemberReadPrivateDotShorthand] The context type '_C' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: InvalidDotShorthandContextResolution
    contextType: _C
    lookupType: _C
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  correspondingParameter: package:test/a.dart::@function::g::@formalParameter::c
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  correspondingParameter: package:test/a.dart::@function::g::@formalParameter::c
  staticType: InvalidType
''');
  }

  test_private_ifNullAssignment() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static int? _foo;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo ??= 1;
//  ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: package:test/a.dart::@class::C
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
class C {
  static int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo++;
//  ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: C
      element: package:test/a.dart::@class::C
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
      token: C
      element: package:test/a.dart::@class::C
      staticType: null
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
class C {
  static void _foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo();
//  ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: C
    element: package:test/a.dart::@class::C
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
  target: SimpleIdentifier
    token: C
    element: package:test/a.dart::@class::C
    staticType: null
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
class C {
  static int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo;
//  ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: package:test/a.dart::@class::C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: package:test/a.dart::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_setterOnly() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f() {
  C._foo;
//  ^^^^
// [diag.undefinedStaticMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: package:test/a.dart::@class::C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: package:test/a.dart::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int _) {}
}

void f() {
  C.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadSetterOnly] There's a static setter 'foo' in the class 'C', but no getter.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_dotShorthandMethodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(C _) {}
}

C f() => .foo();
//        ^^^
// [diag.undefinedStaticMemberReadSetterOnly] There's a static setter 'foo' in the class 'C', but no getter.
''');

    var node = result.findNode.singleDotShorthandMethodInvocation;
    assertResolvedNodeText(node, r'''
DotShorthandMethodInvocation
  period: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
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

  test_setterOnly_dotShorthandNameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(C _) {}
}

C f() => .foo;
//        ^^^
// [diag.undefinedStaticMemberReadSetterOnly] There's a static setter 'foo' in the class 'C', but no getter.
''');

    var node = result.findNode.singleDotShorthandNameExpression;
    assertResolvedNodeText(node, r'''
DotShorthandNameExpression
  period: .
  name: foo
  shorthandContext: ValidDotShorthandContextResolution
    contextType: C
    lookupType: C
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_setterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int? _) {}
}

void f() {
  C.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberReadSetterOnly] There's a static setter 'foo' in the class 'C', but no getter.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int?
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
    staticType: int
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
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int?
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int _) {}
}

void f() {
  C.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadSetterOnly] There's a static setter 'foo' in the class 'C', but no getter.
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
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@class::C::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
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
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int _) {}
}

void f() {
  C.foo();
//  ^^^
// [diag.undefinedStaticMemberReadSetterOnly] There's a static setter 'foo' in the class 'C', but no getter.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
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
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
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
class C {
  static set foo(int _) {}
}

void f() {
  C.foo;
//  ^^^
// [diag.undefinedStaticMemberReadSetterOnly] There's a static setter 'foo' in the class 'C', but no getter.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: C
    element: <testLibrary>::@class::C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }
}
