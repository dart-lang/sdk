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
    declaration: <testLibrary>::@class::C
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
    declaration: <testLibrary>::@class::C
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::foo
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

  test_found_invocation_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.m();
}
C c = C.m();
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

  test_found_invocation_nullAware() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void m() {}
}
f() { A?.m(); }
//     ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
''');
  }

  test_found_invocation_typeAlias_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static void foo() {}
}

typedef A = E;

void f() {
  A.foo();
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extensionType::E::@method::foo
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_invocation_typeAlias_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int?;

void f() {
  A.parse('0');
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: parse
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      SimpleStringLiteral
        literal: '0'
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: dart:core::@class::int::@method::parse
    invokeType: int Function(String, {int? radix})
    type: int
  staticType: int
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: parse
    element: dart:core::@class::int::@method::parse
    staticType: int Function(String, {int? radix})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: '0'
    rightParenthesis: )
  staticInvokeType: int Function(String, {int? radix})
  staticType: int
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
    declaration: <testLibrary>::@class::C
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
    declaration: <testLibrary>::@class::C
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
    declaration: <testLibrary>::@class::C
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
    declaration: <testLibrary>::@class::C
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

  test_invalidAlias_compoundAssignment_undefinedOnType_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Unknown;
//          ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A.foo += 1;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_compoundAssignment_undefinedOnType_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = List<A>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A.foo += 1;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_functionInstantiation_undefinedOnType_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Unknown;
//          ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A.foo<int>;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
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
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_invalidAlias_functionInstantiation_undefinedOnType_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = List<A>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A.foo<int>;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
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
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_invalidAlias_ifNullAssignment_undefinedOnType_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Unknown;
//          ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A.foo ??= 0;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_ifNullAssignment_undefinedOnType_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = List<A>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A.foo ??= 0;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_increment_undefinedOnType_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Unknown;
//          ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A.foo++;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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
      token: A
      element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_increment_undefinedOnType_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = List<A>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A.foo++;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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
      token: A
      element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_invocation_objectMember_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Unknown;
//          ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A.toString();
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_invalidAlias_invocation_objectMember_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = List<A>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A.toString();
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_invalidAlias_propertyExtraction_objectMember_aliasCycle() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = B;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
typedef B = A;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A.hashCode;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_invalidAlias_propertyExtraction_objectMember_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Unknown;
//          ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A.hashCode;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_invalidAlias_propertyExtraction_objectMember_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = List<A>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A.hashCode;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_compoundAssignment_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  int get foo => 0;

  set foo(int _) {}
}

void f() {
  R.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_compoundAssignment_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_compoundAssignment_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_compoundAssignment_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_compoundAssignment_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_compoundAssignment_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_compoundAssignment_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_compoundAssignment_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_compoundAssignment_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
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

  test_noStaticMembers_compoundAssignment_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.foo += 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_functionInstantiation_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  void foo<X>() {}
}

void f() {
  R.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: R
      element: <testLibrary>::@typeAlias::R
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: R
      element: <testLibrary>::@typeAlias::R
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: R
      element: <testLibrary>::@typeAlias::R
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
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
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleFunctionInstantiation;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: F
      element: <testLibrary>::@typeAlias::F
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
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
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
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
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: R
      element: <testLibrary>::@typeAlias::R
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
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
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_functionInstantiation_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.foo<int>;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ReceiverPropertyExtraction
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
    operator: .
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: R
      element: <testLibrary>::@typeAlias::R
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_noStaticMembers_ifNullAssignment_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  int get foo => 0;

  set foo(int _) {}
}

void f() {
  R.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_ifNullAssignment_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_ifNullAssignment_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_ifNullAssignment_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_ifNullAssignment_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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
    literal: 0
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

  test_noStaticMembers_ifNullAssignment_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_ifNullAssignment_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_ifNullAssignment_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_ifNullAssignment_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo ??= 1;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
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

  test_noStaticMembers_ifNullAssignment_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.foo ??= 0;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_increment_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  int get foo => 0;

  set foo(int _) {}
}

void f() {
  R.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_increment_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_increment_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_increment_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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
      token: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_increment_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_increment_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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
      token: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_increment_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_increment_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: A
      element: <testLibrary>::@typeAlias::A
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
      token: A
      element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_increment_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
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

  test_noStaticMembers_increment_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.foo++;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: ReceiverPropertyAssignmentTarget
    receiver: StaticQualifier
      name: R
      element: <testLibrary>::@typeAlias::R
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
      token: R
      element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_invocation_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  void foo() {}
}

void f() {
  R.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
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
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_invocation_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
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
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_invocation_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
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
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_invocation_objectMember_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: F
    element: <testLibrary>::@typeAlias::F
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_genericDynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_genericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void Function(T);

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_genericNever() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_genericRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T,);

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_genericVoid() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_legacyFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A();

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_legacyGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A<T>(T t);

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_nullableFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function()?;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_nullableNever() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never?;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_nullableRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int,)?;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_typeVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<X> = X;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_objectMember_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

void f() {
  A.toString();
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_prefixed_objectMember_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F = void Function();
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F.toString();
//    ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'p.F' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: F
    element: package:test/a.dart::@typeAlias::F
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
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
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_prefixed_objectMember_recordType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef R = (int,);
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.R.toString();
//    ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'p.R' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: R
    element: package:test/a.dart::@typeAlias::R
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: R
      element: package:test/a.dart::@typeAlias::R
      staticType: null
    element: package:test/a.dart::@typeAlias::R
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_invocation_typeArguments_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  void foo<X>() {}
}

void f() {
  R.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeArguments_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeArguments_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeArguments_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeArguments_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: F
    element: <testLibrary>::@typeAlias::F
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeArguments_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeArguments_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeArguments_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo<int>();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: foo
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
  typeArgumentTypes
    int
V1: MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_noStaticMembers_invocation_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
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
    token: A
    element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_invocation_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
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
    token: F
    element: <testLibrary>::@typeAlias::F
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

  test_noStaticMembers_invocation_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
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
    token: A
    element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_invocation_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
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
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_invocation_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
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
    token: A
    element: <testLibrary>::@typeAlias::A
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

  test_noStaticMembers_invocation_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
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
    token: F
    element: <testLibrary>::@typeAlias::F
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

  test_noStaticMembers_invocation_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.foo();
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
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
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  int get foo => 0;
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_nullAware_objectMember_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

void f() {
  A?.hashCode;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//   ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: ?.
  name: hashCode
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: hashCode
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_nullAware_objectMember_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F?.hashCode;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//   ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
  operator: ?.
  name: hashCode
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: F
    element: <testLibrary>::@typeAlias::F
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: hashCode
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_nullAware_objectMember_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

void f() {
  A?.hashCode;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//   ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: ?.
  name: hashCode
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: hashCode
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_nullAware_objectMember_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R?.hashCode;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//   ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: ?.
  name: hashCode
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: hashCode
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_nullAware_objectMember_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

void f() {
  A?.hashCode;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//   ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: ?.
  name: hashCode
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@typeAlias::A
    staticType: null
  operator: ?.
  propertyName: SimpleIdentifier
    token: hashCode
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_objectMember_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_genericDynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_genericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void Function(T);

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_genericNever() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_genericRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T,);

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_genericVoid() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_legacyFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A();

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_legacyGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A<T>(T t);

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_nullableFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function()?;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_nullableNever() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never?;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_nullableRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int,)?;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: hashCode
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_typeVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<X> = X;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_objectMember_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

void f() {
  A.hashCode;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: hashCode
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
    token: hashCode
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_prefixed_objectMember_recordType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef R = (int,);
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.R.hashCode;
//    ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'p.R' doesn't have a static member named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: R
    element: package:test/a.dart::@typeAlias::R
  operator: .
  name: hashCode
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
      token: R
      element: package:test/a.dart::@typeAlias::R
      staticType: null
    element: package:test/a.dart::@typeAlias::R
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_prefixed_undefinedOnType_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F = void Function();
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F.foo;
//    ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'p.F' doesn't have a static member named 'foo'.
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

  test_noStaticMembers_propertyExtraction_tearOff_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension E<T> on T {
  void foo() {}
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_tearOff_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object? {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_tearOff_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Object {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: F
    element: <testLibrary>::@typeAlias::F
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_genericDynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_genericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void Function(T);

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_genericNever() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_genericRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T,);

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_genericVoid() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_legacyFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A();

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_legacyGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A<T>(T t);

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_nullableFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function()?;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_nullableNever() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never?;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_nullableRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int,)?;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

void f() {
  R.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: toString
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_objectMember_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

void f() {
  A.toString;
//  ^^^^^^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@typeAlias::A
  operator: .
  name: toString
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
    token: toString
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noStaticMembers_propertyExtraction_tearOff_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_tearOff_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_tearOff_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_tearOff_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_tearOff_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R = (int,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'R' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: R
    element: <testLibrary>::@typeAlias::R
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
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

  test_noStaticMembers_propertyExtraction_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'A' doesn't have a static member named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noStaticMembers_propertyExtraction_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f() {
  F.foo;
//  ^^^
// [diag.undefinedStaticMemberReadNoStaticMembers] The type alias 'F' doesn't have a static member named 'foo'.
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

  test_notFound_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

@C.foo
// ^^^
// [diag.undefinedStaticMemberReadNotFoundAnnotation] The class 'C' doesn't have a static member or constructor named 'foo'.
void f() {}
''');
  }

  test_notFound_annotation_inExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

