// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractSuperMemberReferenceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AbstractSuperMemberReferenceTest extends PubPackageResolutionTest {
  test_methodInvocation_mixin_implements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(int _) {}
}

mixin M implements A {
  void bar() {
    super.foo(0);
//        ^^^
// [diag.abstractSuperMemberReference] The method 'foo' is always abstract in the supertype.
  }
}
''');

    var node = result.findNode.methodInvocation('super.foo(0)');
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
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_methodInvocation_mixinHasConcrete() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin M {
  void foo() {}
}

class B = A with M;

class C extends B {
  void bar() {
    super.foo();
  }
}
''');

    var node = result.findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_methodInvocation_mixinHasNoSuchMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void foo();
  noSuchMethod(im) => 42;
}

class B extends Object with A {
  void foo() => super.foo(); // ref
//                    ^^^
// [diag.abstractSuperMemberReference] The method 'foo' is always abstract in the supertype.
  noSuchMethod(im) => 87;
}
''');

    var node = result.findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_methodInvocation_superHasAbstract() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo(int _);
}

abstract class B extends A {
  void bar() {
    super.foo(0);
//        ^^^
// [diag.abstractSuperMemberReference] The method 'foo' is always abstract in the supertype.
  }

  void foo(int _) {} // does not matter
}
''');

    var node = result.findNode.methodInvocation('super.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_methodInvocation_superHasConcrete_mixinHasAbstract() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

mixin B {
  void foo();
}

class C extends A with B {
  void bar() {
    super.foo(); // ref
  }
}
''');

    var node = result.findNode.methodInvocation('foo(); // ref');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_methodInvocation_superHasNoSuchMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo();
  noSuchMethod(im) => 42;
}

class B extends A {
  int foo() => super.foo(); // ref
  noSuchMethod(im) => 87;
}
''');

    var node = result.findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_methodInvocation_superSuperHasConcrete() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo() {}
}

abstract class B extends A {
  void foo();
}

class C extends B {
  void bar() {
    super.foo();
  }
}
''');

    var node = result.findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_propertyAccess_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}

abstract class B extends A {
  bar() {
    super.foo; // ref
//        ^^^
// [diag.abstractSuperMemberReference] The getter 'foo' is always abstract in the supertype.
  }
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_propertyAccess_getter_mixin_implements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

mixin M implements A {
  void bar() {
    super.foo;
//        ^^^
// [diag.abstractSuperMemberReference] The getter 'foo' is always abstract in the supertype.
  }
}
''');

    var node = result.findNode.singlePropertyAccess;
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

  test_propertyAccess_getter_mixinHasNoSuchMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends Object with A {
  int get foo => super.foo; // ref
//                     ^^^
// [diag.abstractSuperMemberReference] The getter 'foo' is always abstract in the supertype.
  noSuchMethod(im) => 2;
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_propertyAccess_getter_superHasNoSuchMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo;
  noSuchMethod(im) => 1;
}

class B extends A {
  get foo => super.foo; // ref
  noSuchMethod(im) => 2;
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_propertyAccess_getter_superImplements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

abstract class B implements A {
}

class C extends B {
  int get foo => super.foo; // ref
//                     ^^^
// [diag.abstractSuperMemberReference] The getter 'foo' is always abstract in the supertype.
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_propertyAccess_getter_superSuperHasConcrete() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo => 0;
}

abstract class B extends A {
  int get foo;
}

class C extends B {
  int get bar => super.foo; // ref
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_propertyAccess_method_tearOff_abstract() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

abstract class B extends A {
  void bar() {
    super.foo; // ref
//        ^^^
// [diag.abstractSuperMemberReference] The method 'foo' is always abstract in the supertype.
  }
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  staticType: void Function()
''');
  }

  test_propertyAccess_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  set foo(int _);
}

abstract class B extends A {
  void bar() {
    super.foo = 0;
//        ^^^
// [diag.abstractSuperMemberReference] The setter 'foo' is always abstract in the supertype.
  }
}
''');

    var node = result.findNode.assignment('foo =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_mixin_implements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}

mixin M implements A {
  void bar() {
    super.foo = 0;
//        ^^^
// [diag.abstractSuperMemberReference] The setter 'foo' is always abstract in the supertype.
  }
}
''');

    var node = result.findNode.assignment('foo =');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_mixinHasNoSuchMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {
  set foo(int a);
  noSuchMethod(im) {}
}

class B extends Object with A {
  set foo(int a) => super.foo = a; // ref
//                        ^^^
// [diag.abstractSuperMemberReference] The setter 'foo' is always abstract in the supertype.
  noSuchMethod(im) {}
}
''');

    var node = result.findNode.assignment('foo =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    correspondingParameter: <testLibrary>::@mixin::A::@setter::foo::@formalParameter::a
    element: <testLibrary>::@class::B::@setter::foo::@formalParameter::a
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@mixin::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_superHasNoSuchMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int a);
  noSuchMethod(im) => 1;
}

class B extends A {
  set foo(int a) => super.foo = a; // ref
  noSuchMethod(im) => 2;
}
''');

    var node = result.findNode.assignment('foo =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::a
    element: <testLibrary>::@class::B::@setter::foo::@formalParameter::a
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_setter_superSuperHasConcrete() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void set foo(int _) {}
}

abstract class B extends A {
  void set foo(int _);
}

class C extends B {
  void bar() {
    super.foo = 0;
  }
}
''');

    var node = result.findNode.assignment('foo =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: C
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }
}
