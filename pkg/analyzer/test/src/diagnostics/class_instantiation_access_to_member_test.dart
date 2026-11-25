// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassInstantiationAccessToMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ClassInstantiationAccessToMemberTest extends PubPackageResolutionTest {
  test_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  int i = 1;
}

typedef TA<T> = A<T>;

var x = TA<int>.i;
//      ^^^^^^^^^
// [diag.classInstantiationAccessToInstanceMember] The instance member 'i' can't be accessed on a class instantiation.
''');
  }

  test_extensionMember() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {}

extension E on A {
  int get i => 1;
}

var x = A<int>.i;
//      ^^^^^^^^
// [diag.classInstantiationAccessToUnknownMember] The class 'A' doesn't have a constructor named 'i'.
''');
  }

  test_instanceMember() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  int i = 1;
}

var x = A<int>.i;
//      ^^^^^^^^
// [diag.classInstantiationAccessToInstanceMember] The instance member 'i' can't be accessed on a class instantiation.
''');
  }

  test_instanceSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  set i(int value) {}
}

void foo() {
  A<int>.i = 7;
//^^^^^^^^
// [diag.classInstantiationAccessToInstanceMember] The instance member 'i' can't be accessed on a class instantiation.
}
''');
  }

  test_invalidAlias_compoundAssignment_undefinedOnType_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Unknown;
//             ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A<int>.foo += 1;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: InvalidType
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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
typedef A<T> = List<A<T>>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.foo += 1;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_invalidAlias_directAssignment_undefinedOnType_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Unknown;
//             ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A<int>.foo = 0;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: InvalidType
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    write: InvalidWriteResolution
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_directAssignment_undefinedOnType_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = List<A<T>>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.foo = 0;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    write: InvalidWriteResolution
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_invalidAlias_functionInstantiation_undefinedOnType_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Unknown;
//             ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A<int>.foo<int>;
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: InvalidType
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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
typedef A<T> = List<A<T>>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.foo<int>;
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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
typedef A<T> = Unknown;
//             ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A<int>.foo ??= 0;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: InvalidType
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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
typedef A<T> = List<A<T>>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.foo ??= 0;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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
typedef A<T> = Unknown;
//             ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A<int>.foo++;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: InvalidType
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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
typedef A<T> = List<A<T>>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.foo++;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_invalidAlias_propertyExtraction_objectMember_aliasCycle() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = B<T>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
typedef B<T> = A<T>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.hashCode;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: dynamic
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_invalidAlias_propertyExtraction_objectMember_invalidType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Unknown;
//             ^^^^^^^
// [diag.undefinedClass] Undefined class 'Unknown'.

