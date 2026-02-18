// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    element: <null>
    type: void
  functionKeyword: Function
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: double
        element: dart:core::@class::double
        type: double
      declaredFragment: <testLibraryFragment> null@null
        element: isPrivate
          type: double
    rightParenthesis: )
  declaredFragment: GenericFunctionTypeElement
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
  constructorElement: ConstructorMember
    baseElement: <testLibrary>::@enum::E::@constructor::named
    substitution: {T: int}
  declaredFragment: <testLibraryFragment> v@14
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
  constructorElement: ConstructorMember
    baseElement: <testLibrary>::@enum::E::@constructor::new
    substitution: {T: int}
  declaredFragment: <testLibraryFragment> v@14
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
          element: dart:core::@class::double
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
  constructorElement: ConstructorMember
    baseElement: <testLibrary>::@enum::E::@constructor::named
    substitution: {T: double}
  declaredFragment: <testLibraryFragment> v@14
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
  constructorElement: <testLibrary>::@enum::E::@constructor::named
  declaredFragment: <testLibraryFragment> v@11
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
  constructorElement: <testLibrary>::@enum::E::@constructor::new
  declaredFragment: <testLibraryFragment> v@11
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
  constructorElement: <testLibrary>::@enum::E::@constructor::new
  declaredFragment: <testLibraryFragment> v@11
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
      [error(diag.undefinedEnumConstructorNamed, 13, 5)],
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
  constructorElement: <null>
  declaredFragment: <testLibraryFragment> v@11
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
      [error(diag.undefinedEnumConstructorUnnamed, 11, 1)],
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
  constructorElement: <null>
  declaredFragment: <testLibraryFragment> v@11
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
        declaredFragment: <testLibraryFragment> foo@22
  semicolon: ;
  declaredFragment: <null>
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
    element: #E0 T
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
  declaredFragment: <testLibraryFragment> foo@25
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
      element: <testLibrary>::@class::I
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
    element: dart:core::@class::int
    type: int
  name: foo
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: U
        declaredFragment: <testLibraryFragment> U@27
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element: #E0 T
        type: T
      name: t
      declaredFragment: <testLibraryFragment> t@32
        element: isPublic
          type: T
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element: #E1 U
        type: U
      name: u
      declaredFragment: <testLibraryFragment> u@37
        element: isPublic
          type: U
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
      staticType: int
    semicolon: ;
  declaredFragment: <testLibraryFragment> foo@23
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
    element: dart:core::@class::String
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
  declaredFragment: <testLibraryFragment> toString@23
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
      element: <testLibrary>::@mixin::M
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@mixin::M1
      type: M1<int>
    NamedType
      name: M2
      element: <testLibrary>::@mixin::M2
      type: M2<int>
''');
  }

  test_nameWithTypeParameters_hasTypeParameters() async {
    var code = r'''
