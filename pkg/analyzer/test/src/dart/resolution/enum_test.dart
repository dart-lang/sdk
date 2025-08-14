// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationResolutionTest);
  });
}

@reflectiveTest
class EnumDeclarationResolutionTest extends PubPackageResolutionTest {
  test_constructor_argumentList_contextType() async {
    await assertNoErrorsInCode(r'''
enum E {
  v([]);
  const E(List<int> a);
}
''');

    var node = findNode.listLiteral('[]');
    assertResolvedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
  correspondingParameter: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
  staticType: List<int>
''');
  }

  test_constructor_argumentList_namedType() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(<void Function(double)>[]);
  const E(Object a);
}
''');

    var node = findNode.genericFunctionType('Function');
    assertResolvedNodeText(node, r'''
GenericFunctionType
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  functionKeyword: Function
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: double
        element2: dart:core::@class::double
        type: double
      declaredElement: <testLibraryFragment> null@null
        element: isPrivate
          type: double
    rightParenthesis: )
  declaredElement: GenericFunctionTypeElement
    parameters
      <empty>
        kind: required positional
        element:
          type: double
    returnType: void
    type: void Function(double)
  type: void Function(double)
''');
  }

  test_constructor_generic_noTypeArguments_named() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v.named(42);
  const E.named(T a);
}
''');

    var node = findNode.enumConstantDeclaration('v.');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: named
        element: <null>
        staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@enum::E::@constructor::named::@formalParameter::a
            substitution: {T: int}
          staticType: int
      rightParenthesis: )
  constructorElement2: ConstructorMember
    baseElement: <testLibrary>::@enum::E::@constructor::named
    substitution: {T: int}
  declaredElement: <testLibraryFragment> v@14
''');
  }

  test_constructor_generic_noTypeArguments_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v(42);
  const E(T a);
}
''');

    var node = findNode.enumConstantDeclaration('v(');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
            substitution: {T: int}
          staticType: int
      rightParenthesis: )
  constructorElement2: ConstructorMember
    baseElement: <testLibrary>::@enum::E::@constructor::new
    substitution: {T: int}
  declaredElement: <testLibraryFragment> v@14
''');
  }

  test_constructor_generic_typeArguments_named() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v<double>.named(42);
  const E.named(T a);
}
''');

    var node = findNode.enumConstantDeclaration('v<');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: double
          element2: dart:core::@class::double
          type: double
      rightBracket: >
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: named
        element: <null>
        staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@enum::E::@constructor::named::@formalParameter::a
            substitution: {T: double}
          staticType: double
      rightParenthesis: )
  constructorElement2: ConstructorMember
    baseElement: <testLibrary>::@enum::E::@constructor::named
    substitution: {T: double}
  declaredElement: <testLibraryFragment> v@14
''');
  }

  test_constructor_notGeneric_named() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.named(42);
  const E.named(int a);
}
''');

    var node = findNode.enumConstantDeclaration('v.');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: named
        element: <null>
        staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          correspondingParameter: <testLibrary>::@enum::E::@constructor::named::@formalParameter::a
          staticType: int
      rightParenthesis: )
  constructorElement2: <testLibrary>::@enum::E::@constructor::named
  declaredElement: <testLibraryFragment> v@11
''');
  }

  test_constructor_notGeneric_unnamed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(42);
  const E(int a);
}
''');

    var node = findNode.enumConstantDeclaration('v(');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          correspondingParameter: <testLibrary>::@enum::E::@constructor::new::@formalParameter::a
          staticType: int
      rightParenthesis: )
  constructorElement2: <testLibrary>::@enum::E::@constructor::new
  declaredElement: <testLibraryFragment> v@11
''');
  }

  test_constructor_notGeneric_unnamed_implicit() async {
    await assertNoErrorsInCode(r'''
enum E {
  v
}
''');

    var node = findNode.enumConstantDeclaration('v\n');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  constructorElement2: <testLibrary>::@enum::E::@constructor::new
  declaredElement: <testLibraryFragment> v@11
''');
  }

  test_constructor_unresolved_named() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.named(42);
  const E(int a);
}
''',
      [error(CompileTimeErrorCode.undefinedEnumConstructorNamed, 13, 5)],
    );

    var node = findNode.enumConstantDeclaration('v.');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: named
        element: <null>
        staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
  constructorElement2: <null>
  declaredElement: <testLibraryFragment> v@11