@E.foo
// ^^^
// [diag.undefinedStaticMemberReadNotFoundAnnotation] The extension 'E' doesn't have a static member named 'foo'.
void f() {}
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
    declaration: <testLibrary>::@class::C
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
    declaration: <testLibrary>::@class::C
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

  test_notFound_dotShorthandNameExpression_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

const C x = .foo;
//           ^^^
// [diag.undefinedStaticMemberReadNotFoundDotShorthandConstant] The context type 'C' doesn't have a static member or constructor named 'foo'.
''');
  }

  test_notFound_dotShorthandNameExpression_constant_switchCase() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { a }

void f(E e) {
  switch (e) {
    case .b:
//        ^
// [diag.undefinedStaticMemberReadNotFoundDotShorthandConstant] The context type 'E' doesn't have a value or static member named 'b'.
      break;
  }
}
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
    declaration: <testLibrary>::@class::C
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
    declaration: <testLibrary>::@enum::E
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
    declaration: <testLibrary>::@extensionType::X
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
    declaration: <testLibrary>::@mixin::M
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
    declaration: <testLibrary>::@class::C
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

  test_notFound_propertyExtraction_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

const x = C.foo;
//          ^^^
// [diag.undefinedStaticMemberReadNotFoundConstant] The class 'C' doesn't have a static member or constructor named 'foo'.
''');
  }

  test_notFound_propertyExtraction_constant_inExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

const x = E.foo;
//          ^^^
// [diag.undefinedStaticMemberReadNotFoundConstant] The extension 'E' doesn't have a static member named 'foo'.
''');
  }

  test_notFound_propertyExtraction_constant_receiver() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

const x = C.foo.bar;
//          ^^^
// [diag.undefinedStaticMemberReadNotFound] The class 'C' doesn't have a static member or constructor named 'foo'.
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
    declaration: package:test/a.dart::@class::C
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
    declaration: package:test/a.dart::@class::C
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
    declaration: <testLibrary>::@class::C
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
    declaration: <testLibrary>::@class::C
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
