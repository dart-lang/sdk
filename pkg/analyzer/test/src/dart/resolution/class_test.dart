// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    assertElementTypes(result.findElement.class_('X1').allSupertypes, [
      'Object',
      'A',
    ]);
    assertElementTypes(result.findElement.class_('X2').allSupertypes, [
      'Object',
      'B',
    ]);
    assertElementTypes(result.findElement.class_('X3').allSupertypes, [
      'Object',
      'A',
      'B',
    ]);
    assertElementTypes(result.findElement.class_('X4').allSupertypes, [
      'Object',
      'A',
      'B',
      'C',
    ]);
    assertElementTypes(result.findElement.class_('X5').allSupertypes, [
      'Object',
      'A',
      'B',
      'C',
      'D',
      'E',
    ]);
  }

  test_element_allSupertypes_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
class B<T, U> {}
class C<T> extends B<int, T> {}

class X1 extends A<String> {}
class X2 extends B<String, List<int>> {}
class X3 extends C<double> {}
''');

    assertElementTypes(result.findElement.class_('X1').allSupertypes, [
      'Object',
      'A<String>',
    ]);
    assertElementTypes(result.findElement.class_('X2').allSupertypes, [
      'Object',
      'B<String, List<int>>',
    ]);
    assertElementTypes(result.findElement.class_('X3').allSupertypes, [
      'Object',
      'B<int, double>',
      'C<double>',
    ]);
  }

  test_element_allSupertypes_recursive() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: C, B, A.
class B extends C {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: C, B, A.
class C extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: C, B, A.

class X extends A {}
''');

    assertElementTypes(result.findElement.class_('X').allSupertypes, [
      'A',
      'Object',
    ]);
  }

  test_element_typeFunction_extends() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A extends Function {}
//              ^^^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Function' can't be extended outside of its library because it's a final class.
''');
    var a = result.findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_element_typeFunction_extends_language219() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class A extends Function {}
//              ^^^^^^^^
// [diag.deprecatedExtendsFunction] Extending 'Function' is deprecated.
''');
    var a = result.findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_element_typeFunction_with() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {}
mixin B {}
class C extends Object with A, Function, B {}
//                             ^^^^^^^^
// [diag.classUsedAsMixin] The class 'Function' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');

    assertElementTypes(result.findElement.class_('C').mixins, ['A', 'B']);
  }

  test_element_typeFunction_with_language219() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
mixin A {}
mixin B {}
class C extends Object with A, Function, B {}
//                             ^^^^^^^^
// [diag.deprecatedMixinFunction] Mixing in 'Function' is deprecated.
''');

    assertElementTypes(result.findElement.class_('C').mixins, ['A', 'B']);
  }

  test_field_static_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T? foo;
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');

    var node = result.findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  staticKeyword: static
  fields: VariableDeclarationList
    type: NamedType
      name: T
      question: ?
      element: #E0 T
      type: InvalidType
    variables
      VariableDeclaration
        name: foo
        declaredFragment: <testLibraryFragment> foo@25
  semicolon: ;
  declaredFragment: <null>
''');
  }

  test_issue32815() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> extends B<T> {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B<T> extends A<T> {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
class C<T> extends B<T> implements I<T> {}

abstract class I<T> {}

main() {
  Iterable<I<int>> x = [new C()];
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');
  }

  test_method_static_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T? foo() {}
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}
''');

    var node = result.findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: T
    question: ?
    element: #E0 T
    type: InvalidType
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> foo@25
    element: <testLibrary>::@class::A::@method::foo
      type: InvalidType Function()
''');
  }

  test_nameWithTypeParameters_hasTypeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T extends int> {}
