// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationResolutionTest);
    defineReflectiveTests(ClassDeclarationResolutionTest_constructor_super);
    defineReflectiveTests(
      ClassDeclarationResolutionTest_primaryConstructor_super,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ClassDeclarationResolutionTest extends PubPackageResolutionTest {
  test_element_allSupertypes() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B {}
mixin C {}
class D {}
class E {}

class X1 extends A {}
class X2 implements B {}
class X3 extends A implements B {}
class X4 extends A with B implements C {}
class X5 extends A with B, C implements D, E {}
''');

    assertElementTypes(findElement2.class_('X1').allSupertypes, [
      'Object',
      'A',
    ]);
    assertElementTypes(findElement2.class_('X2').allSupertypes, [
      'Object',
      'B',
    ]);
    assertElementTypes(findElement2.class_('X3').allSupertypes, [
      'Object',
      'A',
      'B',
    ]);
    assertElementTypes(findElement2.class_('X4').allSupertypes, [
      'Object',
      'A',
      'B',
      'C',
    ]);
    assertElementTypes(findElement2.class_('X5').allSupertypes, [
      'Object',
      'A',
      'B',
      'C',
      'D',
      'E',
    ]);
  }

  test_element_allSupertypes_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T, U> {}
class C<T> extends B<int, T> {}

class X1 extends A<String> {}
class X2 extends B<String, List<int>> {}
class X3 extends C<double> {}
''');

    assertElementTypes(findElement2.class_('X1').allSupertypes, [
      'Object',
      'A<String>',
    ]);
    assertElementTypes(findElement2.class_('X2').allSupertypes, [
      'Object',
      'B<String, List<int>>',
    ]);
    assertElementTypes(findElement2.class_('X3').allSupertypes, [
      'Object',
      'B<int, double>',
      'C<double>',
    ]);
  }

  test_element_allSupertypes_recursive() async {
    await assertErrorsInCode(
      r'''
class A extends B {}
class B extends C {}
class C extends A {}

class X extends A {}
''',
      [
        error(diag.recursiveInterfaceInheritance, 6, 1),
        error(diag.recursiveInterfaceInheritance, 27, 1),
        error(diag.recursiveInterfaceInheritance, 48, 1),
      ],
    );

    assertElementTypes(findElement2.class_('X').allSupertypes, ['A', 'Object']);
  }

  test_element_typeFunction_extends() async {
    await assertErrorsInCode(
      r'''
class A extends Function {}
''',
      [error(diag.finalClassExtendedOutsideOfLibrary, 16, 8)],
    );
    var a = findElement2.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_element_typeFunction_extends_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A extends Function {}
''',
      [error(diag.deprecatedExtendsFunction, 32, 8)],
    );
    var a = findElement2.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_element_typeFunction_with() async {
    await assertErrorsInCode(
      r'''
mixin A {}
mixin B {}
class C extends Object with A, Function, B {}
''',
      [error(diag.classUsedAsMixin, 53, 8)],
    );

    assertElementTypes(findElement2.class_('C').mixins, ['A', 'B']);
  }

  test_element_typeFunction_with_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
mixin A {}
mixin B {}
class C extends Object with A, Function, B {}
''',
      [error(diag.deprecatedMixinFunction, 69, 8)],
    );

    assertElementTypes(findElement2.class_('C').mixins, ['A', 'B']);
  }

  test_issue32815() async {
    await assertErrorsInCode(
      r'''
class A<T> extends B<T> {}
class B<T> extends A<T> {}
class C<T> extends B<T> implements I<T> {}

abstract class I<T> {}

main() {
  Iterable<I<int>> x = [new C()];
}
''',
      [
        error(diag.recursiveInterfaceInheritance, 6, 1),
        error(diag.recursiveInterfaceInheritance, 33, 1),
        error(diag.unusedLocalVariable, 150, 1),
      ],
    );
  }

  test_nameWithTypeParameters_hasTypeParameters() async {
    var code = r'''
class A<T extends int> {}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
          declaredFragment: <testLibraryFragment> T@8
            defaultType: int
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_nameWithTypeParameters_noTypeParameters() async {
    var code = r'''
class A {}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedOptional_final() async {
    await assertNoErrorsInCode(r'''
class A({final int a = 0});
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
          declaredFragment: <testLibraryFragment> a@19
            element: isFinal isPublic
              type: int
              field: <testLibrary>::@class::A::@field::a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
          staticType: int
        declaredFragment: <testLibraryFragment> a@19
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@class::A::@field::a
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function({int a})
  body: EmptyClassBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_final() async {
    await assertNoErrorsInCode(r'''
class A({required final int a});
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
          declaredFragment: <testLibraryFragment> a@28
            element: isFinal isPublic
              type: int
              field: <testLibrary>::@class::A::@field::a
        declaredFragment: <testLibraryFragment> a@28
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@class::A::@field::a
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function({required int a})
  body: EmptyClassBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_final() async {
    await assertNoErrorsInCode(r'''
class A(final int a(String x));
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
            declaredFragment: <testLibraryFragment> x@27
              element: isPublic
                type: String
          rightParenthesis: )
        declaredFragment: <testLibraryFragment> a@18
          element: isFinal isPublic
            type: int Function(String)
            field: <testLibrary>::@class::A::@field::a
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function(int Function(String))
  body: EmptyClassBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_final() async {
    await assertNoErrorsInCode(r'''
class A(final int a) {}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
        declaredFragment: <testLibraryFragment> a@18
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@class::A::@field::a
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_var() async {
    await assertNoErrorsInCode(r'''
class A(var int a) {}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        keyword: var
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@16
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@class::A::@field::a
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_field_staticConst() async {
    await assertNoErrorsInCode(r'''
class A(final String a, final bool b) {
  static const int foo = 0;
  static const int bar = 1;
}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        keyword: final
        type: NamedType
          name: String
          element: dart:core::@class::String
          type: String
        name: a
        declaredFragment: <testLibraryFragment> a@21
          element: isFinal isPublic
            type: String
            field: <testLibrary>::@class::A::@field::a
      parameter: SimpleFormalParameter
        keyword: final
        type: NamedType
          name: bool
          element: dart:core::@class::bool
          type: bool
        name: b
        declaredFragment: <testLibraryFragment> b@35
          element: isFinal isPublic
            type: bool
            field: <testLibrary>::@class::A::@field::b
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function(String, bool)
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: const
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          variables
            VariableDeclaration
              name: foo
              equals: =
              initializer: IntegerLiteral
                literal: 0
                staticType: int
              declaredFragment: <testLibraryFragment> foo@59
        semicolon: ;
        declaredFragment: <null>
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: const
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          variables
            VariableDeclaration
              name: bar
              equals: =
              initializer: IntegerLiteral
                literal: 1
                staticType: int
              declaredFragment: <testLibraryFragment> bar@87
        semicolon: ;
        declaredFragment: <null>
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(int this.a) {
  final int a;
}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
        declaredFragment: <testLibraryFragment> a@17
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@class::A::@field::a
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
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
              declaredFragment: <testLibraryFragment> a@34
        semicolon: ;
        declaredFragment: <null>
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_hasTypeParameters_named() async {
    await assertNoErrorsInCode(r'''
class A<T>.named(T t) {}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@8
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
        declaredFragment: <testLibraryFragment> t@19
          element: isPublic
            type: T
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> named@11
      element: <testLibrary>::@class::A::@constructor::named
        type: A<T> Function(T)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_hasTypeParameters_unnamed() async {
    await assertNoErrorsInCode(r'''
class A<T>(T t) {}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@8
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
        declaredFragment: <testLibraryFragment> t@13
          element: isPublic
            type: T
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A<T> Function(T)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_noTypeParameters_named() async {
    await assertNoErrorsInCode(r'''
class A.named(int a) {}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
        declaredFragment: <testLibraryFragment> a@18
          element: isPublic
            type: int
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> named@8
      element: <testLibrary>::@class::A::@constructor::named
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_noTypeParameters_unnamed() async {
    await assertNoErrorsInCode(r'''
class A(int a) {}
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
        declaredFragment: <testLibraryFragment> a@12
          element: isPublic
            type: int
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructor_scopes() async {
    await assertNoErrorsInCode(r'''
const foo = 0;
class A<@foo T>([@foo int x = foo]) {
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
        declaredFragment: <testLibraryFragment> T@28
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
              element: <testLibrary>::@class::A::@getter::foo
              staticType: null
            element: <testLibrary>::@class::A::@getter::foo
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: x
        declaredFragment: <testLibraryFragment> x@41
          element: isPublic
            type: int
      separator: =
      defaultValue: SimpleIdentifier
        token: foo
        element: <testLibrary>::@class::A::@getter::foo
        staticType: int
      declaredFragment: <testLibraryFragment> x@41
        element: isPublic
          type: int
    rightDelimiter: ]
    rightParenthesis: )
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::A::@constructor::new
      type: A<T> Function([int])
''');
  }

  test_primaryConstructor_superFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(final int a);
class B(super.a) extends A;
''');

    var node = findNode.classDeclaration('class B');
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: B
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SuperFormalParameter
        superKeyword: super
        period: .
        name: a
        declaredFragment: <testLibraryFragment> a@36
          element: hasImplicitType isFinal isPublic
            type: int
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::B::@constructor::new
        type: B Function(int)
  extendsClause: ExtendsClause
    extendsKeyword: extends
    superclass: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
  body: EmptyClassBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> B@28
''');
  }

  test_primaryConstructor_typeParameters() async {
    await assertNoErrorsInCode(r'''
class D<T extends U, U extends num>(T t, U u);
''');

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: D
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
          declaredFragment: <testLibraryFragment> T@8
            defaultType: num
        TypeParameter
          name: U
          extendsKeyword: extends
          bound: NamedType
            name: num
            element: dart:core::@class::num
            type: num
          declaredFragment: <testLibraryFragment> U@21
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
        declaredFragment: <testLibraryFragment> t@38
          element: isPublic
            type: T
      parameter: SimpleFormalParameter
        type: NamedType
          name: U
          element: #E0 U
          type: U
        name: u
        declaredFragment: <testLibraryFragment> u@43
          element: isPublic
            type: U
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::D::@constructor::new
        type: D<T, U> Function(T, U)
  body: EmptyClassBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> D@6
''');
  }

  test_primaryConstructorBody_duplicate() async {
    await assertErrorsInCode(
      r'''
class A(bool x, bool y) {
  this : assert(x) {
    y;
  }
  this : assert(!x) {
    !y;
  }
}
''',
      [error(diag.multiplePrimaryConstructorBodyDeclarations, 60, 4)],
    );

    var node = findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
        declaredFragment: <testLibraryFragment> x@13
          element: isPublic
            type: bool
      parameter: SimpleFormalParameter
        type: NamedType
          name: bool
          element: dart:core::@class::bool
          type: bool
        name: y
        declaredFragment: <testLibraryFragment> y@21
          element: isPublic
            type: bool
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@class::A::@constructor::new
        type: A Function(bool, bool)
  body: BlockClassBody
    leftBracket: {
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
              element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
              staticType: bool
            rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: y
                  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::y
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
                element: <testLibrary>::@class::A::@constructor::new::@formalParameter::x
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
                    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::y
                    staticType: bool
                  element: <null>
                  staticType: bool
                semicolon: ;
            rightBracket: }
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
  }

  test_primaryConstructorBody_metadata() async {
    await assertNoErrorsInCode(r'''
class A() {
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
class A {
  @deprecated
  this;
}
''',
      [error(diag.primaryConstructorBodyWithoutDeclaration, 26, 4)],
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
class A {
  this : assert(x) {
    y;
  }
}
''',
      [
        error(diag.primaryConstructorBodyWithoutDeclaration, 12, 4),
        error(diag.undefinedIdentifier, 26, 1),
        error(diag.undefinedIdentifier, 35, 1),
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

  test_primaryConstructorBody_primaryInitializerScope_declaringFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(final bool a) {
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
        element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_declaringFormalParameter_shadowedClassName() async {
    await assertNoErrorsInCode(r'''
class A(final int A()) {
  this : assert(A() > 0);
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::A
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(this.a) {
  final bool a;
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
        element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_fieldFormalParameter_shadowedClassName() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int _);
}

class B(this.A) {
  final int Function() A;
  this : assert(A() > 0);
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::B::@constructor::new::@formalParameter::A
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_simpleFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(bool a) {
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
        element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_superFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(final bool a);
class B(super.a) extends A {
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
        element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_superFormalParameter_shadowedClassName() async {
    await assertNoErrorsInCode(r'''
class A(int Function() A);
class B(super.A) extends A {
  this : assert(A() > 0);
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::B::@constructor::new::@formalParameter::A
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_primaryConstructorBody_primaryParameterScope_declaringFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(final int a) {
  this {
    a;
    foo;
  }
  void foo() {}
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: <testLibrary>::@class::A::@getter::a
            staticType: int
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: foo
            element: <testLibrary>::@class::A::@method::foo
            staticType: void Function()
          semicolon: ;
      rightBracket: }
''');
  }

  test_primaryConstructorBody_primaryParameterScope_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(this.a) {
  final int a;
  this {
    a;
    foo;
  }
  void foo() {}
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: <testLibrary>::@class::A::@getter::a
            staticType: int
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: foo
            element: <testLibrary>::@class::A::@method::foo
            staticType: void Function()
          semicolon: ;
      rightBracket: }
''');
  }

  test_primaryConstructorBody_primaryParameterScope_simpleFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(int a) {
  this {
    a;
    foo;
    (a,) = (0,);
  }
  void foo() {}
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
            staticType: int
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: foo
            element: <testLibrary>::@class::A::@method::foo
            staticType: void Function()
          semicolon: ;
        ExpressionStatement
          expression: PatternAssignment
            pattern: RecordPattern
              leftParenthesis: (
              fields
                PatternField
                  pattern: AssignedVariablePattern
                    name: a
                    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
                    matchedValueType: int
                  element: <null>
              rightParenthesis: )
              matchedValueType: (int,)
            equals: =
            expression: RecordLiteral
              leftParenthesis: (
              fields
                IntegerLiteral
                  literal: 0
                  staticType: int
              rightParenthesis: )
              staticType: (int,)
            patternTypeSchema: (int,)
            staticType: (int,)
          semicolon: ;
      rightBracket: }
''');
  }

  test_primaryConstructorBody_primaryParameterScope_superFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A(final int a);
class B(super.a) extends A {
  this {
    a;
    foo;
  }
  void foo() {}
}
''');

    var node = findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: <testLibrary>::@class::A::@getter::a
            staticType: int
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: foo
            element: <testLibrary>::@class::B::@method::foo
            staticType: void Function()
          semicolon: ;
      rightBracket: }
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance() async {
    await assertNoErrorsInCode(r'''
class A(int foo) {
  var bar = foo;
}
''');

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: bar
        equals: =
        initializer: SimpleIdentifier
          token: foo
          element: <testLibrary>::@class::A::@constructor::new::@formalParameter::foo
          staticType: int
        declaredFragment: <testLibraryFragment> bar@25
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance_declaringFormal() async {
    await assertNoErrorsInCode(r'''
class A(final int foo) {
  var bar = foo;
}
''');

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: bar
        equals: =
        initializer: SimpleIdentifier
          token: foo
          element: <testLibrary>::@class::A::@constructor::new::@formalParameter::foo
          staticType: int
        declaredFragment: <testLibraryFragment> bar@31
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_primaryInitializerScope_fieldInitializer_instance_late() async {
    await assertErrorsInCode(
      r'''
class A(int foo) {
  late var bar = foo;
}
''',
      [error(diag.undefinedIdentifier, 36, 3)],
    );

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    keyword: var
    variables
      VariableDeclaration
        name: bar
        equals: =
        initializer: SimpleIdentifier
          token: foo
          element: <null>
          staticType: InvalidType
        declaredFragment: <testLibraryFragment> bar@30
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_primaryInitializerScope_fieldInitializer_static() async {
    await assertErrorsInCode(
      r'''
class A(int foo) {
  static var bar = foo;
}
''',
      [error(diag.undefinedIdentifier, 38, 3)],
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
        declaredFragment: <testLibraryFragment> bar@32
  semicolon: ;
  declaredFragment: <null>
''');
  }
}

/// Coding for formal parameters of super constructor:
/// - optionalPositional = p
/// - requiredPositional = P
/// - optionalNamed = nx
/// - requiredNamed = Nx
@reflectiveTest
class ClassDeclarationResolutionTest_constructor_super
    extends PubPackageResolutionTest {
  test_named_N1_superFormals_N1_hasSuper_N1() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named({required int n1});
}
class B extends A {
  B.named({required super.n1}) : super.named(n1: 0);
}
''',
      [error(diag.duplicateNamedArgument, 107, 2)],
    );
  }

  test_named_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named(int p1, {required int n1, int? n2});
}
class B extends A {
  B.named(super.p1) : super.named(n2: 1);
}
''',
      [error(diag.missingRequiredArgument, 101, 18)],
    );
  }

  test_named_P_n1_superFormals_P_hasSuper_n1() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named(int p1, {int? n1});
}
class B extends A {
  B.named(super.p1) : super.named(n1: 1);
}
''');
  }

  test_named_P_N1_superFormals_P_N1_hasSuper_none() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named(int p1, {required int n1});
}
class B extends A {
  B.named(super.p1, {required super.n1}) : super.named();
}
''');
  }

  test_named_PP_superFormals_P_hasSuper_P() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named(int p1, int p2);
}
class B extends A {
  B.named(super.p1) : super.named(0);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 75, 2)],
    );
  }

  test_unnamed_n1_n2_n3_superFormals_n1_n2_hasSuper_n3() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1, int? n2, int? n3});
}
class B extends A {
  B({super.n1, super.n2}) : super(n3: 3);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1, required int n2});
}
class B extends A {
  B({required super.n1});
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 75, 1)],
    );
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_N2() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1, required int n2});
}
class B extends A {
  B({required super.n1}) : super(n2: 2);
}
''');
  }

  test_unnamed_n1_n2_superFormals_n1_hasSuper_n2() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1, int? n2});
}
class B extends A {
  B({super.n1}) : super(n2: 2);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1, required int n2});
}
class B extends A {
  B({required super.n1}) : super();
}
''',
      [error(diag.missingRequiredArgument, 100, 7)],
    );
  }

  test_unnamed_n1_N2_superFormals_n1_N2_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1, required int n2});
}
class B extends A {
  B({super.n1, required super.n2});
}
''');
  }

  test_unnamed_N1_superFormals_n1_default_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1});
}
class B extends A {
  B({super.n1 = 1});
}
''');
  }

  test_unnamed_N1_superFormals_N1_hasConstructor_N2_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n2});
}
class B extends A {
  B({required super.n1});
}
''',
      [
        error(diag.implicitSuperInitializerMissingArguments, 58, 1),
        error(diag.superFormalParameterWithoutAssociatedNamed, 76, 2),
      ],
    );
  }

  test_unnamed_N1_superFormals_N1_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1});
}
class B extends A {
  B({required super.n1});
}
''');
  }

  test_unnamed_n1_superFormals_n1_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1});
}
class B extends A {
  B({super.n1});
}
''');
  }

  test_unnamed_N1_superFormals_N1_hasSuper_N1() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1});
}
class B extends A {
  B({required super.n1}) : super(n1: 0);
}
''',
      [error(diag.duplicateNamedArgument, 89, 2)],
    );
  }

  test_unnamed_n1_superFormals_n1_hasSuper_n1() async {
    await assertErrorsInCode(
      r'''
