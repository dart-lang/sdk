// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IndexExpressionResolutionTest extends PubPackageResolutionTest {
  test_contextType_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator [](int index) => false;
  operator []=(String index, bool value) {}
}

void f(A a) {
  a[ g() ];
}

T g<T>() => throw 0;
''');

    var node = result.findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_contextType_readWrite_readLower() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](int index) => 0;
  operator []=(num index, int value) {}
}

void f(A a) {
  a[ g() ]++;
}

T g<T>() => throw 0;
''');

    var node = result.findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_contextType_readWrite_writeLower() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](num index) => 0;
  operator []=(int index, int value) {}
}

void f(A a) {
  a[ g() ]++;
//   ^^^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.
}

T g<T>() => throw 0;
''');

    var node = result.findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_contextType_write() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator [](int index) => false;
  operator []=(String index, bool value) {}
}

void f(A a) {
  a[ g() ] = true;
}

T g<T>() => throw 0;
''');

    var node = result.findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
  staticInvokeType: String Function()
  staticType: String
  typeArgumentTypes
    String
''');
  }

  test_indexAssignmentTarget_extensionOverride() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  operator[]=(int index, num value) {}
}

void f() {
  E(0)[1] = 2.3;
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: IndexAssignmentTarget
    receiver: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: null
    leftBracket: [
    index: IntegerLiteral
      literal: 1
      correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@extension::E::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: =
  value: DoubleLiteral
    literal: 2.3
    correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::value
    staticType: double
  staticType: double
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
      staticType: null
    leftBracket: [
    index: IntegerLiteral
      literal: 1
      correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 2.3
    correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@method::[]=
  writeType: num
  element: <null>
  staticType: double
''');
  }

  test_invalid_inDefaultValue_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f({a = b?[0]}) {}
//          ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');

    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/49101
    var node = result.findNode.indexExpression2('[0]');
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  resolution: InvalidIndexReadResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: IndexExpression
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_invalid_inDefaultValue_nullAware2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void F({a = b?[0]});
//                ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
//                  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');

    var node = result.findNode.indexExpression2('[0]');
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  resolution: InvalidIndexReadResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: IndexExpression
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator[](int index) => false;
}

void f(A a) {
  a[0];
}
''');

    var node = result.findNode.indexExpression2('a[0]');
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: <testLibrary>::@class::A::@method::[]
    invokeType: bool Function(int)
    type: bool
  staticType: bool
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');
  }

  test_read_cascade_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator[](int index) => false;
}

void f(A? a) {
  a?..[0]..[1];
}
''');

    var node1 = result.findNode.index('..[0]');
    assertResolvedNodeText(node1, r'''
IndexExpression
  period: ?..
  leftBracket: [
  index2: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');

    var node2 = result.findNode.index('..[1]');
    assertResolvedNodeText(node2, r'''
IndexExpression
  period: ..
  leftBracket: [
  index2: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');

    assertType(result.findNode.cascade('a?'), 'A?');
  }

  test_read_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  T operator[](int index) => throw 42;
}

void f(A<double> a) {
  a[0];
}
''');

    var node = result.findNode.indexExpression2('a[0]');
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A<double>
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: <testLibrary>::@class::A::@method::[]::@formalParameter::index
      substitution: {T: double}
    staticType: int
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: SubstitutedMethodElementImpl
      baseElement: <testLibrary>::@class::A::@method::[]
      substitution: {T: double}
    invokeType: double Function(int)
    type: double
  staticType: double
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A<double>
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: <testLibrary>::@class::A::@method::[]::@formalParameter::index
      substitution: {T: double}
    staticType: int
  rightBracket: ]
  element: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::A::@method::[]
    substitution: {T: double}
  staticType: double
''');
  }

  test_read_index_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    this[super];
