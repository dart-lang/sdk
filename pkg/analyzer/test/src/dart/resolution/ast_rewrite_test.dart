// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstRewriteImplicitCallReferenceTest);
    defineReflectiveTests(AstRewriteMethodInvocationTest);
    defineReflectiveTests(AstRewritePrefixedIdentifierTest);

    // TODO(srawlins): Add AstRewriteInstanceCreationExpressionTest test, likely
    // moving many test cases from ConstructorReferenceResolutionTest,
    // FunctionReferenceResolutionTest, and TypeLiteralResolutionTest.
    // TODO(srawlins): Add AstRewritePropertyAccessTest test, likely
    // moving many test cases from ConstructorReferenceResolutionTest,
    // FunctionReferenceResolutionTest, and TypeLiteralResolutionTest.
  });
}

@reflectiveTest
class AstRewriteImplicitCallReferenceTest extends PubPackageResolutionTest {
  test_assignment_indexExpression() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C c) {
  var map = <int, C>{};
  return map[1] = c;
}
''');

    var node = findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: AssignmentExpression
    leftHandSide: IndexExpression
      target: SimpleIdentifier
        token: map
        element: map@83
        staticType: Map<int, C>
      leftBracket: [
      index: IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: dart:core::@class::Map::@method::[]=::@formalParameter::key
          substitution: {K: int, V: C}
        staticType: int
      rightBracket: ]
      element: <null>
      staticType: null
    operator: =
    rightHandSide: SimpleIdentifier
      token: c
      correspondingParameter: ParameterMember
        baseElement: dart:core::@class::Map::@method::[]=::@formalParameter::value
        substitution: {K: int, V: C}
      element: <testLibrary>::@function::foo::@formalParameter::c
      staticType: C
    readElement2: <null>
    readType: null
    writeElement2: MethodMember
      baseElement: dart:core::@class::Map::@method::[]=
      substitution: {K: int, V: C}
    writeType: C
    element: <null>
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_conditional_else() async {
    await assertNoErrorsInCode('''
abstract class A {}
abstract class C extends A {
  void call();
}
void Function() f(A a, bool b, C c, dynamic d) => b ? d : (b ? a : c);
''');
    // `c` is in the "else" position of a conditional expression, so implicit
    // call tearoff logic should not apply to it.
    // Therefore the type of `b ? a : c` should be `A`.
    var expr = findNode.conditionalExpression('b ? a : c');
    assertResolvedNodeText(expr, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  colon: :
  elseExpression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  staticType: A
''');
  }

  test_conditional_then() async {
    await assertNoErrorsInCode('''
abstract class A {}
abstract class C extends A {
  void call();
}
void Function() f(A a, bool b, C c, dynamic d) => b ? d : (b ? c : a);
''');
    // `c` is in the "then" position of a conditional expression, so implicit
    // call tearoff logic should not apply to it.
    // Therefore the type of `b ? c : a` should be `A`.
    var expr = findNode.conditionalExpression('b ? c : a');
    assertResolvedNodeText(expr, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  colon: :
  elseExpression: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  staticType: A
''');
  }

  test_explicitTypeArguments() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

void foo() {
  var c = C();
  c<int>;
}
''');

    var node = findNode.implicitCallReference('c<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: c@55
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_ifNull_lhs() async {
    await assertErrorsInCode(
      '''
abstract class A {}
abstract class C extends A {
  void call();
}

void Function() f(A a, bool b, C c, dynamic d) => b ? d : c ?? a;
''',
      [
        error(WarningCode.deadCode, 127, 4),
        error(StaticWarningCode.deadNullAwareExpression, 130, 1),
      ],
    );
    // `c` is on the LHS of an if-null expression, so implicit call tearoff
    // logic should not apply to it.
    // Therefore the type of `c ?? a` should be `A`.
    var expr = findNode.binary('c ?? a');
    assertResolvedNodeText(expr, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  operator: ??
  rightOperand: SimpleIdentifier
    token: a
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  element: <null>
  staticInvokeType: null
  staticType: A
''');
  }

  test_ifNull_rhs() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C? c1, C c2) {
  return c1 ?? c2;
}
''');

    var node = findNode.implicitCallReference('c1 ?? c2');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: BinaryExpression
    leftOperand: SimpleIdentifier
      token: c1
      element: <testLibrary>::@function::foo::@formalParameter::c1
      staticType: C?
    operator: ??
    rightOperand: SimpleIdentifier
      token: c2
      correspondingParameter: <null>
      element: <testLibrary>::@function::foo::@formalParameter::c2
      staticType: C
    element: <null>
    staticInvokeType: null
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_listLiteral_element() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [c];
}
''');

    var node = findNode.implicitCallReference('c]');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_listLiteral_forElement() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [
    for (var _ in [1, 2, 3]) c,
  ];
}
''');

    var node = findNode.implicitCallReference('c,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_listLiteral_ifElement() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [
    if (1==2) c,
  ];
}
''');

    var node = findNode.implicitCallReference('c,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_listLiteral_ifElement_else() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c1, C c2) {
  return [
    if (1==2) c1
    else c2,
  ];
}
''');

    var node = findNode.implicitCallReference('c2,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c2
    element: <testLibrary>::@function::foo::@formalParameter::c2
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_parenthesized_cascade_target() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call();
  void m();
}
void Function() f(C c) => (c)..m();
''');

    var node = findNode.implicitCallReference('(c)');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: CascadeExpression
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    cascadeSections
      MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: m
          element: <testLibrary>::@class::C::@method::m
          staticType: void Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: void Function()
        staticType: void
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function()
''');
  }

  test_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