class A {
  A({int? n1});
}
class B extends A {
  B({super.n1}) : super(n1: 1);
}
''',
      [error(diag.duplicateNamedArgument, 72, 2)],
    );
  }

  test_unnamed_N1_superFormals_none_hasSuper_N1() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1});
}
class B extends A {
  B() : super(n1: 1);
}
''');
  }

  test_unnamed_n1_superFormals_none_hasSuper_n1() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1});
}
class B extends A {
  B() : super(n1: 1);
}
''');
  }

  test_unnamed_N1_superFormals_P_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1});
}
class B extends A {
  B(super.n1);
}
''',
      [
        error(diag.implicitSuperInitializerMissingArguments, 58, 1),
        error(diag.superFormalParameterWithoutAssociatedPositional, 66, 2),
      ],
    );
  }

  test_unnamed_n1_superFormals_P_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A({int? n1});
}
class B extends A {
  B(super.p1);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 58, 2)],
    );
  }

  test_unnamed_P_n1_n2_superFormals_P_hasSuper_n1_n2() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B extends A {
  B(super.p1) : super(n1: 1, n2: 2);
}
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B extends A {
  B(super.p1) : super(n2: 1);
}
''',
      [error(diag.missingRequiredArgument, 89, 12)],
    );
  }

  test_unnamed_P_n1_n2_superFormals_P_n1_hasSuper_n2() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B extends A {
  B(super.p1, {super.n1}) : super(n2: 2);
}
''');
  }

  test_unnamed_P_n1_N2_superFormals_P_n1_N2_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1, required int n2});
}
class B extends A {
  B(super.p1, {super.n1, required super.n2});
}
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_n2_hasSuper_N1() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B extends A {
  B(super.p1, {super.n2}) : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_N1_hasSuper_P() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {required int n1});
}
class B extends A {
  B({required super.n1}) : super(0);
}
''');
  }

  test_unnamed_P_n1_superFormals_n1_hasSuper_P() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1});
}
class B extends A {
  B({super.n1}) : super(0);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, {required int n1});
}
class B extends A {
  B(super.p1);
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 66, 1)],
    );
  }

  test_unnamed_P_n1_superFormals_P_hasSuper_n1() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1});
}
class B extends A {
  B(super.p1) : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_N1_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {required int n1});
}
class B extends A {
  B(super.p1, {required super.n1});
}
''');
  }

  test_unnamed_P_n1_superFormals_P_n1_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1});
}
class B extends A {
  B(super.p1, {super.n1});
}
''');
  }

  test_unnamed_P_superFormals_N1_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B extends A {
  B({required super.p1});
}
''',
      [
        error(diag.implicitSuperInitializerMissingArguments, 47, 1),
        error(diag.superFormalParameterWithoutAssociatedNamed, 65, 2),
      ],
    );
  }

  test_unnamed_p_superFormals_n1_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A([int? p1]);
}
class B extends A {
  B({super.n1});
}
''',
      [error(diag.superFormalParameterWithoutAssociatedNamed, 59, 2)],
    );
  }

  test_unnamed_P_superFormals_none_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B extends A {
  B();
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 47, 1)],
    );
  }

  test_unnamed_P_superFormals_none_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B extends A {
  B() : super();
}
''',
      [error(diag.notEnoughPositionalArgumentsNameSingular, 59, 1)],
    );
  }

  test_unnamed_P_superFormals_none_hasSuper_p() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1);
}
class B extends A {
  B() : super(0);
}
''');
  }

  test_unnamed_p_superFormals_none_hasSuper_p() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B() : super(1);
}
''');
  }

  test_unnamed_P_superFormals_none_noConstructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B extends A {}
