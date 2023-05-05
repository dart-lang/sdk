// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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

    final node = findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: AssignmentExpression
    leftHandSide: IndexExpression
      target: SimpleIdentifier
        token: map
        staticElement: map@83
        staticType: Map<int, C>
      leftBracket: [
      index: IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: dart:core::@class::Map::@method::[]=::@parameter::key
          substitution: {K: int, V: C}
        staticType: int
      rightBracket: ]
      staticElement: <null>
      staticType: null
    operator: =
    rightHandSide: SimpleIdentifier
      token: c
      parameter: ParameterMember
        base: dart:core::@class::Map::@method::[]=::@parameter::value
        substitution: {K: int, V: C}
      staticElement: self::@function::foo::@parameter::c
      staticType: C
    readElement: <null>
    readType: null
    writeElement: MethodMember
      base: dart:core::@class::Map::@method::[]=
      substitution: {K: int, V: C}
    writeType: C
    staticElement: <null>
    staticType: C
  staticElement: self::@class::C::@method::call
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
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  colon: :
  elseExpression: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
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
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  colon: :
  elseExpression: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
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

    final node = findNode.implicitCallReference('c<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: c@55
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticElement: self::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_ifNull_lhs() async {
    await assertErrorsInCode('''
abstract class A {}
abstract class C extends A {
  void call();
}

void Function() f(A a, bool b, C c, dynamic d) => b ? d : c ?? a;
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 130, 1),
    ]);
    // `c` is on the LHS of an if-null expression, so implicit call tearoff
    // logic should not apply to it.
    // Therefore the type of `c ?? a` should be `A`.
    var expr = findNode.binary('c ?? a');
    assertResolvedNodeText(expr, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  operator: ??
  rightOperand: SimpleIdentifier
    token: a
    parameter: <null>
    staticElement: self::@function::f::@parameter::a
    staticType: A
  staticElement: <null>
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

    final node = findNode.implicitCallReference('c1 ?? c2');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: BinaryExpression
    leftOperand: SimpleIdentifier
      token: c1
      staticElement: self::@function::foo::@parameter::c1
      staticType: C?
    operator: ??
    rightOperand: SimpleIdentifier
      token: c2
      parameter: <null>
      staticElement: self::@function::foo::@parameter::c2
      staticType: C
    staticElement: <null>
    staticInvokeType: null
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c]');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: self::@function::foo::@parameter::c
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: self::@function::foo::@parameter::c
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: self::@function::foo::@parameter::c
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c2,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c2
    staticElement: self::@function::foo::@parameter::c2
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('(c)');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: CascadeExpression
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        staticElement: self::@function::f::@parameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    cascadeSections
      MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: m
          staticElement: self::@class::C::@method::m
          staticType: void Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: void Function()
        staticType: void
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c.c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      staticElement: self::@function::foo::@parameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: c
      staticElement: self::@class::C::@getter::c
      staticType: C
    staticElement: self::@class::C::@getter::c
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c.c.c');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: c
        staticElement: self::@function::foo::@parameter::c
        staticType: C
      period: .
      identifier: SimpleIdentifier
        token: c
        staticElement: self::@class::C::@getter::c
        staticType: C
      staticElement: self::@class::C::@getter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: c
      staticElement: self::@class::C::@getter::c
      staticType: C
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c}');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: self::@function::foo::@parameter::c
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c:');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: self::@function::foo::@parameter::c
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c}');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: self::@function::foo::@parameter::c
    staticType: C
  staticElement: self::@class::C::@method::call
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

    final node = findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    staticElement: self::@function::foo::@parameter::c
    staticType: C
  staticElement: self::@class::C::@method::call
  staticType: void Function(int)
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

    var invocation = findNode.methodInvocation('foo();');
    assertElement(invocation, findElement.method('foo'));
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
            element: dart:core::@class::int
            type: int
          NamedType
            name: String
            element: dart:core::@class::String
            type: String
        rightBracket: >
      element: self::@class::A
      type: A<int, String>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::a
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

    final node = findNode.extensionOverride('E<int>(a)');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        parameter: <null>
        staticElement: self::@function::f::@parameter::a
        staticType: A
    rightParenthesis: )
  element: self::@extension::E
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
    staticElement: self::@function::A
    staticType: void Function<T, U>(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@function::A::@parameter::a
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
            element: dart:core::@class::int
            type: int
          NamedType
            name: String
            element: dart:core::@class::String
            type: String
        rightBracket: >
      element: self::@typeAlias::X
      type: A<int, String>
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::_
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_targetNull_typeAlias_Never() async {
    await assertErrorsInCode(r'''
typedef X = Never;

void f() {
  X(0);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION, 33, 1),
    ]);

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
        element: self::@prefix::prefix
      name: A
      element: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::a
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

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named<int>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 50,
          5,
          messageContains: ["The constructor 'prefix.A.named'"]),
    ]);

    var node = findNode.instanceCreation('named<int>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::a
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

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.new<int>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 48,
          5,
          messageContains: ["The constructor 'prefix.A.new'"]),
    ]);

    var node = findNode.instanceCreation('new<int>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: self::@prefix::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::A::@constructor::new
        substitution: {T: int}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::new::@parameter::a
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
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@getter::foo
      staticType: A
    staticElement: package:test/a.dart::@getter::foo
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: bar
    staticElement: package:test/a.dart::@class::A::@method::bar
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@class::A::@method::bar::@parameter::a
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
        element: self::@prefix::prefix
      name: X
      element: package:test/a.dart::@typeAlias::X
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::named::@parameter::a
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
      element: self::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  A.named(int a);
}

