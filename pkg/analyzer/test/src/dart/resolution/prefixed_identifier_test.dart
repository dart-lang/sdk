// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedIdentifierResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrefixedIdentifierResolutionTest extends PubPackageResolutionTest {
  test_class_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A
    staticType: A
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  test_class_read_staticMethod_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  static void foo<U>(int a, U u) {}
}

void f() {
  A.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@class::A
  operator: .
  name: foo
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::A::@method::foo
    type: void Function<U>(int, U)
  staticType: void Function<U>(int, U)
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function<U>(int, U)
  element: <testLibrary>::@class::A::@method::foo
  staticType: void Function<U>(int, U)
''');
  }

  test_class_read_staticMethod_ofGenericClass() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  static void foo(int a) {}
}

void f() {
  A.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@class::A
  operator: .
  name: foo
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::A::@method::foo
    type: void Function(int)
  staticType: void Function(int)
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function(int)
  element: <testLibrary>::@class::A::@method::foo
  staticType: void Function(int)
''');
  }

  test_class_readWrite_assignment() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo += 1;
}
''');

    var node = result.findNode.assignment('foo += 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
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

  test_class_write() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo = 1;
}
''');

    var node = result.findNode.assignment('foo = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  test_enum_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E {
  v;
  int get foo => 0;
}

void f(E e) {
  e.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: e
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::e
      type: E
    staticType: E
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: e
    element: <testLibrary>::@function::f::@formalParameter::e
    staticType: E
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@getter::foo
    staticType: int
  element: <testLibrary>::@enum::E::@getter::foo
  staticType: int
''');
  }

  test_enum_write() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E {
  v;
  set foo(int _) {}
}

void f(E e) {
  e.foo = 1;
}
''');

    var node = result.findNode.assignment('foo = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: e
      element: <testLibrary>::@function::f::@formalParameter::e
      staticType: E
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
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

  test_functionClass_call_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Function a) {
  a.call;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: Function
    staticType: Function
  operator: .
  name: call
  resolution: FunctionInterfaceCallTearOffResolution
    type: Function
  staticType: Function
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Function
  period: .
  identifier: SimpleIdentifier
    token: call
    element: <null>
    staticType: Function
  element: <null>
  staticType: Function
''');
  }

  test_functionType_call_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(int Function(String) a) {
  a.call;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: int Function(String)
    staticType: int Function(String)
  operator: .
  name: call
  resolution: FunctionCallTearOffResolution
    type: int Function(String)
    associatedFunctionType: int Function(String)
  staticType: int Function(String)
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int Function(String)
  period: .
  identifier: SimpleIdentifier
    token: call
    element: <null>
    staticType: int Function(String)
  element: <null>
  staticType: int Function(String)
''');
  }

  test_hasReceiver_typeAlias_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
}

typedef B = A;

void f() {
  B.foo;
}
''');

    var node = result.findNode.receiverPropertyExtraction('B.foo');
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: B
    element: <testLibrary>::@typeAlias::B
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  test_implicitCall_tearOff() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call() => 0;
}

A a;
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';

int Function() foo() {
  return a;
}
''');

    var node = result.findNode.unqualifiedNameExpression('a;');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: a
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::a
    invokeType: A Function()
    type: A
  staticType: A
V1: SimpleIdentifier
  token: a
  element: package:test/a.dart::@getter::a
  staticType: A
''');
  }

  test_implicitCall_tearOff_nullable() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call() => 0;
}

A? a;
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';

int Function() foo() {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'A?' can't be returned from the function 'foo' because it has a return type of 'int Function()'.
}
''');

    var node = result.findNode.unqualifiedNameExpression('a;');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: a
  resolution: GetterInvocationResolution
    element: package:test/a.dart::@getter::a
    invokeType: A? Function()
    type: A?
  staticType: A?
V1: SimpleIdentifier
  token: a
  element: package:test/a.dart::@getter::a
  staticType: A?
''');
  }

  test_ofClassName_augmentationAugments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
}

augment class A {
  augment static int get foo => 0;
}

void f() {
  A.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@class::A
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  test_ofClassName_augmentationAugments_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo();
}

augment class A {
  augment static void foo() {}
}

void f() {
  A.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: StaticQualifier
    name: A
    element: <testLibrary>::@class::A
  operator: .
  name: foo
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::A::@method::foo
    type: void Function()
  staticType: void Function()
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  element: <testLibrary>::@class::A::@method::foo
  staticType: void Function()
''');
  }

  test_ofClassName_augmentationAugments_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
}

augment class A {
  augment static set foo(int _) {}
}

void f() {
  A.foo = 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
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

  test_ofExtensionType_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A a) {
  a.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A
    staticType: A
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: int
  element: <testLibrary>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_ofExtensionType_read_nullableRepresentation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int? it) {
  int get foo => 0;
}

void f(A a) {
  a.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A
    staticType: A
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: int
  element: <testLibrary>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_ofExtensionType_read_nullableType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A? a) {
  a.foo;
//  ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A?
    staticType: A?
  operator: .
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: int
  element: <testLibrary>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_ofExtensionType_read_nullableType_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A? a) {
  a?.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A?
    staticType: A?
  operator: ?.
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int?
V1: PropertyAccess
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: int
  staticType: int?
''');
  }

  test_ofExtensionType_write() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(int _) {}
}

void f(A a) {
  a.foo = 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
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
    correspondingParameter: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extensionType::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_read_dynamicIdentifier_hashCode() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(dynamic a) {
  a.hashCode;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: dynamic
    staticType: dynamic
  operator: .
  name: hashCode
  resolution: GetterInvocationResolution
    element: dart:core::@class::Object::@getter::hashCode
    invokeType: int Function()
    type: int
  staticType: int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
    staticType: int
  element: dart:core::@class::Object::@getter::hashCode
  staticType: int
''');
  }

  test_read_dynamicIdentifier_identifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(dynamic a) {
  a.foo;
}
''');

    var node = result.findNode.singleReceiverPropertyExtraction;
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: dynamic
    staticType: dynamic
  operator: .
  name: foo
  resolution: DynamicPropertyReadResolution
    type: dynamic
  staticType: dynamic
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: <null>
    staticType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_read_interfaceType_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(int a) {
  a.foo;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.receiverPropertyExtraction('foo;');
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: int
    staticType: int
  operator: .
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
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