//       ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }

  int operator[](Object index) => 0;
}
''');

    var node = result.findNode.singleIndexExpression2;
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: ThisExpression
    thisKeyword: this
    staticType: A
  leftBracket: [
  index: SuperExpression
    superKeyword: super
    staticType: A
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: <testLibrary>::@class::A::@method::[]
    invokeType: int Function(Object)
    type: int
  staticType: int
V1: IndexExpression
  target: ThisExpression
    thisKeyword: this
    staticType: A
  leftBracket: [
  index: SuperExpression
    superKeyword: super
    staticType: A
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: int
''');
  }

  test_read_index_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> a) {
  a[b];
//  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
}
''');

    var node = result.findNode.singleIndexExpression2;
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: List<int>
  leftBracket: [
  index: SimpleIdentifier
    token: b
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: dart:core::@class::List::@method::[]::@formalParameter::index
      substitution: {E: int}
    element: <null>
    staticType: InvalidType
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: SubstitutedMethodElementImpl
      baseElement: dart:core::@class::List::@method::[]
      substitution: {E: int}
    invokeType: int Function(int)
    type: int
  staticType: int
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: List<int>
  leftBracket: [
  index: SimpleIdentifier
    token: b
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: dart:core::@class::List::@method::[]::@formalParameter::index
      substitution: {E: int}
    element: <null>
    staticType: InvalidType
  rightBracket: ]
  element: SubstitutedMethodElementImpl
    baseElement: dart:core::@class::List::@method::[]
    substitution: {E: int}
  staticType: int
''');
  }

  test_read_null() async {
    var result = await resolveTestCode(r'''
void f(Null a) {
  a?[0];
}
''');

    var node = result.findNode.indexExpression2('a?[0]');
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Null
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  resolution: <null>
  staticType: Never?
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Null
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: Never?
''');
  }

  test_read_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator[](int index) => false;
}

void f(A? a) {
  a?[0];
}
''');

    var node = result.findNode.indexExpression2('a?[0]');
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: <testLibrary>::@class::A::@method::[]
    invokeType: bool Function(int)
    type: bool?
  staticType: bool?
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool?
''');
  }

  test_read_ofExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  bool operator[](int index) => false;
}

void f() {
  0[1];
}
''');

    var node = result.findNode.singleIndexExpression2;
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: IntegerLiteral
    literal: 0
    staticType: int
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: <testLibrary>::@extension::E::@method::[]
    invokeType: bool Function(int)
    type: bool
  staticType: bool
V1: IndexExpression
  target: IntegerLiteral
    literal: 0
    staticType: int
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@extension::E::@method::[]
  staticType: bool
''');
  }

  test_read_ofExtension_augmentation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {}

void f() {
  0[1];
}

augment extension E {
  bool operator[](int index) => false;
}
''');

    var node = result.findNode.singleIndexExpression2;
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: IntegerLiteral
    literal: 0
    staticType: int
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: <testLibrary>::@extension::E::@method::[]
    invokeType: bool Function(int)
    type: bool
  staticType: bool
V1: IndexExpression
  target: IntegerLiteral
    literal: 0
    staticType: int
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@extension::E::@method::[]
  staticType: bool
''');
  }

  test_read_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator[](int index) => false;
}

void f(Object? x) {
  (switch (x) {
    _ => A(),
  }[0]);
}
''');

    var node = result.findNode.indexExpression2('[0]');
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SwitchExpression
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
        expression2: ConstructorInvocation
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
        expression(v1): InstanceCreationExpression
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
    rightBracket: }
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: <testLibrary>::@class::A::@method::[]
    invokeType: bool Function(int)
    type: bool
  staticType: bool
V1: IndexExpression
  target: SwitchExpression
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
        expression: InstanceCreationExpression
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
    rightBracket: }
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');
  }

  test_read_target_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a[0];
}
''');

    var node = result.findNode.singleIndexExpression2;
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  resolution: DynamicIndexReadResolution
    type: dynamic
  staticType: dynamic
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: dynamic
''');
  }

  test_read_target_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  a[0];
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.singleIndexExpression2;
    assertResolvedNodeText(node, r'''
IndexExpression2
  receiver: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  resolution: InvalidIndexReadResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: IndexExpression
  target: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_readWrite_assignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

void f(A a) {
  a[0] += 1.2;
}
''');

    var node = result.findNode.assignment('a[0]');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: double
  readElement: <testLibrary>::@class::A::@method::[]
  readType: num
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: double
''');
  }

  test_readWrite_assignment_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  T operator[](int index) => throw 42;
  void operator[]=(int index, T value) {}
}

void f(A<double> a) {
  a[0] += 1.2;
}
''');

    var node = result.findNode.assignment('a[0]');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A<double>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
        substitution: {T: double}
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: dart:core::@class::double::@method::+::@formalParameter::other
    staticType: double
  readElement: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::A::@method::[]
    substitution: {T: double}
  readType: double
  writeElement: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::A::@method::[]=
    substitution: {T: double}
  writeType: double
  element: dart:core::@class::double::@method::+
  staticType: double
''');
  }

  test_readWrite_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

void f(A? a) {
  a?[0] += 1.2;
}
''');

    var node = result.findNode.assignment('a?[0]');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: IndexExpression
    target2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index2: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide2: DoubleLiteral
    literal: 1.2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: double
  readElement: <testLibrary>::@class::A::@method::[]
  readType: num
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: double?
''');
  }

  test_receiver() async {
    var result = await resolveTestCode(r'''