''');

    var node = result.findNode.singleClassDeclaration;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
''');

    var node = result.findNode.singleClassDeclaration;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A({final int a = 0});
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A({required final int a});
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        requiredKeyword: required
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int a(String x));
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        functionTypedSuffix: FunctionTypedFormalParameterSuffix
          formalParameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int a) {}
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(var int a) {}
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: var
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final String a, final bool b) {
  static const int foo = 0;
  static const int bar = 1;
}
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        type: NamedType
          name: String
          element: dart:core::@class::String
          type: String
        name: a
        declaredFragment: <testLibraryFragment> a@21
          element: isFinal isPublic
            type: String
            field: <testLibrary>::@class::A::@field::a
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int this.a) {
  final int a;
}
''');

    var node = result.findNode.singleClassDeclaration;
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

  test_primaryConstructor_formalParameters_bodyScope_metadata() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;
class A(@foo int x) {
  static const foo = 1;
}
''');

    var node = result.findNode.singlePrimaryConstructorDeclaration;
    assertResolvedNodeText(node, r'''
PrimaryConstructorDeclaration
  typeName: A
  formalParameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
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
      declaredFragment: <testLibraryFragment> x@32
        element: isPublic
          type: int
    rightParenthesis: )
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::A::@constructor::new
      type: A Function(int)
''');
  }

  test_primaryConstructor_formalParameters_bodyScope_type() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
//      ^^^
// [diag.notAType] int isn't a type.
  static const String int = '';
}
''');

    var node = result.findNode.singlePrimaryConstructorDeclaration;
    assertResolvedNodeText(node, r'''
PrimaryConstructorDeclaration
  typeName: A
  formalParameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
        element: <testLibrary>::@class::A::@getter::int
        type: InvalidType
      name: x
      declaredFragment: <testLibraryFragment> x@12
        element: isPublic
          type: InvalidType
    rightParenthesis: )
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::A::@constructor::new
      type: A Function(InvalidType)
''');
  }

  test_primaryConstructor_hasTypeParameters_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T>.named(T t) {}
''');

    var node = result.findNode.singleClassDeclaration;
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
      parameter: RegularFormalParameter
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T>(T t) {}
''');

    var node = result.findNode.singleClassDeclaration;
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
      parameter: RegularFormalParameter
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A.named(int a) {}
''');

    var node = result.findNode.singleClassDeclaration;
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
      parameter: RegularFormalParameter
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int a) {}
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;
class A<@foo T>([@foo int x = foo]) {
  static const foo = 1;
}
''');

    var node = result.findNode.singlePrimaryConstructorDeclaration;
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
    parameter: RegularFormalParameter
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
      defaultClause: FormalParameterDefaultClause
        separator: =
        value: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int a);
class B(super.a) extends A;
''');

    var node = result.findNode.classDeclaration('class B');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class D<T extends U, U extends num>(T t, U u);
''');

    var node = result.findNode.singleClassDeclaration;
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
      parameter: RegularFormalParameter
        type: NamedType
          name: T
          element: #E1 T
          type: T
        name: t
        declaredFragment: <testLibraryFragment> t@38
          element: isPublic
            type: T
      parameter: RegularFormalParameter
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(bool x, bool y) {
  this : assert(x) {
    y;
  }
  this : assert(!x) {
//^^^^
// [diag.multiplePrimaryConstructorBodyDeclarations] Only one primary constructor body declaration is allowed.
    !y;
  }
}
''');

    var node = result.findNode.singleClassDeclaration;
    assertResolvedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: bool
          element: dart:core::@class::bool
          type: bool
        name: x
        declaredFragment: <testLibraryFragment> x@13
          element: isPublic
            type: bool
      parameter: RegularFormalParameter
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A() {
  @deprecated
  this;
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  @deprecated
  this;
//^^^^
// [diag.primaryConstructorBodyWithoutDeclaration] A primary constructor body requires a primary constructor declaration.
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  this : assert(x) {
//^^^^
// [diag.primaryConstructorBodyWithoutDeclaration] A primary constructor body requires a primary constructor declaration.
//              ^
// [diag.undefinedIdentifier] Undefined name 'x'.
    y;
//  ^
// [diag.undefinedIdentifier] Undefined name 'y'.
  }
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final bool a) {
  this : assert(a);
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int A()) {
  this : assert(A() > 0);
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(this.a) {
  final bool a;
  this : assert(a);
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int _);
}

