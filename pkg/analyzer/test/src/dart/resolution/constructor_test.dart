// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorDeclarationResolutionTest);
  });
}

@reflectiveTest
class ConstructorDeclarationResolutionTest extends PubPackageResolutionTest {
  test_factory_redirect_generic_instantiated() async {
    await assertNoErrorsInCode(r'''
class A<T> implements B<T> {
  A(T a);
}
class B<U> {
  factory B(U a) = A<U>;
}

B<int> b = B(0);
''');

    nodeTextConfiguration.withRedirectedConstructors = true;

    var node = findNode.constructorName('B(0)');
    assertResolvedNodeText(node, r'''
ConstructorName
  type: NamedType
    name: B
    element2: <testLibrary>::@class::B
    type: B<int>
  element: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {U: int}
    redirectedConstructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
      redirectedConstructor: <null>
''');
  }

  test_fieldShadowingWildcardParameter() async {
    await assertErrorsInCode(
      r'''
class A {
  var v;
  var _;
  A(var _) : v = _;
}
''',
      [error(CompileTimeErrorCode.implicitThisReferenceInInitializer, 45, 1)],
    );

    var node = findNode.constructorFieldInitializer('v = _');
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
    await assertNoErrorsInCode('''
class a {}

class B {
  B(a a) {
    a;
  }
}
''');

    var node = findNode.constructorDeclaration('B(');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  returnType: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: a
        element2: <testLibrary>::@class::a
        type: a
      name: a
      declaredElement: <testLibraryFragment> a@28
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
  declaredElement: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B Function(a)
''');
  }

  test_redirectedConstructor_named() async {
    await assertNoErrorsInCode(r'''
class A implements B {
  A.named();
}

class B {
  factory B() = A.named;
}
''');

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
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
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B Function()
''');
  }

  test_redirectedConstructor_named_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> implements B<T> {
  A.named();
}

class B<U> {
  factory B() = A<U>.named;
}
''');

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
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
            element2: #E0 U
            type: U
        rightBracket: >
      element2: <testLibrary>::@class::A
      type: A<U>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: U}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: U}
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B<U> Function()
''');
  }

  test_redirectedConstructor_named_unresolved() async {
    await assertErrorsInCode(
      r'''
class A implements B {
  A();
}

class B {
  factory B() = A.named;
}
''',
      [error(CompileTimeErrorCode.redirectToMissingConstructor, 59, 7)],
    );

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
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
      element2: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <null>
      staticType: null
    element: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment> new@null
    element: <testLibrary>::@class::B::@constructor::new
      type: B Function()
''');
  }

  test_redirectedConstructor_unnamed() async {
    await assertNoErrorsInCode(r'''
class A implements B {
  A();
}

class B {
  factory B.named() = A;
}
''');

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
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
      element2: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment> named@55
    element: <testLibrary>::@class::B::@constructor::named
      type: B Function()
''');
  }

  test_redirectedConstructor_unnamed_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> implements B<T> {
  A();
}

class B<U> {
  factory B.named() = A<U>;
}
''');

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
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
            element2: #E0 U
            type: U
        rightBracket: >
      element2: <testLibrary>::@class::A
      type: A<U>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: U}
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment> named@64
    element: <testLibrary>::@class::B::@constructor::named
      type: B<U> Function()
''');
  }

  test_redirectedConstructor_unnamed_unresolved() async {
    await assertErrorsInCode(
      r'''
class A implements B {
  A.named();
}

class B {
  factory B.named() = A;
}
''',
      [error(CompileTimeErrorCode.redirectToMissingConstructor, 71, 1)],
    );

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
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
      element2: <testLibrary>::@class::A
      type: A
    element: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment> named@61
    element: <testLibrary>::@class::B::@constructor::named
      type: B Function()
''');
  }
}
