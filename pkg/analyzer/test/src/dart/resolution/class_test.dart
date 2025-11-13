// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationResolutionTest);
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

    useDeclaringConstructorsAst = true;
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

    {
      useDeclaringConstructorsAst = false;
      await assertNoErrorsInCode(code);

      var node = findNode.singleClassDeclaration;
      assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  name: A
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
  leftBracket: {
  rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
    }
  }

  test_nameWithTypeParameters_noTypeParameters() async {
    var code = r'''
class A {}
''';

    useDeclaringConstructorsAst = true;
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

    {
      useDeclaringConstructorsAst = false;
      await assertNoErrorsInCode(code);

      var node = findNode.singleClassDeclaration;
      assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
  declaredFragment: <testLibraryFragment> A@6
''');
    }
  }

  test_primaryConstructor_declaringFormalParameter_default_namedOptional_final() async {
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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
    useDeclaringConstructorsAst = true;
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

  test_primaryConstructor_superFormalParameter() async {
    useDeclaringConstructorsAst = true;
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
}
