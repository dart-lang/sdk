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
    element: <testLibraryFragment>::@class::B
    element2: <testLibraryFragment>::@class::B#element
    type: B<int>
  staticElement: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {U: int}
    redirectedConstructor: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: int}
      redirectedConstructor: <null>
  element: <testLibraryFragment>::@class::B::@constructor::new#element
''');
  }

  test_fieldShadowingWildcardParameter() async {
    await assertErrorsInCode(r'''
class A {
  var v;
  var _;
  A(var _) : v = _;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 45, 1),
    ]);

    var node = findNode.constructorFieldInitializer('v = _');
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: v
    staticElement: <testLibraryFragment>::@class::A::@field::v
    element: <testLibraryFragment>::@class::A::@field::v#element
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: _
    staticElement: <testLibraryFragment>::@class::A::@getter::_
    element: <testLibraryFragment>::@class::A::@getter::_#element
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: a
        element: <testLibraryFragment>::@class::a
        element2: <testLibraryFragment>::@class::a#element
        type: a
      name: a
      declaredElement: <testLibraryFragment>::@class::B::@constructor::new::@parameter::a
        type: a
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: <testLibraryFragment>::@class::B::@constructor::new::@parameter::a
            element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::a#element
            staticType: a
          semicolon: ;
      rightBracket: }
  declaredElement: <testLibraryFragment>::@class::B::@constructor::new
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <testLibraryFragment>::@class::A::@constructor::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::named
    element: <testLibraryFragment>::@class::A::@constructor::named#element
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment>::@class::B::@constructor::new
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
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
            element: U@53
            element2: <not-implemented>
            type: U
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A<U>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::named
        substitution: {T: U}
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: U}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment>::@class::B::@constructor::new
    type: B<U> Function()
''');
  }

  test_redirectedConstructor_named_unresolved() async {
    await assertErrorsInCode(r'''
class A implements B {
  A();
}

class B {
  factory B() = A.named;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 59, 7),
    ]);

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment>::@class::B::@constructor::new
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
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
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment>::@class::B::@constructor::named
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
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
            element: U@47
            element2: <not-implemented>
            type: U
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A<U>
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::new
      substitution: {T: U}
    element: <testLibraryFragment>::@class::A::@constructor::new#element
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment>::@class::B::@constructor::named
    type: B<U> Function()
''');
  }

  test_redirectedConstructor_unnamed_unresolved() async {
    await assertErrorsInCode(r'''
class A implements B {
  A.named();
}

class B {
  factory B.named() = A;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 71, 1),
    ]);

    var node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
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
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A
    staticElement: <null>
    element: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: <testLibraryFragment>::@class::B::@constructor::named
    type: B Function()
''');
  }
}
