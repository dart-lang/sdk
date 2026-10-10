// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedInstanceMemberReadTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedInstanceMemberReadTest extends PubPackageResolutionTest {
  test_found_cascadePropertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
  int bar() => 0;
}

void f(C c) {
  c..foo;
}
''');

    var node = result.findNode.singleCascadePropertyExtraction;
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_found_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
  int bar() => 0;
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

  test_found_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo() {}
}

void f(C c) {
  c.foo();
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
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
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
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

  test_found_objectPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
  int bar() => 0;
}

void f(C c) {
  if (c case C(foo: _)) {}
}
''');

    var node = result.findNode.singlePatternField;
    assertResolvedNodeText(node, r'''
PatternField
  name: PatternFieldName
    name: foo
    colon: :
  pattern: WildcardPattern
    name: _
    matchedValueType: int
  element: <testLibrary>::@class::C::@getter::foo
''');
  }

  test_found_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int foo = 0;
  int bar() => 0;
}

void f(C c) {
  c.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: int
  element: <testLibrary>::@class::C::@getter::foo
  staticType: int
''');
  }

  test_found_propertyExtraction_abstractField() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
int f(A a) => a.x;
''');
  }

  test_found_propertyExtraction_abstractFinalField() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract final int x;
}
int f(A a) => a.x;
''');
  }

  test_found_propertyExtraction_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on C {
  int get foo => 0;
}

void f(C c) {
  c.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extension::#0::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::#0::@getter::foo
    staticType: int
  element: <testLibrary>::@extension::#0::@getter::foo
  staticType: int
''');
  }

  test_found_propertyExtraction_externalField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
int f(A a) => a.x;
''');
  }

  test_found_propertyExtraction_externalFinalField() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external final int x;
}
int f(A a) => a.x;
''');
  }

  test_found_propertyExtraction_functionCall() async {
    // Referencing `.call` on a `Function` type works similarly to referencing
    // it on `dynamic`--the reference is accepted at compile time, and all type
    // checking is deferred until runtime.
    await resolveTestCodeWithDiagnostics('''
f(Function f) {
  return f.call;
}
''');
  }

  test_found_propertyExtraction_functionCall_parenthesized() async {
    await resolveTestCodeWithDiagnostics('''
void f(Function a) {
  return (a).call;
//       ^^^^^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Function' can't be returned from the function 'f' because it has a return type of 'void'.
}
''');
  }

  test_found_propertyExtraction_ifElementInList_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return [if (x is String) x.length];
}
''');
  }

  test_found_propertyExtraction_ifElementInMap_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return {if (x is String) x : x.length};
}
''');
  }

  test_found_propertyExtraction_ifElementInSet_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return {if (x is String) x.length};
}
''');
  }

  test_found_propertyExtraction_ifStatement_promoted() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  if (x is String) {
    x.length;
  }
}
''');
  }

  test_found_propertyExtraction_methodTearOffCall() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void staticMethod() {}
}

void f(A a) {
  a.staticMethod.call;
}
''');
  }

  test_found_propertyExtraction_typeLiteralExtension() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo;
}

extension E on Type {
  int get foo => 1;
}
''');
  }

  test_found_propertyExtraction_typeSubstitution() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  E element;
  A(this.element);
}
class B extends A<List> {
  B(List element) : super(element);
  m() {
    element.last;
  }
}
''');
  }

  test_notFound_cascadeInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c..foo();
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleCascadeSection;
    assertResolvedNodeText(node, r'''
CascadeSection
  operator: ..
  body: CascadeMethodInvocation
    name: foo
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: InvalidInvocationResolution
      type: InvalidType
      recovery: <null>
    staticType: InvalidType
''');
  }

  test_notFound_cascadeInvocation_conditionContext() async {
    await resolveTestCodeWithDiagnostics('''
T castObject<T>(Object value) => value as T;

