// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationResolutionTest);
  });
}

@reflectiveTest
class MixinDeclarationResolutionTest extends PubPackageResolutionTest {
  test_classDeclaration_with() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class A extends Object with M {}
''');

    var node = findNode.singleWithClause;
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

  test_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class A = Object with M;
''');

    var node = findNode.singleWithClause;
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

  test_commentReference() async {
    await assertNoErrorsInCode(r'''
const a = 0;

/// Reference [a] in documentation.
mixin M {}
''');

    var node = findNode.commentReference('a]');
    assertResolvedNodeText(node, r'''
CommentReference
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: null
''');
  }

  test_field() async {
    await assertNoErrorsInCode(r'''
mixin M<T> {
  late T f;
}
''');

    var node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    type: NamedType
      name: T
      element2: #E0 T
      type: T
    variables
      VariableDeclaration
        name: f
        declaredElement: <testLibraryFragment> f@22
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_getter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get foo => 0;
}
''');

    var node = findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  propertyKeyword: get
  name: foo
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
      staticType: int
    semicolon: ;
  declaredElement: <testLibraryFragment> foo@20
    element: <testLibrary>::@mixin::M::@getter::foo
      type: int Function()
''');
  }

  test_implementsClause() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}

mixin M implements A, B {}
''');

    var node = findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    NamedType
      name: B
      element2: <testLibrary>::@class::B
      type: B
''');
  }

  test_invalid_unresolved_before_mixin() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

abstract class X extends A with U1, U2, M {}
''',
      [
        error(CompileTimeErrorCode.mixinOfNonClass, 121, 2),
        error(CompileTimeErrorCode.mixinOfNonClass, 125, 2),
        error(
          CompileTimeErrorCode.mixinApplicationNoConcreteSuperInvokedMember,
          129,
          1,
        ),
      ],
    );
  }

  test_lookUpMemberInInterfaces_Object() async {
    await assertNoErrorsInCode(r'''
class Foo {}

mixin UnhappyMixin on Foo {
  String toString() => '$runtimeType';
}
''');
  }

  test_metadata() async {
    await assertNoErrorsInCode(r'''
const a = 0;

@a
mixin M {}
''');

    var node = findNode.annotation('@a');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: null
  element2: <testLibrary>::@getter::a
''');
  }

  test_method() async {
    await assertNoErrorsInCode(r'''
mixin M {
  void foo() {}
}
''');

    var node = findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment> foo@17
    element: <testLibrary>::@mixin::M::@method::foo
      type: void Function()
''');
  }

  test_methodCallTypeInference_mixinType() async {
    await assertErrorsInCode(
      '''
g(M<T> f<T>()) {
  C<int> c = f();
}

class C<T> {}

mixin M<T> on C<T> {}
''',
      [error(WarningCode.unusedLocalVariable, 26, 1)],
    );

    var node = findNode.functionExpressionInvocation('f()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::g::@formalParameter::f
    staticType: M<T> Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: M<int> Function()
  staticType: M<int>
  typeArgumentTypes
    int
''');
  }

  test_onClause() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}

mixin M on A, B {}
''');

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A
    NamedType
      name: B
      element2: <testLibrary>::@class::B
      type: B
''');
  }

  test_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  void set foo(int _) {}
}
''');

    var node = findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  propertyKeyword: set
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: _
      declaredElement: <testLibraryFragment> _@29
        element: isPrivate
          type: int
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment> foo@21
    element: <testLibrary>::@mixin::M::@setter::foo
      type: void Function(int)
''');
  }

  test_superInvocation_getter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

mixin M on A {
  void bar() {
    super.foo;
  }
}

class X extends A with M {}
''');

    var node = findNode.propertyAccess('super.foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_superInvocation_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int x) {}
}

mixin M on A {
  void bar() {
    super.foo(42);
  }
}

class X extends A with M {}
''');

    var node = findNode.methodInvocation('foo(42)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::x
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_superInvocation_setter() async {
    await assertNoErrorsInCode(r'''
class A {
  void set foo(int _) {}
}

mixin M on A {
  void bar() {
    super.foo = 0;
  }
}

class X extends A with M {}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: M
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }
}