''');
  }

  test_constructor_unresolved_unnamed() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(42);
  const E.named(int a);
}
''',
      [error(CompileTimeErrorCode.undefinedEnumConstructorUnnamed, 11, 1)],
    );

    var node = findNode.enumConstantDeclaration('v(');
    assertResolvedNodeText(node, r'''
EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 42
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
  constructorElement2: <null>
  declaredElement: <testLibraryFragment> v@11
''');
  }

  test_field() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  final foo = 42;
}
''');

    var node = findNode.fieldDeclaration('foo =');
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: foo
        equals: =
        initializer: IntegerLiteral
          literal: 42
          staticType: int
        declaredElement: <testLibraryFragment> foo@22
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_getter() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  T get foo => throw 0;
}
''');

    var node = findNode.methodDeclaration('get foo');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: T
    element2: #E0 T
    type: T
  propertyKeyword: get
  name: foo
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: ThrowExpression
      throwKeyword: throw
      expression: IntegerLiteral
        literal: 0
        staticType: int
      staticType: Never
    semicolon: ;
  declaredElement: <testLibraryFragment> foo@25
    element: <testLibrary>::@enum::E::@getter::foo
      type: T Function()
''');
  }

  test_inference_listLiteral() async {
    await assertNoErrorsInCode(r'''
enum E1 {a, b}
enum E2 {a, b}

var v = [E1.a, E2.b];
''');

    var v = findElement2.topVar('v');
    assertType(v.type, 'List<Enum>');
  }

  test_interfaces() async {
    await assertNoErrorsInCode(r'''
class I {}
enum E implements I {
  v;
}
''');

    var node = findNode.implementsClause('implements');
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: I
      element2: <testLibrary>::@class::I
      type: I
''');
  }

  test_isEnumConstant() async {
    await assertNoErrorsInCode(r'''
enum E {
  a, b
}
''');

    expect(findElement2.field('a').isEnumConstant, isTrue);
    expect(findElement2.field('b').isEnumConstant, isTrue);

    expect(findElement2.field('values').isEnumConstant, isFalse);
  }

  test_method() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  int foo<U>(T t, U u) => 0;
}
''');

    var node = findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  name: foo
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: U
        declaredElement: <testLibraryFragment> U@27
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element2: #E0 T
        type: T
      name: t
      declaredElement: <testLibraryFragment> t@32
        element: isPublic
          type: T
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element2: #E1 U
        type: U
      name: u
      declaredElement: <testLibraryFragment> u@37
        element: isPublic
          type: U
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
      staticType: int
    semicolon: ;
  declaredElement: <testLibraryFragment> foo@23
    element: <testLibrary>::@enum::E::@method::foo
      type: int Function<U>(T, U)
''');
  }

  test_method_toString() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  String toString() => 'E';
}
''');

    var node = findNode.methodDeclaration('toString()');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: String
    element2: dart:core::@class::String
    type: String
  name: toString
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: SimpleStringLiteral
      literal: 'E'
    semicolon: ;
  declaredElement: <testLibraryFragment> toString@23
    element: <testLibrary>::@enum::E::@method::toString
      type: String Function()
''');
  }

  test_mixins() async {
    await assertNoErrorsInCode(r'''
mixin M {}
enum E with M {
  v;
}
''');

    var node = findNode.withClause('with M');
    assertResolvedNodeText(node, r'''
WithClause
  withKeyword: with
  mixinTypes
    NamedType
      name: M
      element2: <testLibrary>::@mixin::M
      type: M
''');
  }

  test_mixins_inference() async {
    await assertNoErrorsInCode(r'''
mixin M1<T> {}
mixin M2<T> on M1<T> {}
enum E with M1<int>, M2 {
  v;
}
''');

    var node = findNode.withClause('with');
    assertResolvedNodeText(node, r'''
WithClause
  withKeyword: with
  mixinTypes
    NamedType
      name: M1
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: <testLibrary>::@mixin::M1
      type: M1<int>
    NamedType
      name: M2
      element2: <testLibrary>::@mixin::M2
      type: M2<int>
''');
  }

  test_setter() async {
    await assertNoErrorsInCode(r'''
enum E<T> {
  v;
  set foo(T a) {}
}
''');

    var node = findNode.methodDeclaration('set foo');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  propertyKeyword: set
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element2: #E0 T
        type: T
      name: a
      declaredElement: <testLibraryFragment> a@29
        element: isPublic
          type: T
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment> foo@23
    element: <testLibrary>::@enum::E::@setter::foo
      type: void Function(T)
''');
  }

  test_value_underscore() async {
    await assertNoErrorsInCode(r'''
enum E { _ }

void f() {
  E._.index;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@enum::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _
      element: <testLibrary>::@enum::E::@getter::_
      staticType: E
    element: <testLibrary>::@enum::E::@getter::_
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: index
    element: dart:core::@class::Enum::@getter::index
    staticType: int
  staticType: int
''');
  }
}