class B(this.A) {
  final int Function() A;
  this : assert(A() > 0);
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(bool a) {
  this : assert(a);
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final bool a);
class B(super.a) extends A {
  this : assert(a);
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int Function() A);
class B(super.A) extends A {
  this : assert(A() > 0);
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int a) {
  this {
    a;
    foo;
  }
  void foo() {}
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(this.a) {
  final int a;
  this {
    a;
    foo;
  }
  void foo() {}
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int a) {
  this {
    a;
    foo;
    (a,) = (0,);
  }
  void foo() {}
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int a);
class B(super.a) extends A {
  this {
    a;
    foo;
  }
  void foo() {}
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int foo) {
  var bar = foo;
}
''');

    var node = result.findNode.singleFieldDeclaration;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(final int foo) {
  var bar = foo;
}
''');

    var node = result.findNode.singleFieldDeclaration;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int foo) {
  late var bar = foo;
//               ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleFieldDeclaration;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int foo) {
  static var bar = foo;
//                 ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleFieldDeclaration;
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

  test_primaryInitializerScope_fieldTypeAnnotation_shadowedClassName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A(int A) {
  A? field;
}
''');

    var node = result.findNode.namedType('A? field');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  question: ?
  element: <testLibrary>::@class::A
  type: A?
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named({required int n1});
}
class B extends A {
  B.named({required super.n1}) : super.named(n1: 0);
//                                           ^^
// [diag.duplicateNamedArgument] The argument for the named parameter 'n1' was already specified.
}
''');
  }

  test_named_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, {required int n1, int? n2});
}
class B extends A {
  B.named(super.p1) : super.named(n2: 1);
//                    ^^^^^^^^^^^^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'n1' is required, but there's no corresponding argument.
}
''');
  }

  test_named_P_n1_superFormals_P_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, {int? n1});
}
class B extends A {
  B.named(super.p1) : super.named(n1: 1);
}
''');
  }

  test_named_P_N1_superFormals_P_N1_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, {required int n1});
}
class B extends A {
  B.named(super.p1, {required super.n1}) : super.named();
}
''');
  }

  test_named_PP_superFormals_P_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, int p2);
}
class B extends A {
  B.named(super.p1) : super.named(0);
//              ^^
// [diag.positionalSuperFormalParameterWithPositionalArgument] Positional super parameters can't be used when the super constructor invocation has a positional argument.
}
''');
  }

  test_unnamed_n1_n2_n3_superFormals_n1_n2_hasSuper_n3() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1, int? n2, int? n3});
}
class B extends A {
  B({super.n1, super.n2}) : super(n3: 3);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1, required int n2});
}
class B extends A {
  B({required super.n1});
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_N2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1, required int n2});
}
class B extends A {
  B({required super.n1}) : super(n2: 2);
}
''');
  }

  test_unnamed_n1_n2_superFormals_n1_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1, int? n2});
}
class B extends A {
  B({super.n1}) : super(n2: 2);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1, required int n2});
}
class B extends A {
  B({required super.n1}) : super();
//                         ^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'n2' is required, but there's no corresponding argument.
}
''');
  }

  test_unnamed_n1_N2_superFormals_n1_N2_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1, required int n2});
}
class B extends A {
  B({super.n1, required super.n2});
}
''');
  }

  test_unnamed_N1_superFormals_n1_default_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B extends A {
  B({super.n1 = 1});
}
''');
  }

  test_unnamed_N1_superFormals_N1_hasConstructor_N2_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n2});
}
class B extends A {
  B({required super.n1});
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
//                  ^^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
}
''');
  }

  test_unnamed_N1_superFormals_N1_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B extends A {
  B({required super.n1});
}
''');
  }

  test_unnamed_n1_superFormals_n1_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B extends A {
  B({super.n1});
}
''');
  }

  test_unnamed_N1_superFormals_N1_hasSuper_N1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B extends A {
  B({required super.n1}) : super(n1: 0);
//                               ^^
// [diag.duplicateNamedArgument] The argument for the named parameter 'n1' was already specified.
}
''');
  }

  test_unnamed_n1_superFormals_n1_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B extends A {
  B({super.n1}) : super(n1: 1);
//                      ^^
// [diag.duplicateNamedArgument] The argument for the named parameter 'n1' was already specified.
}
''');
  }

  test_unnamed_N1_superFormals_none_hasSuper_N1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B extends A {
  B() : super(n1: 1);
}
''');
  }

  test_unnamed_n1_superFormals_none_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B extends A {
  B() : super(n1: 1);
}
''');
  }

  test_unnamed_N1_superFormals_P_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B extends A {
  B(super.n1);
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
//        ^^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_unnamed_n1_superFormals_P_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B extends A {
  B(super.p1);
//        ^^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_unnamed_P_n1_n2_superFormals_P_hasSuper_n1_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B extends A {
  B(super.p1) : super(n1: 1, n2: 2);
}
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B extends A {
  B(super.p1) : super(n2: 1);
//              ^^^^^^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'n1' is required, but there's no corresponding argument.
}
''');
  }

  test_unnamed_P_n1_n2_superFormals_P_n1_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B extends A {
  B(super.p1, {super.n1}) : super(n2: 2);
}
''');
  }

  test_unnamed_P_n1_N2_superFormals_P_n1_N2_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1, required int n2});
}
class B extends A {
  B(super.p1, {super.n1, required super.n2});
}
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_n2_hasSuper_N1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B extends A {
  B(super.p1, {super.n2}) : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_N1_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1});
}
class B extends A {
  B({required super.n1}) : super(0);
}
''');
  }

  test_unnamed_P_n1_superFormals_n1_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1});
}
class B extends A {
  B({super.n1}) : super(0);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1});
}
class B extends A {
  B(super.p1);
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_unnamed_P_n1_superFormals_P_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1});
}
class B extends A {
  B(super.p1) : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_N1_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1});
}
class B extends A {
  B(super.p1, {required super.n1});
}
''');
  }

  test_unnamed_P_n1_superFormals_P_n1_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1});
}
class B extends A {
  B(super.p1, {super.n1});
}
''');
  }

  test_unnamed_P_superFormals_N1_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B({required super.p1});
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
//                  ^^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
}
''');
  }

  test_unnamed_p_superFormals_n1_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B({super.n1});
//         ^^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
}
''');
  }

  test_unnamed_P_superFormals_none_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B();
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_unnamed_P_superFormals_none_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B() : super();
//            ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
}
''');
  }

  test_unnamed_P_superFormals_none_hasSuper_p() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B() : super(0);
}
''');
  }

  test_unnamed_p_superFormals_none_hasSuper_p() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B() : super(1);
}
''');
  }

  test_unnamed_P_superFormals_none_noConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {}
//    ^
// [diag.noDefaultSuperConstructorImplicit] The superclass 'A' doesn't have a zero argument constructor.
''');
  }

  test_unnamed_P_superFormals_p_default_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B([super.p1 = 1]);
}
''');
  }

  test_unnamed_p_superFormals_p_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B([super.p1]);
}
''');
  }

  test_unnamed_P_superFormals_P_hasConstructor_noSuper_wrongType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B(String super.p1);