main() {
  (castObject(true)..whatever()) ? 1 : 2;
//                   ^^^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'whatever' isn't defined for the type 'bool'.
}
''');
  }

  test_notFound_cascadeInvocation_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) {
  m..abs();
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'abs' isn't defined for the type 'M'.
}
''');
  }

  test_notFound_cascadePropertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c..foo;
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleCascadePropertyExtraction;
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_cascadePropertyExtraction_new() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c..new;
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'new' isn't defined for the type 'C?'.
}
''');
  }

  test_notFound_cascadePropertyExtraction_typeLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
class T {
  static int get foo => 42;
}
main() {
  T..foo;
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'Type'.
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
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type 'C'.
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

  test_notFound_compoundAssignment_staticSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int _) {}
}

void f(C c) {
  c.foo += 1;
//  ^^^
// [diag.instanceAccessToStaticMember] The static setter 'foo' can't be accessed through an instance.
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
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.foo ??= 0;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type 'C'.
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
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type 'C'.
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

  test_notFound_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.foo();
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
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
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
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

  test_notFound_invocation_declaredType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
//    ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'm' isn't defined for the type 'A'.
  }
}
''');
  }

  test_notFound_invocation_extensionStatic() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

extension E on C {
  static void a() {}
}

f(C c) {
  c.a();
//  ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'a' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_invocation_extensionWithOtherMember() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E on C {
  void a() {}
}

f(C c) {
  c.c();
//  ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'c' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_invocation_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) {
  m.abs();
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'abs' isn't defined for the type 'M'.
}
''');
  }

  test_notFound_invocation_privateExtension() async {
    newFile('$testPackageLibPath/lib.dart', '''
class B {}