void f() {
  A<int>.hashCode;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: InvalidType
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_invalidAlias_propertyExtraction_objectMember_selfReference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = List<A<T>>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.

void f() {
  A<int>.hashCode;
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: dynamic
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_compoundAssignment_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  int get foo => 0;

  set foo(int _) {}
}

void f() {
  R<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_compoundAssignment_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_compoundAssignment_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_compoundAssignment_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_compoundAssignment_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
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
    read: InvalidReadResolution
    write: InvalidWriteResolution
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

  test_noConstructors_compoundAssignment_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: Never
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_compoundAssignment_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_compoundAssignment_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: void
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_compoundAssignment_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
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
    read: InvalidReadResolution
    write: InvalidWriteResolution
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

  test_noConstructors_compoundAssignment_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.foo += 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
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
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_directAssignment_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  set foo(int _) {}
}

void f() {
  R<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_directAssignment_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_directAssignment_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_directAssignment_prefixed_undefinedOnType_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = void Function(T);
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F<int>.foo = 1;
//         ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'p.F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        importPrefix: ImportPrefixReference
          name: p
          period: .
          element: <testLibraryFragment>::@prefix::p
        name: F
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: package:test/a.dart::@typeAlias::F
        type: void Function(int)
          alias: package:test/a.dart::@typeAlias::F
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
        importPrefix: ImportPrefixReference
          name: p
          period: .
          element: <testLibraryFragment>::@prefix::p
        name: F
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: package:test/a.dart::@typeAlias::F
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

  test_noConstructors_directAssignment_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
          alias: <testLibrary>::@typeAlias::A
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_directAssignment_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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
    literal: 0
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

  test_noConstructors_directAssignment_typeExtension_legacyGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A<T>(T t);

extension on Type {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: void Function(int)
          alias: <testLibrary>::@typeAlias::A
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_directAssignment_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: Never
          alias: <testLibrary>::@typeAlias::A
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_directAssignment_typeExtension_nullableRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T,)?;

extension on Type {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: (int,)?
          alias: <testLibrary>::@typeAlias::A
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_directAssignment_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_directAssignment_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: void
          alias: <testLibrary>::@typeAlias::A
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_directAssignment_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo = 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
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

  test_noConstructors_directAssignment_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.foo = 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
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
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_directAssignment_undefinedOnType_typeVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<X> = X;

void f() {
  A<int>.foo = 0;
//^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: InvalidType
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    write: InvalidWriteResolution
  operator: =
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_functionInstantiation_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  void foo<X>() {}
}

void f() {
  R<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_functionInstantiation_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_functionInstantiation_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  void foo<X>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_functionInstantiation_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: dynamic
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_functionInstantiation_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'F.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
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
  function: ConstructorReference
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

  test_noConstructors_functionInstantiation_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: Never
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_functionInstantiation_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_functionInstantiation_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  void foo<T>() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: void
        alias: <testLibrary>::@typeAlias::A
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_functionInstantiation_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.foo<int>;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
//          ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'R.foo' doesn't have type parameters.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: ConstructorTearOff
    typeReference: ConstructorTypeReference
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: (int,)
        alias: <testLibrary>::@typeAlias::R
          typeArguments
            int
    selector: ConstructorSelector
      period: .
      name2: foo
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
V1: FunctionReference
  function: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
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

  test_noConstructors_ifNullAssignment_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  int get foo => 0;

  set foo(int _) {}
}

void f() {
  R<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
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
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: Never
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: void
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo ??= 1;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
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
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
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

  test_noConstructors_ifNullAssignment_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.foo ??= 0;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
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

  test_noConstructors_increment_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  int get foo => 0;

  set foo(int _) {}
}

void f() {
  R<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: dynamic
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
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
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
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
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: Never
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.

  set foo(int _) {}
//    ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: void
          alias: <testLibrary>::@typeAlias::A
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: A
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::A
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
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
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
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
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_increment_undefinedOnType_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.foo++;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: InvalidExpressionAssignmentTarget
    expression: ConstructorTearOff
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: (int,)
          alias: <testLibrary>::@typeAlias::R
            typeArguments
              int
      selector: ConstructorSelector
        period: .
        name2: foo
      element: <null>
      staticType: InvalidType
    read: InvalidReadResolution
    write: InvalidWriteResolution
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: PostfixExpression
  operand: ConstructorReference
    constructorName: ConstructorName
      type: NamedType
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: null
      period: .
      name: SimpleIdentifier
        token: foo
        element: <null>
        staticType: null
      element: <null>
    staticType: InvalidType
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  int get foo => 0;
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_objectMember_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

void f() {
  A<int>.hashCode;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: dynamic
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_objectMember_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.hashCode;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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
    name2: hashCode
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
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_objectMember_legacyGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A<T>(T t);

void f() {
  A<int>.hashCode;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_objectMember_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

void f() {
  A<int>.hashCode;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: Never
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_objectMember_nullableRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T,)?;

void f() {
  A<int>.hashCode;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: (int,)?
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_objectMember_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.hashCode;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_objectMember_typeVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<X> = X;

void f() {
  A<int>.hashCode;
//^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: InvalidType
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_objectMember_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

void f() {
  A<int>.hashCode;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: void
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_prefixed_objectMember_recordType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef R<T> = (T,);
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.R<int>.hashCode;
//         ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'p.R' doesn't have a constructor named 'hashCode'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::R
    type: (int,)
      alias: package:test/a.dart::@typeAlias::R
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: hashCode
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@typeAlias::R
      type: null
    period: .
    name: SimpleIdentifier
      token: hashCode
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_prefixed_undefinedOnType_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = void Function(T);
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F<int>.foo;
//         ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'p.F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: F
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: package:test/a.dart::@typeAlias::F
    type: void Function(int)
      alias: package:test/a.dart::@typeAlias::F
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
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: F
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@typeAlias::F
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

  test_noConstructors_propertyExtraction_tearOff_genericExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension E<T> on T {
  void foo() {}
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_tearOff_nullableObjectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object? {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_tearOff_objectExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Object {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_tearOff_objectMember_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

void f() {
  A<int>.toString;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: dynamic
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: toString
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_tearOff_objectMember_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.toString;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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
    name2: toString
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
      token: toString
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_tearOff_objectMember_legacyGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef void A<T>(T t);

void f() {
  A<int>.toString;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: void Function(int)
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: toString
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_tearOff_objectMember_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

void f() {
  A<int>.toString;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: Never
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: toString
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_tearOff_objectMember_nullableRecordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = (T,)?;

void f() {
  A<int>.toString;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: (int,)?
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: toString
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_tearOff_objectMember_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

void f() {
  R<int>.toString;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: toString
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: null
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_tearOff_objectMember_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

void f() {
  A<int>.toString;
//       ^^^^^^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'toString'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: void
      alias: <testLibrary>::@typeAlias::A
        typeArguments
          int
  selector: ConstructorSelector
    period: .
    name2: toString
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
      type: null
    period: .
    name: SimpleIdentifier
      token: toString
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_noConstructors_propertyExtraction_tearOff_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: dynamic
      alias: <testLibrary>::@typeAlias::A
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
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_propertyExtraction_tearOff_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noConstructors_propertyExtraction_tearOff_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: Never
      alias: <testLibrary>::@typeAlias::A
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
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_propertyExtraction_tearOff_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_tearOff_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  void foo() {}
//     ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: void
      alias: <testLibrary>::@typeAlias::A
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
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_propertyExtraction_typeExtension_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = dynamic;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: dynamic
      alias: <testLibrary>::@typeAlias::A
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
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_propertyExtraction_typeExtension_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  F<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
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

  test_noConstructors_propertyExtraction_typeExtension_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = Never;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: Never
      alias: <testLibrary>::@typeAlias::A
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
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_propertyExtraction_typeExtension_recordType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  R<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (int,)
      alias: <testLibrary>::@typeAlias::R
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
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
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

  test_noConstructors_propertyExtraction_typeExtension_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = void;

extension on Type {
  int get foo => 0;
//        ^^^
// [diag.unusedElement] The declaration 'foo' isn't referenced.
}

void f() {
  A<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'A' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: void
      alias: <testLibrary>::@typeAlias::A
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
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@typeAlias::A
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

  test_noConstructors_propertyExtraction_undefinedOnType_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

void f() {
  F<int>.foo;
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'F' doesn't have a constructor named 'foo'.
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

  test_staticMember() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  static int i = 1;
}

var x = A<int>.i;
//      ^^^^^^^^
// [diag.classInstantiationAccessToStaticMember] The static member 'i' can't be accessed on a class instantiation.
''');
  }

  test_staticSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  static set i(int value) {}
}

void bar() {
  A<int>.i = 7;
//^^^^^^^^
// [diag.classInstantiationAccessToStaticMember] The static member 'i' can't be accessed on a class instantiation.
}
''');
  }

  test_syntheticIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

var x = A<int>.;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }
}