''',
      [error(diag.noDefaultSuperConstructorImplicit, 31, 1)],
    );
  }

  test_unnamed_P_superFormals_p_default_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1);
}
class B extends A {
  B([super.p1 = 1]);
}
''');
  }

  test_unnamed_p_superFormals_p_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B([super.p1]);
}
''');
  }

  test_unnamed_P_superFormals_P_hasConstructor_noSuper_wrongType() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B extends A {
  B(String super.p1);
}
''',
      [error(diag.superFormalParameterTypeIsNotSubtypeOfAssociated, 62, 2)],
    );
  }

  test_unnamed_P_superFormals_P_hasSuper_none() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1);
}
class B extends A {
  B(super.p1) : super();
}
''');
  }

  test_unnamed_P_superFormals_p_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B extends A {
  B([super.p1]) : super();
}
''',
      [error(diag.missingDefaultValueForParameterPositional, 56, 2)],
    );
  }

  test_unnamed_p_superFormals_p_hasSuper_p() async {
    await assertErrorsInCode(
      r'''
class A {
  A([int? p1]);
}
class B extends A {
  B(super.p1) : super(1);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 58, 2)],
    );
  }

  test_unnamed_P_superFormals_PP_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B extends A {
  B(super.p1, super.p2);
}
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 65, 2)],
    );
  }

  test_unnamed_PP_superFormals_P_hasConstructor_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, int p2);
}
class B extends A {
  B(super.p1);
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 55, 1)],
    );
  }

  test_unnamed_PP_superFormals_P_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, int p2);
}
class B extends A {
  B(super.p1) : super();
}
''',
      [error(diag.notEnoughPositionalArgumentsNamePlural, 75, 1)],
    );
  }

  test_unnamed_PP_superFormals_P_hasSuper_P() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, int p2);
}
class B extends A {
  B(super.p1) : super(0);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 63, 2)],
    );
  }

  test_unnamed_Pp_superFormals_Pp_hasConstructor_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, [int? p2]);
}
class B extends A {
  B(super.p1, [super.p2]);
}
''');
  }
}

/// Coding for formal parameters of super constructor:
/// - optionalPositional = p
/// - requiredPositional = P
/// - optionalNamed = nx
/// - requiredNamed = Nx
@reflectiveTest
class ClassDeclarationResolutionTest_primaryConstructor_super
    extends PubPackageResolutionTest {
  test_named_N1_superFormals_N1_hasSuper_N1() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named({required int n1});
}
class B.named({required super.n1}) extends A {
  this : super.named(n1: 0);
}
''',
      [error(diag.duplicateNamedArgument, 110, 2)],
    );
  }

  test_named_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named(int p1, {required int n1, int? n2});
}
class B.named(super.p1) extends A {
  this : super.named(n2: 1);
}
''',
      [error(diag.missingRequiredArgument, 104, 18)],
    );
  }

  test_named_P_n1_superFormals_P_hasSuper_n1() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named(int p1, {int? n1});
}
class B.named(super.p1) extends A {
  this : super.named(n1: 1);
}
''');
  }

  test_named_P_N1_superFormals_P_N1_hasSuper_none() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named(int p1, {required int n1});
}
class B.named(super.p1, {required super.n1}) extends A {
  this : super.named();
}
''');
  }

  test_named_PP_superFormals_P_hasSuper_P() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named(int p1, int p2);
}
class B.named(super.p1) extends A {
  this : super.named(0);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 59, 2)],
    );
  }

  test_unnamed_n1_n2_n3_superFormals_n1_n2_hasSuper_n3() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1, int? n2, int? n3});
}
class B({super.n1, super.n2}) extends A {
  this : super(n3: 3);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasBody_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A {
  this;
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 96, 4)],
    );
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_N2() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A {
  this : super(n2: 2);
}
''');
  }

  test_unnamed_n1_n2_superFormals_n1_hasSuper_n2() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1, int? n2});
}
class B({super.n1}) extends A {
  this : super(n2: 2);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A {
  this : super();
}
''',
      [error(diag.missingRequiredArgument, 103, 7)],
    );
  }

  test_unnamed_n1_N2_superFormals_n1_N2_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1, required int n2});
}
class B({super.n1, required super.n2}) extends A;
''');
  }

  test_unnamed_N1_N2_superFormals_N1_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 59, 1)],
    );
  }

  test_unnamed_N1_superFormals_n1_default_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1});
}
class B({super.n1 = 1}) extends A;
''');
  }

  test_unnamed_N1_superFormals_N1_hasBody_noSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1});
}
class B({required super.n1}) extends A {
  this;
}
''');
  }

  test_unnamed_N1_superFormals_N1_hasSuper_N1() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1});
}
class B({required super.n1}) extends A {
  this : super(n1: 0);
}
''',
      [error(diag.duplicateNamedArgument, 92, 2)],
    );
  }

  test_unnamed_n1_superFormals_n1_hasSuper_n1() async {
    await assertErrorsInCode(
      r'''