//               ^^
// [diag.superFormalParameterTypeIsNotSubtypeOfAssociated] The type 'String' of this parameter isn't a subtype of the type 'int' of the associated super constructor parameter.
}
''');
  }

  test_unnamed_P_superFormals_P_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B(super.p1) : super();
}
''');
  }

  test_unnamed_P_superFormals_p_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B([super.p1]) : super();
//         ^^
// [diag.missingDefaultValueForParameterPositional] The parameter 'p1' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
''');
  }

  test_unnamed_p_superFormals_p_hasSuper_p() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B extends A {
  B(super.p1) : super(1);
//        ^^
// [diag.positionalSuperFormalParameterWithPositionalArgument] Positional super parameters can't be used when the super constructor invocation has a positional argument.
}
''');
  }

  test_unnamed_P_superFormals_PP_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B extends A {
  B(super.p1, super.p2);
//                  ^^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
}
''');
  }

  test_unnamed_PP_superFormals_P_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, int p2);
}
class B extends A {
  B(super.p1);
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_unnamed_PP_superFormals_P_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, int p2);
}
class B extends A {
  B(super.p1) : super();
//                    ^
// [diag.notEnoughPositionalArgumentsNamePlural] 2 positional arguments expected by 'A.new', but 1 found.
}
''');
  }

  test_unnamed_PP_superFormals_P_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, int p2);
}
class B extends A {
  B(super.p1) : super(0);
//        ^^
// [diag.positionalSuperFormalParameterWithPositionalArgument] Positional super parameters can't be used when the super constructor invocation has a positional argument.
}
''');
  }

  test_unnamed_Pp_superFormals_Pp_hasConstructor_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named({required int n1});
}
class B.named({required super.n1}) extends A {
  this : super.named(n1: 0);
//                   ^^
// [diag.duplicateNamedArgument] The argument for the named parameter 'n1' was already specified.
}
''');
  }

  test_named_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, {required int n1, int? n2});
}
class B.named(super.p1) extends A {
  this : super.named(n2: 1);
//       ^^^^^^^^^^^^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'n1' is required, but there's no corresponding argument.
}
''');
  }

  test_named_P_n1_superFormals_P_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, {int? n1});
}
class B.named(super.p1) extends A {
  this : super.named(n1: 1);
}
''');
  }

  test_named_P_N1_superFormals_P_N1_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, {required int n1});
}
class B.named(super.p1, {required super.n1}) extends A {
  this : super.named();
}
''');
  }

  test_named_PP_superFormals_P_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int p1, int p2);
}
class B.named(super.p1) extends A {
//                  ^^
// [diag.positionalSuperFormalParameterWithPositionalArgument] Positional super parameters can't be used when the super constructor invocation has a positional argument.
  this : super.named(0);
}
''');
  }

  test_unnamed_n1_n2_n3_superFormals_n1_n2_hasSuper_n3() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1, int? n2, int? n3});
}
class B({super.n1, super.n2}) extends A {
  this : super(n3: 3);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasBody_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A {
  this;
//^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_N2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A {
  this : super(n2: 2);
}
''');
  }

  test_unnamed_n1_n2_superFormals_n1_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1, int? n2});
}
class B({super.n1}) extends A {
  this : super(n2: 2);
}
''');
  }

  test_unnamed_N1_N2_superFormals_N1_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A {
  this : super();
//       ^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'n2' is required, but there's no corresponding argument.
}
''');
  }

  test_unnamed_n1_N2_superFormals_n1_N2_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1, required int n2});
}
class B({super.n1, required super.n2}) extends A;
''');
  }

  test_unnamed_N1_N2_superFormals_N1_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1, required int n2});
}
class B({required super.n1}) extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_unnamed_N1_superFormals_n1_default_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B({super.n1 = 1}) extends A;
''');
  }

  test_unnamed_N1_superFormals_N1_hasBody_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B({required super.n1}) extends A {
  this;
}
''');
  }

  test_unnamed_N1_superFormals_N1_hasSuper_N1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B({required super.n1}) extends A {
  this : super(n1: 0);
//             ^^
// [diag.duplicateNamedArgument] The argument for the named parameter 'n1' was already specified.
}
''');
  }

  test_unnamed_n1_superFormals_n1_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B({super.n1}) extends A {
  this : super(n1: 1);
//             ^^
// [diag.duplicateNamedArgument] The argument for the named parameter 'n1' was already specified.
}
''');
  }

  test_unnamed_N1_superFormals_N1_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B({required super.n1}) extends A;
