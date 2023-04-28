// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
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
    var classB_constructor = findElement.class_('B').unnamedConstructor!;
    assertMember(
      classB_constructor.redirectedConstructor,
      findElement.unnamedConstructor('A'),
      {'T': 'U'},
    );

    var B_int = findElement.topVar('b').type as InterfaceType;
    var B_int_constructor = B_int.constructors.single;
    var B_int_redirect = B_int_constructor.redirectedConstructor!;
    assertMember(
      B_int_redirect,
      findElement.unnamedConstructor('A'),
      {'T': 'int'},
    );
    assertType(B_int_redirect.returnType, 'A<int>');
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

    final node = findNode.constructorDeclaration('B(');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  returnType: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: a
        element: self::@class::a
        type: a
      name: a
      declaredElement: self::@class::B::@constructor::new::@parameter::a
        type: a
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: self::@class::B::@constructor::new::@parameter::a
            staticType: a
          semicolon: ;
      rightBracket: }
  declaredElement: self::@class::B::@constructor::new
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

    final node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: self::@class::A::@constructor::named
      staticType: null
    staticElement: self::@class::A::@constructor::named
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: self::@class::B::@constructor::new
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

    final node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: self::@class::B
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
            type: U
        rightBracket: >
      element: self::@class::A
      type: A<U>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: U}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: U}
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: self::@class::B::@constructor::new
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

    final node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: self::@class::B
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <null>
      staticType: null
    staticElement: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: self::@class::B::@constructor::new
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

    final node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: self::@class::B
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
      element: self::@class::A
      type: A
    staticElement: self::@class::A::@constructor::new
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: self::@class::B::@constructor::named
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

    final node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: self::@class::B
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
            type: U
        rightBracket: >
      element: self::@class::A
      type: A<U>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: U}
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: self::@class::B::@constructor::named
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

    final node = findNode.constructorDeclaration('factory B');
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
    token: B
    staticElement: self::@class::B
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
      element: self::@class::A
      type: A
    staticElement: <null>
  body: EmptyFunctionBody
    semicolon: ;
  declaredElement: self::@class::B::@constructor::named
    type: B Function()
''');
  }
}