f() {
  A.named<int, String>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          13,
          messageContains: ["The constructor 'A.named'"]),
    ]);

    // TODO(scheglov) Move type arguments
    var node = findNode.instanceCreation('named<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A<dynamic, dynamic>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic, U: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: dynamic, U: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::a
          substitution: {T: dynamic, U: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: A<dynamic, dynamic>
''');
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments_new() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  A.new(int a);
}

f() {
  A.new<int, String>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 48,
          13,
          messageContains: ["The constructor 'A.new'"]),
    ]);

    // TODO(scheglov) Move type arguments
    var node = findNode.instanceCreation('new<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: self::@class::A
      type: A<dynamic, dynamic>
    period: .
    name: SimpleIdentifier
      token: new
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::new
        substitution: {T: dynamic, U: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::new
      substitution: {T: dynamic, U: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::new::@parameter::a
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

    var invocation = findNode.methodInvocation('foo(0);');
    assertElement(invocation, findElement.method('foo'));
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
        element: self::@prefix::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
          NamedType
            name: String
            element: dart:core::@class::String
            type: String
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: A<int, String>
    staticElement: ConstructorMember
      base: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@class::A::@constructor::new::@parameter::a
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

    final node = findNode.extensionOverride('E<int>(a)');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  importPrefix: ImportPrefixReference
    name: prefix
    period: .
    element: self::@prefix::prefix
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        parameter: <null>
        staticElement: self::@function::f::@parameter::a
        staticType: A
    rightParenthesis: )
  element: package:test/a.dart::@extension::E
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
    staticElement: self::@prefix::prefix
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::@function::A
    staticType: void Function<T, U>(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: package:test/a.dart::@function::A::@parameter::a
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
      element: self::@typeAlias::X
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    staticElement: ConstructorMember
      base: self::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: self::@class::A::@constructor::named::@parameter::a
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
    await assertErrorsInCode('''
class C {}

void f() {
  C.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 3),
    ]);

    var identifier = findNode.prefixed('C.new');
    // The left side of the assignment is resolved by
    // [PropertyElementResolver._resolveTargetClassElement], which looks for
    // getters and setters on `C`, and does not recover with other elements
    // (methods, constructors). This prefixed identifier can have a real
    // `staticElement` if we add such recovery.
    assertElement(identifier, null);
  }

  test_constructorReference_inAssignment_onRightSide() async {
    await assertNoErrorsInCode('''
class C {}

Function? f;
void g() {
  f = C.new;
}
''');

    var identifier = findNode.constructorReference('C.new');
    assertElement(identifier, findElement.unnamedConstructor('C'));
  }

  // TODO(srawlins): Complete tests of all cases of rewriting (or not) a
  // prefixed identifier.
}