''');
  }

  test_unnamed_n1_superFormals_n1_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B({super.n1}) extends A;
''');
  }

  test_unnamed_N1_superFormals_N1_noBody_N2_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n2});
}
class B({required super.n1}) extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
//                      ^^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
''');
  }

  test_unnamed_N1_superFormals_none_hasSuper_N1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B() extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_n1_superFormals_none_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B() extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_N1_superFormals_P_hasBody_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B(super.n1) extends A {
//            ^^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
  this;
//^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_unnamed_N1_superFormals_P_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int n1});
}
class B(super.n1) extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
//            ^^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
''');
  }

  test_unnamed_n1_superFormals_P_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? n1});
}
class B(super.p1) extends A;
//            ^^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
''');
  }

  test_unnamed_P_n1_n2_superFormals_P_hasSuper_n1_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B(super.p1) extends A {
  this : super(n1: 1, n2: 2);
}
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B(super.p1) extends A {
  this : super(n2: 1);
//       ^^^^^^^^^^^^
// [diag.missingRequiredArgument] The named parameter 'n1' is required, but there's no corresponding argument.
}
''');
  }

  test_unnamed_P_n1_n2_superFormals_P_n1_hasSuper_n2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1, int? n2});
}
class B(super.p1, {super.n1}) extends A {
  this : super(n2: 2);
}
''');
  }

  test_unnamed_P_n1_N2_superFormals_P_n1_N2_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1, required int n2});
}
class B(super.p1, {super.n1, required super.n2}) extends A;
''');
  }

  test_unnamed_P_N1_n2_superFormals_P_n2_hasSuper_N1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1, int? n2});
}
class B(super.p1, {super.n2}) extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_N1_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1});
}
class B({required super.n1}) extends A {
  this : super(0);
}
''');
  }

  test_unnamed_P_n1_superFormals_n1_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1});
}
class B({super.n1}) extends A {
  this : super(0);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_hasBody_noSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1});
}
class B(super.p1) extends A {
  this;
//^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_unnamed_P_n1_superFormals_P_hasSuper_n1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1});
}
class B(super.p1) extends A {
  this : super(n1: 1);
}
''');
  }

  test_unnamed_P_N1_superFormals_P_N1_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1});
}
class B(super.p1, {required super.n1}) extends A;
''');
  }

  test_unnamed_P_n1_superFormals_P_n1_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {int? n1});
}
class B(super.p1, {super.n1}) extends A;
''');
  }

  test_unnamed_P_N1_superFormals_P_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, {required int n1});
}
class B(super.p1) extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_unnamed_P_superFormals_N1_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B({required super.p1}) extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
//                      ^^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
''');
  }

  test_unnamed_p_superFormals_n1_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B({super.n1}) extends A;
//             ^^
// [diag.superFormalParameterWithoutAssociatedNamed] No associated named super constructor parameter.
''');
  }

  test_unnamed_P_superFormals_none_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B() extends A {
  this : super();
//             ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
}
''');
  }

  test_unnamed_P_superFormals_none_hasSuper_p() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B() extends A {
  this : super(0);
}
''');
  }

  test_unnamed_p_superFormals_none_hasSuper_p() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B() extends A {
  this : super(1);
}
''');
  }

  test_unnamed_P_superFormals_none_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B() extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_unnamed_P_superFormals_none_noConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B() extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_unnamed_P_superFormals_p_default_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B([super.p1 = 1]) extends A;
''');
  }

  test_unnamed_P_superFormals_P_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B(super.p1) extends A {
  this : super();
}
''');
  }

  test_unnamed_P_superFormals_p_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B([super.p1]) extends A {
//             ^^
// [diag.missingDefaultValueForParameterPositional] The parameter 'p1' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
  this : super();
}
''');
  }

  test_unnamed_p_superFormals_p_hasSuper_p() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B(super.p1) extends A {
//            ^^
// [diag.positionalSuperFormalParameterWithPositionalArgument] Positional super parameters can't be used when the super constructor invocation has a positional argument.
  this : super(1);
}
''');
  }

  test_unnamed_p_superFormals_p_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? p1]);
}
class B([super.p1]) extends A;
''');
  }

  test_unnamed_P_superFormals_P_noBody_wrongType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B(String super.p1) extends A;