extension _ on B {
  void a() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart';

f(B b) {
  b.a();
//  ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'a' isn't defined for the type 'B'.
}
''');
  }

  test_notFound_invocation_privateStatic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static void _foo() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f(C c) {
  c._foo();
//  ^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member '_foo' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_invocation_record() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var x = 1;
  (x,).foo();
//     ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type '(int,)'.
}
''');
  }

  test_notFound_invocation_syntheticName() async {
    await resolveTestCodeWithDiagnostics('''
void f(int a) {
  a.(0);
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_invocation_syntheticName_argumentsResolved() async {
    await resolveTestCodeWithDiagnostics('''
void f(int a) {
  a.(unresolved);
//  ^
// [diag.missingIdentifier] Expected an identifier.
//   ^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_notFound_invocation_typeLiteralFunctionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function();

void f() {
  A.foo();
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'Type'.
}
''');
  }

  test_notFound_invocation_unnamedExtensionOfOtherLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension on C {
  void a() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart';

f(C c) {
  c.a();
//  ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'a' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_nullAwareInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C? c) {
  c?.foo();
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C?
    staticType: C?
  operator: ?.
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
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C?
  operator: ?.
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

  test_notFound_nullAwareInvocation_syntheticName() async {
    await resolveTestCodeWithDiagnostics('''
void f(int? a) {
  a?.(0);
//   ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_nullAwarePropertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C? c) {
  c?.foo;
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C?
    staticType: C?
  operator: ?.
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_nullAwarePropertyExtraction_new() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c?.new;
//   ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'new' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_objectPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  if (c case C(foo: _)) {}
//             ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singlePatternField;
    assertResolvedNodeText(node, r'''
PatternField
  name: PatternFieldName
    name: foo
    colon: :
  pattern: WildcardPattern
    name: _
    matchedValueType: dynamic
  element: <null>
''');
  }

  test_notFound_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_ambiguousExtensions() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E1 on C {
  int get foo => 0;
}

extension E2 on C {
  int get foo => 0;
}

void f(C c) {
  c.foo;
//  ^^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'foo' is defined in 'extension E1 on C' and 'extension E2 on C', and neither is more specific.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_extensionNotApplicable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on String {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_extensionStatic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on C {
  static int get foo => 0;
//               ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type C(int it) {}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_extensionWithoutMember() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E on C {}

f(C c) {
  c.a;
//  ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'a' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_propertyExtraction_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(void Function() c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'void Function()'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: void Function()
    staticType: void Function()
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: void Function()
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_ifElementInList_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  return [if (x is String) x.length];
//                           ^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'length' isn't defined for the type 'int'.
}
''');
  }

  test_notFound_propertyExtraction_ifElementInMap_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  return {if (x is String) x : x.length};
//                               ^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'length' isn't defined for the type 'int'.
}
''');
  }

  test_notFound_propertyExtraction_ifElementInSet_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  return {if (x is String) x.length};
//                           ^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'length' isn't defined for the type 'int'.
}
''');
  }

  test_notFound_propertyExtraction_ifStatement_notPromoted() async {
    await resolveTestCodeWithDiagnostics('''
f(int x) {
  if (x is String) {
    x.length;
//    ^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'length' isn't defined for the type 'int'.
  }
}
''');
  }

  test_notFound_propertyExtraction_mixinThis() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  f() { return this.m; }
//                  ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'm' isn't defined for the type 'M'.
}
''');
  }

  test_notFound_propertyExtraction_new() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C c) {
  c.new;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'new' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_propertyExtraction_new_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f(dynamic d) {
  d.new;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'new' isn't defined for the type 'dynamic'.
}
''');
  }

  test_notFound_propertyExtraction_new_parenthesized() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c1, C c2) {
  (c1 ?? c2).new;
//           ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'new' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_propertyExtraction_new_propertyTarget() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

abstract class D {
  C get c;
}

f(D d) {
  d.c.new;
//    ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'new' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_propertyExtraction_new_typeParameter() async {
    await resolveTestCodeWithDiagnostics('''
f<T>(T t) {
  t.new;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'new' isn't defined for the type 'T'.
}
''');
  }

  test_notFound_propertyExtraction_nullableReceiver() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C? c) {
  c.foo;
//  ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C?
    staticType: C?
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C?
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_nullReceiver() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null _null;
  _null.foo;
//      ^^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_notFound_propertyExtraction_objectCall() async {
    await resolveTestCodeWithDiagnostics('''
f(Object o) {
  return o.call;
//         ^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'call' isn't defined for the type 'Object'.
}
''');
  }

  test_notFound_propertyExtraction_privateName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member '_foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_privateStatic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f(C c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member '_foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_privateStatic_interface() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int get _foo => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

abstract class C implements A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';

void f(C c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member '_foo' isn't defined for the type 'C'.
}
''');
  }

  test_notFound_propertyExtraction_promotedTypeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<X extends num, Y extends X>(Y y) {
  if (y is int) {
    y.isEven;
//    ^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'isEven' isn't defined for the type 'Y'.
  }
}
''');
  }

  test_notFound_propertyExtraction_record() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, {int bar}) c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type '(int, {int bar})'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: (int, {int bar})
    staticType: (int, {int bar})
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PropertyAccess
  target: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: (int, {int bar})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_staticSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int _) {}
}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_syntheticName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f(C c) {
  c.;
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: <empty> <synthetic>
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: <empty> <synthetic>
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_propertyExtraction_syntheticName_argument() async {
    await resolveTestCodeWithDiagnostics('''