void f(List<int>? x) {
  x![0];
}
''');

    var node = result.findNode.singleIndexExpression2;
    expect(node.receiver, isA<NullAssertionExpression>());
  }

  test_rewrite_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  T Function<T>(T) operator[](int i);
}
abstract class B {
  A get a;
}
int Function(int)? f(B? b) => b?.a[0];
''');

    var node = result.findNode.functionReference('b?.a[0]');
    assertResolvedNodeText(node, r'''FunctionReference
  function2: IndexExpression2
    receiver: PropertyAccess
      target2: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: B?
      operator: ?.
      propertyName: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::i
      staticType: int
    rightBracket: ]
    resolution: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: T Function<T>(T) Function(int)
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  function(v1): IndexExpression
    target: PropertyAccess
      target: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: B?
      operator: ?.
      propertyName: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::i
      staticType: int
    rightBracket: ]
    element: <testLibrary>::@class::A::@method::[]
    staticType: T Function<T>(T)
  staticType: int Function(int)?
  typeArgumentTypes
    int
''');
  }

  test_write() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(A a) {
  a[0] = 1.2;
}
''');

    var node = result.findNode.directAssignment('a[0]');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: IndexAssignmentTarget
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
    read: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: =
  value: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  staticType: double
V1: AssignmentExpression
  leftHandSide: IndexExpression
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
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: double
''');
  }

  test_write_cascade_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void operator[]=(int index, A a) {}
}

void f(A? a) {
  a?..[0] = a..[1] = a;
}
''');

    var node = result.findNode.cascade('a?..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  cascadeSections2
    AssignmentExpression
      leftHandSide2: IndexExpression
        period: ?..
        leftBracket: [
        index2: IntegerLiteral
          literal: 0
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: =
      rightHandSide2: SimpleIdentifier
        token: a
        correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      readElement: <null>
      readType: null
      writeElement: <testLibrary>::@class::A::@method::[]=
      writeType: A
      element: <null>
      staticType: A
    AssignmentExpression
      leftHandSide2: IndexExpression
        period: ..
        leftBracket: [
        index2: IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: =
      rightHandSide2: SimpleIdentifier
        token: a
        correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      readElement: <null>
      readType: null
      writeElement: <testLibrary>::@class::A::@method::[]=
      writeType: A
      element: <null>
      staticType: A
  staticType: A?
''');
  }

  test_write_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void operator[]=(int index, T value) {}
}

void f(A<double> a) {
  a[0] = 1.2;
}
''');

    var node = result.findNode.directAssignment('a[0]');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: IndexAssignmentTarget
    receiver: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A<double>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
        substitution: {T: double}
      staticType: int
    rightBracket: ]
    read: <null>
    write: MethodIndexWriteResolution
      element: SubstitutedMethodElementImpl
        baseElement: <testLibrary>::@class::A::@method::[]=
        substitution: {T: double}
      invokeType: void Function(int, double)
      acceptedType: double
  operator: =
  value: DoubleLiteral
    literal: 1.2
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
      substitution: {T: double}
    staticType: double
  staticType: double
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A<double>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
        substitution: {T: double}
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: SubstitutedFormalParameterElementImpl
      baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
      substitution: {T: double}
    staticType: double
  readElement: <null>
  readType: null
  writeElement: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::A::@method::[]=
    substitution: {T: double}
  writeType: double
  element: <null>
  staticType: double
''');
  }

  test_write_never_alias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef N = Never;

void f(N x) {
  x[0] = 0;
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//  ^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.directAssignment('x[0]');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: IndexAssignmentTarget
    receiver: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
        alias: <testLibrary>::@typeAlias::N
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    read: <null>
    write: <null>
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: Never
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Never
        alias: <testLibrary>::@typeAlias::N
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
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
  writeType: null
  element: <null>
  staticType: Never
''');
  }

  test_write_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(A? a) {
  a?[0] = 1.2;
}
''');

    var node = result.findNode.assignment('a?[0]');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: IndexExpression
    target2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index2: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide2: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: double?
''');
  }

  test_write_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(Object? x) {
  (switch (x) {
    _ => A(),
  }[0] = 1.2);
}
''');

    var node = result.findNode.directAssignment('[0]');
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: IndexAssignmentTarget
    receiver: SwitchExpression
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
          expression2: ConstructorInvocation
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
          expression(v1): InstanceCreationExpression
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
      rightBracket: }
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: <null>
    write: MethodIndexWriteResolution
      element: <testLibrary>::@class::A::@method::[]=
      invokeType: void Function(int, num)
      acceptedType: num
  operator: =
  value: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  staticType: double
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SwitchExpression
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
          expression: InstanceCreationExpression
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
      rightBracket: }
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: double
''');
  }
}