//                   ^^
// [diag.superFormalParameterTypeIsNotSubtypeOfAssociated] The type 'String' of this parameter isn't a subtype of the type 'int' of the associated super constructor parameter.
''');
  }

  test_unnamed_P_superFormals_PP_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1);
}
class B(super.p1, super.p2) extends A;
//                      ^^
// [diag.superFormalParameterWithoutAssociatedPositional] No associated positional super constructor parameter.
''');
  }

  test_unnamed_PP_superFormals_P_hasSuper_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, int p2);
}
class B(super.p1) extends A {
  this : super();
//             ^
// [diag.notEnoughPositionalArgumentsNamePlural] 2 positional arguments expected by 'A.new', but 1 found.
}
''');
  }

  test_unnamed_PP_superFormals_P_hasSuper_P() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, int p2);
}
class B(super.p1) extends A {
//            ^^
// [diag.positionalSuperFormalParameterWithPositionalArgument] Positional super parameters can't be used when the super constructor invocation has a positional argument.
  this : super(0);
}
''');
  }

  test_unnamed_PP_superFormals_P_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, int p2);
}
class B(super.p1) extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_unnamed_Pp_superFormals_Pp_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p1, [int? p2]);
}
class B(super.p1, [super.p2]) extends A;
''');
  }
}