class A {
  A({int? n1});
}
class B({super.n1}) extends A {
  this : super(n1: 1);
}
''',
      [error(diag.duplicateNamedArgument, 75, 2)],
    );
  }

  test_unnamed_N1_superFormals_N1_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1});
}
class B({required super.n1}) extends A;
''');
  }

  test_unnamed_n1_superFormals_n1_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1});
}
class B({super.n1}) extends A;
''');
  }

  test_unnamed_N1_superFormals_N1_noBody_N2_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n2});
}
class B({required super.n1}) extends A;
''',
      [
        error(diag.implicitSuperInitializerMissingArguments, 42, 1),
        error(diag.superFormalParameterWithoutAssociatedNamed, 60, 2),
      ],
    );
  }

  test_unnamed_N1_superFormals_none_hasSuper_N1() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int n1});
}
class B() extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_n1_superFormals_none_hasSuper_n1() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? n1});
}
class B() extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_N1_superFormals_P_hasBody_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1});
}
class B(super.n1) extends A {
  this;
}
''',
      [
        error(diag.superFormalParameterWithoutAssociatedPositional, 50, 2),
        error(diag.implicitSuperInitializerMissingArguments, 68, 4),
      ],
    );
  }

  test_unnamed_N1_superFormals_P_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int n1});
}
class B(super.n1) extends A;
''',
      [
        error(diag.implicitSuperInitializerMissingArguments, 42, 1),
        error(diag.superFormalParameterWithoutAssociatedPositional, 50, 2),
      ],
    );
  }

  test_unnamed_n1_superFormals_P_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A({int? n1});
}
class B(super.p1) extends A;
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 42, 2)],
    );
  }

  test_unnamed_P_n1_n2_superFormals_P_hasSuper_n1_n2() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B(super.p1) extends A {
  this : super(n1: 1, n2: 2);
}
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B(super.p1) extends A {
  this : super(n2: 1);
}
''',
      [error(diag.missingRequiredArgument, 92, 12)],
    );
  }

  test_unnamed_P_n1_n2_superFormals_P_n1_hasSuper_n2() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B(super.p1, {super.n1}) extends A {
  this : super(n2: 2);
}
''');
  }

  test_unnamed_P_n1_N2_superFormals_P_n1_N2_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1, required int n2});
}
class B(super.p1, {super.n1, required super.n2}) extends A;
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_n2_hasSuper_N1() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B(super.p1, {super.n2}) extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_N1_hasSuper_P() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {required int n1});
}
class B({required super.n1}) extends A {
  this : super(0);
}
''');
  }

  test_unnamed_P_n1_superFormals_n1_hasSuper_P() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1});
}
class B({super.n1}) extends A {
  this : super(0);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_hasBody_noSuper() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, {required int n1});
}
class B(super.p1) extends A {
  this;
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 76, 4)],
    );
  }

  test_unnamed_P_n1_superFormals_P_hasSuper_n1() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1});
}
class B(super.p1) extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_N1_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {required int n1});
}
class B(super.p1, {required super.n1}) extends A;
''');
  }

  test_unnamed_P_n1_superFormals_P_n1_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, {int? n1});
}
class B(super.p1, {super.n1}) extends A;
''');
  }

  test_unnamed_P_N1_superFormals_P_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, {required int n1});
}
class B(super.p1) extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 50, 1)],
    );
  }

  test_unnamed_P_superFormals_N1_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B({required super.p1}) extends A;
''',
      [
        error(diag.implicitSuperInitializerMissingArguments, 31, 1),
        error(diag.superFormalParameterWithoutAssociatedNamed, 49, 2),
      ],
    );
  }

  test_unnamed_p_superFormals_n1_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A([int? p1]);
}
class B({super.n1}) extends A;
''',
      [error(diag.superFormalParameterWithoutAssociatedNamed, 43, 2)],
    );
  }

  test_unnamed_P_superFormals_none_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B() extends A {
  this : super();
}
''',
      [error(diag.notEnoughPositionalArgumentsNameSingular, 62, 1)],
    );
  }

  test_unnamed_P_superFormals_none_hasSuper_p() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1);
}
class B() extends A {
  this : super(0);
}
''');
  }

  test_unnamed_p_superFormals_none_hasSuper_p() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? p1]);
}
class B() extends A {
  this : super(1);
}
''');
  }

  test_unnamed_P_superFormals_none_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B() extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 31, 1)],
    );
  }

  test_unnamed_P_superFormals_none_noConstructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B() extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 31, 1)],
    );
  }

  test_unnamed_P_superFormals_p_default_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1);
}
class B([super.p1 = 1]) extends A;
''');
  }

  test_unnamed_P_superFormals_P_hasSuper_none() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1);
}
class B(super.p1) extends A {
  this : super();
}
''');
  }

  test_unnamed_P_superFormals_p_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B([super.p1]) extends A {
  this : super();
}
''',
      [error(diag.missingDefaultValueForParameterPositional, 40, 2)],
    );
  }

  test_unnamed_p_superFormals_p_hasSuper_p() async {
    await assertErrorsInCode(
      r'''