abstract class C {
  C get c;
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c.c;
}
''');

    var node = findNode.implicitCallReference('c.c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::foo::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: c
      element: <testLibrary>::@class::C::@getter::c
      staticType: C
    element: <testLibrary>::@class::C::@getter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_propertyAccess() async {
    await assertNoErrorsInCode('''
abstract class C {
  C get c;
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c.c.c;
}
''');

    var node = findNode.implicitCallReference('c.c.c');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: c
        element: <testLibrary>::@function::foo::@formalParameter::c
        staticType: C
      period: .
      identifier: SimpleIdentifier
        token: c
        element: <testLibrary>::@class::C::@getter::c
        staticType: C
      element: <testLibrary>::@class::C::@getter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: c
      element: <testLibrary>::@class::C::@getter::c
      staticType: C
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_setOrMapLiteral_element() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Set<void Function(int)> foo(C c) {
  return {c};
}
''');

    var node = findNode.implicitCallReference('c}');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_setOrMapLiteral_mapLiteralEntry_key() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Map<void Function(int), int> foo(C c) {
  return {c: 1};
}
''');

    var node = findNode.implicitCallReference('c:');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_setOrMapLiteral_mapLiteralEntry_value() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Map<int, void Function(int)> foo(C c) {
  return {1: c};
}
''');

    var node = findNode.implicitCallReference('c}');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_simpleIdentifier() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c;
}
''');

    var node = findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::foo::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: void Function(int)
''');
  }

  test_simpleIdentifier_typeAlias() async {
    await assertNoErrorsInCode('''
class A {
  void call() {}
}
typedef B = A;
Function f(B b) => b;
''');

    var node = findNode.implicitCallReference('b;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: A
      alias: <testLibrary>::@typeAlias::B
  element: <testLibrary>::@class::A::@method::call
  staticType: void Function()
''');
  }

  test_simpleIdentifier_typeVariable() async {
    await assertNoErrorsInCode('''
class A {
  void call() {}
}
Function f<X extends A>(X x) => x;
''');

    var node = findNode.implicitCallReference('x;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: X
  element: <testLibrary>::@class::A::@method::call
  staticType: void Function()
''');
  }

  test_simpleIdentifier_typeVariable2() async {
    await assertNoErrorsInCode('''
class A {
  void call() {}
}
Function f<X extends A, Y extends X>(Y y) => y;
''');

    var node = findNode.implicitCallReference('y;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: y
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: Y
  element: <testLibrary>::@class::A::@method::call
  staticType: void Function()
''');
  }

  test_simpleIdentifier_typeVariable2_nullable() async {
    await assertErrorsInCode(
      '''
class A {
  void call() {}
}
Function f<X extends A, Y extends X?>(Y y) => y;
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 75, 1)],
    );

    // Verify that no ImplicitCallReference was inserted.
    var node = findNode.expressionFunctionBody('y;').expression;
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: y
  element: <testLibrary>::@function::f::@formalParameter::y
  staticType: Y