enum A<T extends int> {v}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          extendsKeyword: extends
          bound: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          declaredFragment: <testLibraryFragment> T@7
            defaultType: int
      rightBracket: >
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        constructorElement: ConstructorMember
          baseElement: <testLibrary>::@enum::A::@constructor::new
          substitution: {T: int}
        declaredFragment: <testLibraryFragment> v@23
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_nameWithTypeParameters_noTypeParameters() async {
    var code = r'''
enum A {v}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: A
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@8
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedOptional_final() async {
    await assertNoErrorsInCode(r'''
enum A({final int a = 0}) { v(a: 1) }
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          keyword: final
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: <testLibraryFragment> a@18
            element: isFinal isPublic
              type: int
              field: <testLibrary>::@enum::A::@field::a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
          staticType: int
        declaredFragment: <testLibraryFragment> a@18
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@enum::A::@field::a
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A Function({int a})
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              NamedExpression
                name: Label
                  label: SimpleIdentifier
                    token: a
                    element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
                    staticType: null
                  colon: :
                expression: IntegerLiteral
                  literal: 1
                  staticType: int
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@28
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_final() async {
    await assertNoErrorsInCode(r'''
enum A({required final int a}) { v(a: 0) }
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          keyword: final
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: <testLibraryFragment> a@27
            element: isFinal isPublic
              type: int
              field: <testLibrary>::@enum::A::@field::a
        declaredFragment: <testLibraryFragment> a@27
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@enum::A::@field::a
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A Function({required int a})
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              NamedExpression
                name: Label
                  label: SimpleIdentifier
                    token: a
                    element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
                    staticType: null
                  colon: :
                expression: IntegerLiteral
                  literal: 0
                  staticType: int
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@33
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_final() async {
    await assertNoErrorsInCode(r'''
enum A(final int a(String x)) { v(foo) }
int foo(String _) => 0;
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FunctionTypedFormalParameter
        keyword: final
        returnType: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: String
              element: dart:core::@class::String
              type: String
            name: x
            declaredFragment: <testLibraryFragment> x@26
              element: isPublic
                type: String
          rightParenthesis: )
        declaredFragment: <testLibraryFragment> a@17
          element: isFinal isPublic
            type: int Function(String)
            field: <testLibrary>::@enum::A::@field::a
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A Function(int Function(String))
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: foo
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
                element: <testLibrary>::@function::foo
                staticType: int Function(String)
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@32
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_final() async {
    await assertNoErrorsInCode(r'''
enum A(final int a) { v(0) }
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        keyword: final
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@17
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@enum::A::@field::a
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A Function(int)
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 0
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
                staticType: int
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@22
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
enum A(int this.a) {
  v(0);
  final int a;
}
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FieldFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        thisKeyword: this
        period: .
        name: a
        declaredFragment: <testLibraryFragment> a@16
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@enum::A::@field::a
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A Function(int)
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 0
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
                staticType: int
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@23
    semicolon: ;
    members
      FieldDeclaration
        fields: VariableDeclarationList
          keyword: final
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          variables
            VariableDeclaration
              name: a
              declaredFragment: <testLibraryFragment> a@41
        semicolon: ;
        declaredFragment: <null>
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_hasTypeParameters_named() async {
    await assertNoErrorsInCode(r'''
enum A<T>.named(T t) { v.named(0) }
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@7
            defaultType: dynamic
      rightBracket: >
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: T
          element: #E0 T
          type: T
        name: t
        declaredFragment: <testLibraryFragment> t@18
          element: isPublic
            type: T
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> named@10
      element: <testLibrary>::@enum::A::@constructor::named
        type: A<T> Function(T)
  body: EnumBody
    leftBracket: {
    constants
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
                literal: 0
                correspondingParameter: ParameterMember
                  baseElement: <testLibrary>::@enum::A::@constructor::named::@formalParameter::t
                  substitution: {T: int}
                staticType: int
            rightParenthesis: )
        constructorElement: ConstructorMember
          baseElement: <testLibrary>::@enum::A::@constructor::named
          substitution: {T: int}
        declaredFragment: <testLibraryFragment> v@23
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_hasTypeParameters_unnamed() async {
    await assertNoErrorsInCode(r'''
enum A<T>(T t) { v(0) }
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@7
            defaultType: dynamic
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: T
          element: #E0 T
          type: T
        name: t
        declaredFragment: <testLibraryFragment> t@12
          element: isPublic
            type: T
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A<T> Function(T)
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 0
                correspondingParameter: ParameterMember
                  baseElement: <testLibrary>::@enum::A::@constructor::new::@formalParameter::t
                  substitution: {T: int}
                staticType: int
            rightParenthesis: )
        constructorElement: ConstructorMember
          baseElement: <testLibrary>::@enum::A::@constructor::new
          substitution: {T: int}
        declaredFragment: <testLibraryFragment> v@17
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_noTypeParameters_named() async {
    await assertNoErrorsInCode(r'''
enum A.named(int a) { v.named(0) }
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@17
          element: isPublic
            type: int
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> named@7
      element: <testLibrary>::@enum::A::@constructor::named
        type: A Function(int)
  body: EnumBody
    leftBracket: {
    constants
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
                literal: 0
                correspondingParameter: <testLibrary>::@enum::A::@constructor::named::@formalParameter::a
                staticType: int
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::named
        declaredFragment: <testLibraryFragment> v@22
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_noTypeParameters_unnamed() async {
    await assertNoErrorsInCode(r'''
enum A(int a) { v(0) }
''');

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@11
          element: isPublic
            type: int
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A Function(int)
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 0
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
                staticType: int
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@16
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructor_scopes() async {
    await assertNoErrorsInCode(r'''
const foo = 0;
enum A<@foo T>([@foo int x = foo]) {
  v;
  static const foo = 1;
}
''');

    var node = findNode.singlePrimaryConstructorDeclaration;
    assertResolvedNodeText(node, r'''
PrimaryConstructorDeclaration
  typeName: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        metadata
          Annotation
            atSign: @
            name: SimpleIdentifier
              token: foo
              element: <testLibrary>::@getter::foo
              staticType: null
            element: <testLibrary>::@getter::foo
        name: T
        declaredFragment: <testLibraryFragment> T@27
          defaultType: dynamic
    rightBracket: >
  formalParameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        metadata
          Annotation
            atSign: @
            name: SimpleIdentifier
              token: foo
              element: <testLibrary>::@enum::A::@getter::foo
              staticType: null
            element: <testLibrary>::@enum::A::@getter::foo
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: x
        declaredFragment: <testLibraryFragment> x@40
          element: isPublic
            type: int
      separator: =
      defaultValue: SimpleIdentifier
        token: foo
        element: <testLibrary>::@enum::A::@getter::foo
        staticType: int
      declaredFragment: <testLibraryFragment> x@40
        element: isPublic
          type: int
    rightDelimiter: ]
    rightParenthesis: )
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@enum::A::@constructor::new
      type: A<T> Function([int])
''');
  }

  test_primaryConstructor_typeParameters() async {
    await assertNoErrorsInCode(r'''
enum E<T extends U, U extends num>(T t, U u) {
  v(0, 0);
}
''');

    var node = findNode.singlePrimaryConstructorDeclaration;
    assertResolvedNodeText(node, r'''
PrimaryConstructorDeclaration
  typeName: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        extendsKeyword: extends
        bound: NamedType
          name: U
          element: #E0 U
          type: U
        declaredFragment: <testLibraryFragment> T@7
          defaultType: num
      TypeParameter
        name: U
        extendsKeyword: extends
        bound: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        declaredFragment: <testLibraryFragment> U@20
          defaultType: num
    rightBracket: >
  formalParameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element: #E1 T
        type: T
      name: t
      declaredFragment: <testLibraryFragment> t@37
        element: isPublic
          type: T
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element: #E0 U
        type: U
      name: u
      declaredFragment: <testLibraryFragment> u@42
        element: isPublic
          type: U
    rightParenthesis: )
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@enum::E::@constructor::new
      type: E<T, U> Function(T, U)
''');
  }

  test_primaryConstructorBody_duplicate() async {
    await assertErrorsInCode(
      r'''
enum A(bool x, bool y) {
  v(true, true);
  this : assert(x) {
    y;
  }
  this : assert(!x) {
    !y;
  }
}
''',
      [
        error(diag.constConstructorWithBody, 61, 1),
        error(diag.multiplePrimaryConstructorBodyDeclarations, 76, 4),
      ],
    );

    var node = findNode.singleEnumDeclaration;
    assertResolvedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: bool
          element: dart:core::@class::bool
          type: bool
        name: x
        declaredFragment: <testLibraryFragment> x@12
          element: isPublic
            type: bool
      parameter: SimpleFormalParameter
        type: NamedType
          name: bool
          element: dart:core::@class::bool
          type: bool
        name: y
        declaredFragment: <testLibraryFragment> y@20
          element: isPublic
            type: bool
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@enum::A::@constructor::new
        type: A Function(bool, bool)
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              BooleanLiteral
                literal: true
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::x
                staticType: bool
              BooleanLiteral
                literal: true
                correspondingParameter: <testLibrary>::@enum::A::@constructor::new::@formalParameter::y
                staticType: bool
            rightParenthesis: )
        constructorElement: <testLibrary>::@enum::A::@constructor::new
        declaredFragment: <testLibraryFragment> v@27
    semicolon: ;
    members
      PrimaryConstructorBody
        thisKeyword: this
        colon: :
        initializers
          AssertInitializer
            assertKeyword: assert
            leftParenthesis: (
            condition: SimpleIdentifier
              token: x
              element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::x
              staticType: bool
            rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: y
                  element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::y
                  staticType: bool
                semicolon: ;
            rightBracket: }
      PrimaryConstructorBody
        thisKeyword: this
        colon: :
        initializers
          AssertInitializer
            assertKeyword: assert
            leftParenthesis: (
            condition: PrefixExpression
              operator: !
              operand: SimpleIdentifier
                token: x
                element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::x
                staticType: bool
              element: <null>
              staticType: bool
            rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: PrefixExpression
                  operator: !
                  operand: SimpleIdentifier
                    token: y
                    element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::y
                    staticType: bool
                  element: <null>
                  staticType: bool
                semicolon: ;
            rightBracket: }
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@5
''');
  }

  test_primaryConstructorBody_metadata() async {
    await assertNoErrorsInCode(r'''
enum E(int a) {
  v(0);
  @deprecated
  this;
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: deprecated
        element: dart:core::@getter::deprecated
        staticType: null
      element: dart:core::@getter::deprecated
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_metadata_noDeclaration() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  @deprecated
  this;
}
''',
      [error(diag.primaryConstructorBodyWithoutDeclaration, 30, 4)],
    );

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: deprecated
        element: dart:core::@getter::deprecated
        staticType: null
      element: dart:core::@getter::deprecated
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_noDeclaration() async {
    await assertErrorsInCode(
      r'''
enum A/*(bool x, int y)*/ {
  v();
  this : assert(x) {
    y;
  }
}
''',
      [
        error(diag.primaryConstructorBodyWithoutDeclaration, 37, 4),
        error(diag.undefinedIdentifier, 51, 1),
        error(diag.undefinedIdentifier, 60, 1),
      ],
    );

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
        element: <null>
        staticType: InvalidType
      rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: y
            element: <null>
            staticType: InvalidType
          semicolon: ;
      rightBracket: }
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_declaringFormalParameter_optionalNamed() async {
    await assertNoErrorsInCode(r'''
enum A({final x = false}) {
  v(x: true);
  this : assert(x);
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
        element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::x
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_declaringFormalParameter_requiredPositional() async {
    await assertNoErrorsInCode(r'''
enum A(final bool a) {
  v(true);
  this : assert(a);
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: a
        element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::a
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
enum A(this.x) {
  v(true);
  final bool x;
  this : assert(x);
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: x
        element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::x
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance() async {
    await assertNoErrorsInCode(r'''
enum A(int foo) {
  v(0);
  final bar = foo;
}
''');

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: bar
        equals: =
        initializer: SimpleIdentifier
          token: foo
          element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          staticType: int
        declaredFragment: <testLibraryFragment> bar@34
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance_declaringFormal() async {
    await assertNoErrorsInCode(r'''
enum A(final int foo) {
  v(0);
  final bar = foo;
}
''');

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: bar
        equals: =
        initializer: SimpleIdentifier
          token: foo
          element: <testLibrary>::@enum::A::@constructor::new::@formalParameter::foo
          staticType: int
        declaredFragment: <testLibraryFragment> bar@40
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance_late() async {
    await assertErrorsInCode(
      r'''
enum A(int foo) {
  v(0);
  late final bar = foo;
}
''',
      [
        error(diag.lateFinalFieldWithConstConstructor, 28, 4),
        error(diag.undefinedIdentifier, 45, 3),
      ],
    );

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: final
    variables
      VariableDeclaration
        name: bar
        equals: =
        initializer: SimpleIdentifier
          token: foo
          element: <null>
          staticType: InvalidType
        declaredFragment: <testLibraryFragment> bar@39
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_primaryInitializerScope_fieldInitializer_static() async {
    await assertErrorsInCode(
      r'''
enum A(int foo) {
  v(0);
  static var bar = foo;
}
''',
      [error(diag.undefinedIdentifier, 45, 3)],
    );

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  staticKeyword: static
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: bar
        equals: =
        initializer: SimpleIdentifier
          token: foo
          element: <null>
          staticType: InvalidType
        declaredFragment: <testLibraryFragment> bar@39
  semicolon: ;
  declaredFragment: <null>
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
        element: #E0 T
        type: T
      name: a
      declaredFragment: <testLibraryFragment> a@29
        element: isPublic
          type: T
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> foo@23
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