class A {
  A([int? p1]);
}
class B(super.p1) extends A {
  this : super(1);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 42, 2)],
    );
  }

  test_unnamed_p_superFormals_p_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? p1]);
}
class B([super.p1]) extends A;
''');
  }

  test_unnamed_P_superFormals_P_noBody_wrongType() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B(String super.p1) extends A;
''',
      [error(diag.superFormalParameterTypeIsNotSubtypeOfAssociated, 46, 2)],
    );
  }

  test_unnamed_P_superFormals_PP_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1);
}
class B(super.p1, super.p2) extends A;
''',
      [error(diag.superFormalParameterWithoutAssociatedPositional, 49, 2)],
    );
  }

  test_unnamed_PP_superFormals_P_hasSuper_none() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, int p2);
}
class B(super.p1) extends A {
  this : super();
}
''',
      [error(diag.notEnoughPositionalArgumentsNamePlural, 78, 1)],
    );
  }

  test_unnamed_PP_superFormals_P_hasSuper_P() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, int p2);
}
class B(super.p1) extends A {
  this : super(0);
}
''',
      [error(diag.positionalSuperFormalParameterWithPositionalArgument, 47, 2)],
    );
  }

  test_unnamed_PP_superFormals_P_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p1, int p2);
}
class B(super.p1) extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 39, 1)],
    );
  }

  test_unnamed_Pp_superFormals_Pp_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p1, [int? p2]);
}
class B(super.p1, [super.p2]) extends A;
''');
  }
}
