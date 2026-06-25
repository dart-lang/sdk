// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorDeclarationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstructorDeclarationResolutionTest extends PubPackageResolutionTest {
  test_factory_redirect_generic_instantiated() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> implements B<T> {
  A(T a);
}
class B<U> {
  factory B(U a) = A<U>;
}

B<int> b = B(0);
''');

    nodeTextConfiguration.withRedirectedConstructors = true;

    var node = result.findNode.constructorName('B(0)');
    assertResolvedNodeText(node, r'''
ConstructorName
  type: NamedType
    name: B
    element: <testLibrary>::@class::B
    type: B<int>
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {U: int}
    redirectedConstructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
      redirectedConstructor: <null>
''');
  }

  test_fieldShadowingWildcardParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  var v;
  var _;
  A(_) : v = _;
//           ^
// [diag.implicitThisReferenceInInitializer] The instance member '_' can't be accessed in an initializer.
}
''');

    var node = result.findNode.constructorFieldInitializer('v = _');
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: v
    element: <testLibrary>::@class::A::@field::v
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: _
    element: <testLibrary>::@class::A::@getter::_
    staticType: dynamic
''');
  }

  test_formalParameterScope() async {
    var result = await resolveTestCodeWithDiagnostics('''
class a {}

class B {
  B(a a) {
    a;
  }
}
''');

    var node = result.findNode.constructorDeclaration('B(');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: a
        element: <testLibrary>::@class::a
        type: a
      name: a
      declaredFragment: <testLibraryFragment> a@28
        element: isPublic
          type: a
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: <testLibrary>::@class::B::@constructor::new::@formalParameter::a
            staticType: a
          semicolon: ;
      rightBracket: }
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B Function(a)
''');
  }

  test_privateNamedParameter_accessInInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? _x;
//     ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  int? _y;
//     ^^
// [diag.unusedField] The value of the field '_y' isn't used.
  C({this._x}) : _y = _x;
}
''');

    var node = result.findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: _y
    element: <testLibrary>::@class::C::@field::_y
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: _x
    element: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
    staticType: int?
''');
  }

  test_privateNamedParameter_fieldFormal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? _x;
//     ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  C({this._x});
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: FieldFormalParameter
      thisKeyword: this
      period: .
      name: _x
      declaredFragment: <testLibraryFragment> x@31
        element: hasImplicitType isFinal isPublic
          type: int?
          field: <testLibrary>::@class::C::@field::_x
    rightDelimiter: }
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::C::@constructor::new
      type: C Function({int? x})
''');
  }

  test_privateNamedParameter_nonFieldFormal() async {
    // The user is incorrectly using a private named parameter for a non-field
    // parameter. This is erroneous, but resolve using the private name.
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C({int? _x});
//        ^^
// [diag.privateNamedNonFieldParameter] Named parameters that don't refer to instance variables can't start with underscore.
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: {
    parameter: RegularFormalParameter
      type: NamedType
        name: int
        question: ?
        element: dart:core::@class::int
        type: int?
      name: _x
      declaredFragment: <testLibraryFragment> _x@20
        element: isPrivate
          type: int?
    rightDelimiter: }
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::C::@constructor::new
      type: C Function({int? _x})
''');
  }

  test_redirectedConstructor_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A implements B {
  A.named();
}

class B {
  factory B() = A.named;
}
''');

    var node = result.findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B Function()
''');
  }

  test_redirectedConstructor_named_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> implements B<T> {
  A.named();
}

class B<U> {
  factory B() = A<U>.named;
}
''');

    var node = result.findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: U
            element: #E0 U
            type: U
        rightBracket: >
      element: <testLibrary>::@class::A
      type: A<U>
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: U}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: U}
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B<U> Function()
''');
  }

  test_redirectedConstructor_named_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A implements B {
  A();
}

class B {
  factory B() = A.named;
//              ^^^^^^^
// [diag.redirectToMissingConstructor] The constructor 'A.named' couldn't be found in 'A'.
}
''');

    var node = result.findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <null>
      staticType: null
    element: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B Function()
''');
  }

  test_redirectedConstructor_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A implements B {
  A();
}

class B {
  factory B.named() = A;
}
''');

    var node = result.findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@55
    element: <testLibrary>::@class::B::@constructor::named
      type: B Function()
''');
  }

  test_redirectedConstructor_unnamed_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> implements B<T> {
  A();
}

class B<U> {
  factory B.named() = A<U>;
}
''');

    var node = result.findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: U
            element: #E0 U
            type: U
        rightBracket: >
      element: <testLibrary>::@class::A
      type: A<U>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: U}
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@64
    element: <testLibrary>::@class::B::@constructor::named
      type: B<U> Function()
''');
  }

  test_redirectedConstructor_unnamed_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A implements B {
  A.named();
}

class B {
  factory B.named() = A;
//                    ^
// [diag.redirectToMissingConstructor] The constructor 'A' couldn't be found in 'A'.
}
''');

    var node = result.findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    element: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@61
    element: <testLibrary>::@class::B::@constructor::named
      type: B Function()
''');
  }
}