''');
  }

  test_simpleIdentifier_typeVariable_nullable() async {
    await assertErrorsInCode(
      '''
class A {
  void call() {}
}
Function f<X extends A>(X? x) => x;
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 62, 1)],
    );

    // Verify that no ImplicitCallReference was inserted.
    var node = findNode.expressionFunctionBody('x;').expression;
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: x
  element: <testLibrary>::@function::f::@formalParameter::x
  staticType: X?
''');
  }
}

@reflectiveTest
class AstRewriteMethodInvocationTest extends PubPackageResolutionTest
    with AstRewriteMethodInvocationTestCases {}

mixin AstRewriteMethodInvocationTestCases on PubPackageResolutionTest {
  test_targetNull_cascade() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

f(A a) {
  a..foo();
}
''');

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
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

  test_targetNull_class() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int a);
}

f() {
  A<int, String>(0);
}
''');

    var node = findNode.instanceCreation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          NamedType
            name: String
            element2: dart:core::@class::String
            type: String
        rightBracket: >
      element2: <testLibrary>::@class::A
      type: A<int, String>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_targetNull_extension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E<T> on A {
  void foo() {}
}

f(A a) {
  E<int>(a).foo();
}
''');

    var node = findNode.extensionOverride('E<int>(a)');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: <null>
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
    rightParenthesis: )
  element2: <testLibrary>::@extension::E
  extendedType: A
  staticType: null
  typeArgumentTypes
    int
''');
  }

  test_targetNull_function() async {
    await assertNoErrorsInCode(r'''
void A<T, U>(int a) {}

f() {
  A<int, String>(0);
}
''');

    var node = findNode.methodInvocation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: A
    element: <testLibrary>::@function::A
    staticType: void Function<T, U>(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::A::@formalParameter::a
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
    String
''');
  }

  test_targetNull_typeAlias_interfaceType() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int _);
}

typedef X<T, U> = A<T, U>;

void f() {
  X<int, String>(0);
}
''');

    var node = findNode.instanceCreation('X<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          NamedType
            name: String
            element2: dart:core::@class::String
            type: String
        rightBracket: >
      element2: <testLibrary>::@typeAlias::X
      type: A<int, String>
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::_
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_targetNull_typeAlias_Never() async {
    await assertErrorsInCode(
      r'''
typedef X = Never;

