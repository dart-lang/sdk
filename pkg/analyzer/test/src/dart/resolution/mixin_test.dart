// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
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
      element: <testLibraryFragment>::@mixin::M
      element2: <testLibraryFragment>::@mixin::M#element
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
      element: <testLibraryFragment>::@mixin::M
      element2: <testLibraryFragment>::@mixin::M#element
      type: M
''');
  }

  test_commentReference() async {
    await assertNoErrorsInCode(r'''
const a = 0;

/// Reference [a] in documentation.
mixin M {}
''');

    var aRef = findNode.commentReference('a]').expression;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_element() async {
    await assertNoErrorsInCode(r'''
mixin M {}
''');

    var mixin = findNode.mixin('mixin M');
    var element = findElement.mixin('M');
    assertElement(mixin, element);

    expect(element.typeParameters, isEmpty);

    expect(element.supertype, isNull);
    expect(element.thisType.isDartCoreObject, isFalse);

    assertElementTypes(
      element.superclassConstraints,
      ['Object'],
    );
    assertElementTypes(element.interfaces, []);
  }

  test_element_allSupertypes() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}
class C {}

mixin M1 on A, B {}
mixin M2 on A implements B, C {}
''');

    assertElementTypes(
      findElement.mixin('M1').allSupertypes,
      ['Object', 'A', 'B'],
    );
    assertElementTypes(
      findElement.mixin('M2').allSupertypes,
      ['Object', 'A', 'B', 'C'],
    );
  }

  test_element_allSupertypes_generic() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {}
class B<T> extends A<int, T> {}

mixin M1 on A<int, double> {}
mixin M2 on B<String> {}
''');

    assertElementTypes(
      findElement.mixin('M1').allSupertypes,
      ['Object', 'A<int, double>'],
    );
    assertElementTypes(
      findElement.mixin('M2').allSupertypes,
      ['Object', 'A<int, String>', 'B<String>'],
    );
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
      element: T@8
      element2: <not-implemented>
      type: T
    variables
      VariableDeclaration
        name: f
        declaredElement: <testLibraryFragment>::@mixin::M::@field::f
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
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  propertyKeyword: get
  name: foo
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
      staticType: int
    semicolon: ;
  declaredElement: <testLibraryFragment>::@mixin::M::@getter::foo
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
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A
    NamedType
      name: B
      element: <testLibraryFragment>::@class::B
      element2: <testLibraryFragment>::@class::B#element
      type: B
''');
  }

  test_invalid_unresolved_before_mixin() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

abstract class X extends A with U1, U2, M {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 121, 2),
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 125, 2),
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          129,
          1),
    ]);
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

    var a = findElement.topGet('a');
    var element = findElement.mixin('M');

    var metadata = element.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].element, same(a));

    var annotation = findNode.annotation('@a');
    assertElement(annotation, a);
    expect(annotation.elementAnnotation, same(metadata[0]));
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
    element: <null>
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
  declaredElement: <testLibraryFragment>::@mixin::M::@method::foo
    type: void Function()
''');
  }

  test_methodCallTypeInference_mixinType() async {
    await assertErrorsInCode('''
g(M<T> f<T>()) {
  C<int> c = f();
}

class C<T> {}

mixin M<T> on C<T> {}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);

    var node = findNode.functionExpressionInvocation('f()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: M<T> Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A
    NamedType
      name: B
      element: <testLibraryFragment>::@class::B
      element2: <testLibraryFragment>::@class::B#element
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
    element: <null>
    element2: <null>
    type: void
  propertyKeyword: set
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      name: _
      declaredElement: <testLibraryFragment>::@mixin::M::@setter::foo::@parameter::_
        type: int
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment>::@mixin::M::@setter::foo
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

    var access = findNode.propertyAccess('super.foo;');
    assertElement(access, findElement.getter('foo'));
    assertType(access, 'int');
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::x
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
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }
}