class A {
}
main() {
  print(A().);
//          ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_propertyExtraction_syntheticName_listLiteral() async {
    await resolveTestCodeWithDiagnostics('''
void f(int a) {
  a.[0];
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_propertyExtraction_syntheticName_setOrMapLiteral() async {
    await resolveTestCodeWithDiagnostics('''
void f(int a) {
  a.{};
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_propertyExtraction_syntheticName_stringLiteral() async {
    await resolveTestCodeWithDiagnostics('''
void f(int a) {
  a."s";
//  ^^^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_propertyExtraction_syntheticName_typedListLiteral() async {
    await resolveTestCodeWithDiagnostics('''
void f(int a) {
  a.<int>[];
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_propertyExtraction_topLevelVariableInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {}
var a = 3.v;
//        ^
// [diag.undefinedInstanceMemberReadNotFound] The member 'v' isn't defined for the type 'int'.
''');
  }

  test_notFound_propertyExtraction_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

void f<T extends C>(T c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'foo' isn't defined for the type 'T'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: T
    staticType: T
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: T
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
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c._foo += 1;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
// [diag.undefinedSetter] The setter '_foo' isn't defined for the type 'C'.
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
// [diag.undefinedSetter] The setter '_foo' isn't defined for the type 'C'.
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
// [diag.undefinedSetter] The setter '_foo' isn't defined for the type 'C'.
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

  test_private_invocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c._foo();
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
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
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
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

  test_private_invocation_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  void _foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.

void f(int c) {
  c._foo();
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: int
    staticType: int
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
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
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

  test_private_objectPattern() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  if (c case C(_foo: _)) {}
//             ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singlePatternField;
    assertResolvedNodeText(node, r'''
PatternField
  name: PatternFieldName
    name: _foo
    colon: :
  pattern: WildcardPattern
    name: _
    matchedValueType: dynamic
  element: <null>
''');
  }

  test_private_propertyExtraction() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';


void f(C c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.

void f(int c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: int
    staticType: int
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_extensionNotApplicable() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on String {
  int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'a.dart'.

void f(int c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member '_foo' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: int
    staticType: int
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_extensionNotImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int get _foo => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.

void f(int c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member '_foo' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: int
    staticType: int
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_inherited() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

class C extends A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';

void f(C c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_private_propertyExtraction_inherited_shadowedByStatic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

class B extends A {
  static int get _foo => 0;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';

void f(B b) {
  b._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');
  }

  test_private_propertyExtraction_interfaceFirst() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int get _foo => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

extension E on C {
  int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';
//     ^^^^^^^^
// [diag.unusedImport] Unused import: 'b.dart'.

void f(C c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
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
  set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f(C c) {
  c._foo;
//  ^^^^
// [diag.undefinedInstanceMemberReadPrivate] The member '_foo' is declared in 'package:test/a.dart', but private names are visible only in their own library.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: _foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_cascadePropertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f(C c) {
  c..foo;
//   ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
}
''');

    var node = result.findNode.singleCascadePropertyExtraction;
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: foo
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::C::@setter::foo
    type: void Function(int)
  staticType: void Function(int)
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@setter::foo
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_setterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f(C c) {
  c.foo += 1;
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
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
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f(C c) {
  c.foo ??= 0;
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
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
      recoveryElement: <testLibrary>::@class::C::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@class::C::@setter::foo
      acceptedType: int
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
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
    correspondingParameter: <testLibrary>::@class::C::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f(C c) {
  c.foo++;
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
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
  writeElement: <testLibrary>::@class::C::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f(C c) {
  c.foo();
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
}
''');

    var node = result.findNode.singleReceiverMethodInvocation;
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
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
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
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

  test_setterOnly_objectPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f(C c) {
  if (c case C(foo: _)) {}
//             ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
}
''');

    var node = result.findNode.singlePatternField;
    assertResolvedNodeText(node, r'''
PatternField
  name: PatternFieldName
    name: foo
    colon: :
  pattern: WildcardPattern
    name: _
    matchedValueType: dynamic
  element: <null>
''');
  }

  test_setterOnly_propertyExtraction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}
}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@class::C::@setter::foo
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@setter::foo
    staticType: InvalidType
  element: <testLibrary>::@class::C::@setter::foo
  staticType: InvalidType
''');
  }

  test_setterOnly_propertyExtraction_extension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

extension on C {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@extension::#0::@setter::foo
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::#0::@setter::foo
    staticType: InvalidType
  element: <testLibrary>::@extension::#0::@setter::foo
  staticType: InvalidType
''');
  }

  test_setterOnly_propertyExtraction_extensionHasGetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;
}

f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
}
''');
  }

  test_setterOnly_propertyExtraction_extensionHasGetter_explicitThis() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;

  f() {
    this.foo;
//       ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
  }
}
''');
  }

  test_setterOnly_propertyExtraction_inherited() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}

class C extends A {}

void f(C c) {
  c.foo;
//  ^^^
// [diag.undefinedInstanceMemberReadSetterOnly] There's a setter 'foo' for the type 'C', but no getter.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@class::A::@setter::foo
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@setter::foo
    staticType: InvalidType
  element: <testLibrary>::@class::A::@setter::foo
  staticType: InvalidType
''');
  }
}