void f() {
  X(0);
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunction, 33, 1)],
    );

    // Not rewritten.
    findNode.methodInvocation('X(0)');
  }

  test_targetPrefixedIdentifier_prefix_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(T a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named(0);
}
''');

    var node = findNode.instanceCreation('A.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element2: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetPrefixedIdentifier_prefix_class_constructor_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(int a);
}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named<int>(0);
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          50,
          5,
          messageContains: ["The constructor 'prefix.A.named'"],
        ),
      ],
    );

    var node = findNode.instanceCreation('named<int>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetPrefixedIdentifier_prefix_class_constructor_typeArguments_new() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.new(int a);
}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart' as prefix;

f() {
  prefix.A.new<int>(0);
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          48,
          5,
          messageContains: ["The constructor 'prefix.A.new'"],
        ),
      ],
    );

    var node = findNode.instanceCreation('new<int>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: new
      element: ConstructorMember
        baseElement: package:test/a.dart::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetPrefixedIdentifier_prefix_getter_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
A get foo => A();

class A {
  void bar(int a) {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.foo.bar(0);
}
''');

    var node = findNode.methodInvocation('bar(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@getter::foo
      staticType: A
    element: package:test/a.dart::@getter::foo
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: bar
    element: package:test/a.dart::@class::A::@method::bar
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@class::A::@method::bar::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_targetPrefixedIdentifier_typeAlias_interfaceType_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.X.named(0);
}
''');

    var node = findNode.instanceCreation('X.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: X
      element2: package:test/a.dart::@typeAlias::X
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetSimpleIdentifier_class_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

f() {
  A.named(0);
}
''');

    var node = findNode.instanceCreation('A.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments() async {
    await assertErrorsInCode(
      r'''
class A<T, U> {
  A.named(int a);
}

f() {
  A.named<int, String>(0);
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          52,
          13,
          messageContains: ["The constructor 'A.named'"],
        ),
      ],
    );

    // TODO(scheglov): Move type arguments
    var node = findNode.instanceCreation('named<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<dynamic, dynamic>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic, U: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: dynamic, U: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: dynamic, U: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: A<dynamic, dynamic>
''');
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments_new() async {
    await assertErrorsInCode(
      r'''
class A<T, U> {
  A.new(int a);
}

f() {
  A.new<int, String>(0);
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          48,
          13,
          messageContains: ["The constructor 'A.new'"],
        ),
      ],
    );

    // TODO(scheglov): Move type arguments
    var node = findNode.instanceCreation('new<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<dynamic, dynamic>
    period: .
    name: SimpleIdentifier
      token: new
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: dynamic, U: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: dynamic, U: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
          substitution: {T: dynamic, U: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: A<dynamic, dynamic>
''');
  }

  test_targetSimpleIdentifier_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int a) {}
}

f() {
  A.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
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
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_targetSimpleIdentifier_prefix_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T, U> {
  A(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var node = findNode.instanceCreation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          NamedType
            name: String
            element2: dart:core::@class::String
            type: String
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int, String>
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::a
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_targetSimpleIdentifier_prefix_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}

extension E<T> on A {
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f(prefix.A a) {
  prefix.E<int>(a).foo();
}
''');

    var node = findNode.extensionOverride('E<int>(a)');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  importPrefix: ImportPrefixReference
    name: prefix
    period: .
    element2: <testLibraryFragment>::@prefix2::prefix
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: <null>
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
    rightParenthesis: )
  element2: package:test/a.dart::@extension::E
  extendedType: A
  staticType: null
  typeArgumentTypes
    int
''');
  }

  test_targetSimpleIdentifier_prefix_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void A<T, U>(int a) {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var node = findNode.methodInvocation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix2::prefix
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: A
    element: package:test/a.dart::@function::A
    staticType: void Function<T, U>(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@function::A::@formalParameter::a
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
    String
''');
  }

  test_targetSimpleIdentifier_typeAlias_interfaceType_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;

void f() {
  X.named(0);
}
''');

    var node = findNode.instanceCreation('X.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element2: <testLibrary>::@typeAlias::X
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }
}

@reflectiveTest
class AstRewritePrefixedIdentifierTest extends PubPackageResolutionTest {
  test_constructorReference_inAssignment_onLeftSide() async {
    await assertErrorsInCode(
      '''
class C {}

void f() {
  C.new = 1;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 27, 3)],
    );

    var identifier = findNode.prefixed('C.new');
    // The left side of the assignment is resolved by
    // [PropertyElementResolver._resolveTargetClassElement], which looks for
    // getters and setters on `C`, and does not recover with other elements
    // (methods, constructors). This prefixed identifier can have a real
    // `staticElement` if we add such recovery.
    expect(identifier.element, isNull);
  }

  test_constructorReference_inAssignment_onRightSide() async {
    await assertNoErrorsInCode('''
class C {}

Function? f;
void g() {
  f = C.new;
}
''');

    var node = findNode.constructorReference('C.new');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: C
      element2: <testLibrary>::@class::C
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::C::@constructor::new
      staticType: null
    element: <testLibrary>::@class::C::@constructor::new
  correspondingParameter: <testLibrary>::@setter::f::@formalParameter::value
  staticType: C Function()
''');
  }

  // TODO(srawlins): Complete tests of all cases of rewriting (or not) a
  // prefixed identifier.
}
