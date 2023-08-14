// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsTest);
    defineReflectiveTests(ExtensionMethodsWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ExtensionMethodsTest extends PubPackageResolutionTest
    with ExtensionMethodsTestCases {}

mixin ExtensionMethodsTestCases on ResolutionTest {
  test_implicit_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  a.foo;
}
''');

    final node = findNode.prefixed('.foo');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A<int>
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::foo
      substitution: {T: int}
    staticType: List<int>
  staticElement: PropertyAccessorMember
    base: self::@extension::E::@getter::foo
    substitution: {T: int}
  staticType: List<int>
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A<int*>*
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::foo
      substitution: {T: int*}
    staticType: List<int*>*
  staticElement: PropertyAccessorMember
    base: self::@extension::E::@getter::foo
    substitution: {T: int*}
  staticType: List<int*>*
''');
    }
  }

  test_implicit_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  a.foo(1.0);
}
''');

    final node = findNode.singleMethodInvocation;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A<int>
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int, U: U}
    staticType: Map<int, U> Function<U>(U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DoubleLiteral
        literal: 1.0
        parameter: ParameterMember
          base: root::@parameter::u
          substitution: {U: double}
        staticType: double
    rightParenthesis: )
  staticInvokeType: Map<int, double> Function(double)
  staticType: Map<int, double>
  typeArgumentTypes
    double
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A<int*>*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int*, U: U}
    staticType: Map<int*, U*>* Function<U>(U*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DoubleLiteral
        literal: 1.0
        parameter: ParameterMember
          base: root::@parameter::u
          substitution: {U: double*}
        staticType: double*
    rightParenthesis: )
  staticInvokeType: Map<int*, double*>* Function(double*)*
  staticType: Map<int*, double*>*
  typeArgumentTypes
    double*
''');
    }
  }

  test_implicit_method_internal() async {
    await assertNoErrorsInCode(r'''
extension E<T> on List<T> {
  List<T> foo() => this;
  List<T> bar(List<T> other) => other.foo();
}
''');

    var node = findNode.methodInvocation('other.foo()');
    if (result.libraryElement.isNonNullableByDefault) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: other
    staticElement: self::@extension::E::@method::bar::@parameter::other
    staticType: List<T>
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: T}
    staticType: List<T> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: List<T> Function()
  staticType: List<T>
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: other
    staticElement: self::@extension::E::@method::bar::@parameter::other
    staticType: List<T*>*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: T*}
    staticType: List<T*>* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: List<T*>* Function()*
  staticType: List<T*>*
''');
    }
  }

  test_implicit_method_onTypeParameter() async {
    await assertNoErrorsInCode('''
extension E<T> on T {
  Map<T, U> foo<U>(U value) => <T, U>{};
}

void f(String a) {
  a.foo(0);
}
''');

    final node = findNode.singleMethodInvocation;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: String
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: String, U: U}
    staticType: Map<String, U> Function<U>(U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::value
          substitution: {U: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: Map<String, int> Function(int)
  staticType: Map<String, int>
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: String*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: String*, U: U}
    staticType: Map<String*, U*>* Function<U>(U*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::value
          substitution: {U: int*}
        staticType: int*
    rightParenthesis: )
  staticInvokeType: Map<String*, int*>* Function(int*)*
  staticType: Map<String*, int*>*
  typeArgumentTypes
    int*
''');
    }
  }

  test_implicit_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  a.foo;
}
''');

    final node = findNode.prefixed('foo;');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A<int>
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int, U: U}
    staticType: Map<int, U> Function<U>(U)
  staticElement: MethodMember
    base: self::@extension::E::@method::foo
    substitution: {T: int, U: U}
  staticType: Map<int, U> Function<U>(U)
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A<int*>*
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int*, U: U}
    staticType: Map<int*, U*>* Function<U>(U*)*
  staticElement: MethodMember
    base: self::@extension::E::@method::foo
    substitution: {T: int*, U: U}
  staticType: Map<int*, U*>* Function<U>(U*)*
''');
    }
  }

  test_implicit_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  a.foo = 0;
}
''');
    var assignment = findNode.assignment('foo =');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A<int>
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: self::@extension::E::@setter::foo::@parameter::value
      substitution: {T: int}
    staticType: int
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::foo
    substitution: {T: int}
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A<int*>*
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: self::@extension::E::@setter::foo::@parameter::value
      substitution: {T: int*}
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::foo
    substitution: {T: int*}
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_implicit_targetTypeParameter_hasBound_methodInvocation() async {
    await assertNoErrorsInCode('''
extension Test<T> on T {
  T Function(T) test() => throw 0;
}

void f<S extends num>(S x) {
  x.test();
}
''');

    var node = findNode.methodInvocation('test();');
    if (result.libraryElement.isNonNullableByDefault) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: S
  operator: .
  methodName: SimpleIdentifier
    token: test
    staticElement: MethodMember
      base: self::@extension::Test::@method::test
      substitution: {T: S}
    staticType: S Function(S) Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: S Function(S) Function()
  staticType: S Function(S)
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: S*
  operator: .
  methodName: SimpleIdentifier
    token: test
    staticElement: MethodMember
      base: self::@extension::Test::@method::test
      substitution: {T: num*}
    staticType: num* Function(num*)* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: num* Function(num*)* Function()*
  staticType: num* Function(num*)*
''');
    }
  }

  test_implicit_targetTypeParameter_hasBound_propertyAccess_getter() async {
    await assertNoErrorsInCode('''
extension Test<T> on T {
  T Function(T) get test => throw 0;
}

void f<S extends num>(S x) {
  (x).test;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: S
    rightParenthesis: )
    staticType: S
  operator: .
  propertyName: SimpleIdentifier
    token: test
    staticElement: PropertyAccessorMember
      base: self::@extension::Test::@getter::test
      substitution: {T: S}
    staticType: S Function(S)
  staticType: S Function(S)
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: S*
    rightParenthesis: )
    staticType: S*
  operator: .
  propertyName: SimpleIdentifier
    token: test
    staticElement: PropertyAccessorMember
      base: self::@extension::Test::@getter::test
      substitution: {T: num*}
    staticType: num* Function(num*)*
  staticType: num* Function(num*)*
''');
    }
  }

  test_implicit_targetTypeParameter_hasBound_propertyAccess_setter() async {
    await assertNoErrorsInCode('''
extension Test<T> on T {
  void set test(T _) {}
}

T g<T>() => throw 0;

void f<S extends num>(S x) {
  (x).test = g();
}
''');

    var assignment = findNode.assignment('(x).test');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
        staticElement: self::@function::f::@parameter::x
        staticType: S
      rightParenthesis: )
      staticType: S
    operator: .
    propertyName: SimpleIdentifier
      token: test
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      staticElement: self::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: ParameterMember
      base: self::@extension::Test::@setter::test::@parameter::_
      substitution: {T: S}
    staticInvokeType: S Function()
    staticType: S
    typeArgumentTypes
      S
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::Test::@setter::test
    substitution: {T: S}
  writeType: S
  staticElement: <null>
  staticType: S
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
        staticElement: self::@function::f::@parameter::x
        staticType: S*
      rightParenthesis: )
      staticType: S*
    operator: .
    propertyName: SimpleIdentifier
      token: test
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      staticElement: self::@function::g
      staticType: T* Function<T>()*
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: ParameterMember
      base: self::@extension::Test::@setter::test::@parameter::_
      substitution: {T: num*}
    staticInvokeType: num* Function()*
    staticType: num*
    typeArgumentTypes
      num*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::Test::@setter::test
    substitution: {T: num*}
  writeType: num*
  staticElement: <null>
  staticType: num*
''');
    }
  }

  test_override_downward_hasTypeArguments() async {
    await assertNoErrorsInCode('''
extension E<T> on Set<T> {
  void foo() {}
}

main() {
  E<int>({}).foo();
}
''');
    var literal = findNode.setOrMapLiteral('{}).');
    assertType(literal, 'Set<int>');
  }

  test_override_downward_hasTypeArguments_wrongNumber() async {
    await assertErrorsInCode('''
extension E<T> on Set<T> {
  void foo() {}
}

main() {
  E<int, bool>({}).foo();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION, 58,
          11),
    ]);
    var literal = findNode.setOrMapLiteral('{}).');
    assertType(literal, 'Set<dynamic>');
  }

  test_override_downward_noTypeArguments() async {
    await assertNoErrorsInCode('''
extension E<T> on Set<T> {
  void foo() {}
}

main() {
  E({}).foo();
}
''');
    var literal = findNode.setOrMapLiteral('{}).');
    assertType(literal, 'Set<dynamic>');
  }

  test_override_hasTypeArguments_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  E<num>(a).foo;
}
''');

    final node = findNode.propertyAccess('.foo');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: num
          element: dart:core::@class::num
          type: num
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int>
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<num>
    staticType: null
    typeArgumentTypes
      num
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::foo
      substitution: {T: num}
    staticType: List<num>
  staticType: List<num>
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: num
          element: dart:core::@class::num
          type: num*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int*>*
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<num*>*
    staticType: null
    typeArgumentTypes
      num*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::foo
      substitution: {T: num*}
    staticType: List<num*>*
  staticType: List<num*>*
''');
    }
  }

  test_override_hasTypeArguments_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E<num>(a).foo(1.0);
}
''');

    final node = findNode.singleMethodInvocation;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: num
          element: dart:core::@class::num
          type: num
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int>
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<num>
    staticType: null
    typeArgumentTypes
      num
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: num, U: U}
    staticType: Map<num, U> Function<U>(U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DoubleLiteral
        literal: 1.0
        parameter: ParameterMember
          base: root::@parameter::u
          substitution: {U: double}
        staticType: double
    rightParenthesis: )
  staticInvokeType: Map<num, double> Function(double)
  staticType: Map<num, double>
  typeArgumentTypes
    double
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: num
          element: dart:core::@class::num
          type: num*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int*>*
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<num*>*
    staticType: null
    typeArgumentTypes
      num*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: num*, U: U}
    staticType: Map<num*, U*>* Function<U>(U*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DoubleLiteral
        literal: 1.0
        parameter: ParameterMember
          base: root::@parameter::u
          substitution: {U: double*}
        staticType: double*
    rightParenthesis: )
  staticInvokeType: Map<num*, double*>* Function(double*)*
  staticType: Map<num*, double*>*
  typeArgumentTypes
    double*
''');
    }
  }

  test_override_hasTypeArguments_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E<num>(a).foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: num
          element: dart:core::@class::num
          type: num
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int>
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<num>
    staticType: null
    typeArgumentTypes
      num
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: num, U: U}
    staticType: Map<num, U> Function<U>(U)
  staticType: Map<num, U> Function<U>(U)
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: num
          element: dart:core::@class::num
          type: num*
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int*>*
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<num*>*
    staticType: null
    typeArgumentTypes
      num*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: num*, U: U}
    staticType: Map<num*, U*>* Function<U>(U*)*
  staticType: Map<num*, U*>* Function<U>(U*)*
''');
    }
  }

  test_override_hasTypeArguments_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  E<num>(a).foo = 1.2;
}
''');

    var assignment = findNode.assignment('foo =');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: num
            element: dart:core::@class::num
            type: num
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A<int>
        rightParenthesis: )
      element: self::@extension::E
      extendedType: A<num>
      staticType: null
      typeArgumentTypes
        num
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: ParameterMember
      base: self::@extension::E::@setter::foo::@parameter::value
      substitution: {T: num}
    staticType: double
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::foo
    substitution: {T: num}
  writeType: num
  staticElement: <null>
  staticType: double
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: num
            element: dart:core::@class::num
            type: num*
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A<int*>*
        rightParenthesis: )
      element: self::@extension::E
      extendedType: A<num*>*
      staticType: null
      typeArgumentTypes
        num*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: ParameterMember
      base: self::@extension::E::@setter::foo::@parameter::value
      substitution: {T: num*}
    staticType: double*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::foo
    substitution: {T: num*}
  writeType: num*
  staticElement: <null>
  staticType: double*
''');
    }
  }

  test_override_inferTypeArguments_error_couldNotInfer() async {
    await assertErrorsInCode('''
extension E<T extends num> on T {
  void foo() {}
}

f(String s) {
  E(s).foo();
}
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 69, 1),
    ]);
    var override = findNode.extensionOverride('E(s)');
    assertElementTypes(override.typeArgumentTypes, ['String']);
    assertType(override.extendedType, 'String');
  }

  test_override_inferTypeArguments_getter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  List<T> get foo => <T>[];
}

void f(A<int> a) {
  E(a).foo;
}
''');

    final node = findNode.propertyAccess('.foo');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int>
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<int>
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::foo
      substitution: {T: int}
    staticType: List<int>
  staticType: List<int>
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int*>*
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<int*>*
    staticType: null
    typeArgumentTypes
      int*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: self::@extension::E::@getter::foo
      substitution: {T: int*}
    staticType: List<int*>*
  staticType: List<int*>*
''');
    }
  }

  test_override_inferTypeArguments_method() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E(a).foo(1.0);
}
''');

    final node = findNode.singleMethodInvocation;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int>
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<int>
    staticType: null
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int, U: U}
    staticType: Map<int, U> Function<U>(U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DoubleLiteral
        literal: 1.0
        parameter: ParameterMember
          base: root::@parameter::u
          substitution: {U: double}
        staticType: double
    rightParenthesis: )
  staticInvokeType: Map<int, double> Function(double)
  staticType: Map<int, double>
  typeArgumentTypes
    double
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int*>*
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<int*>*
    staticType: null
    typeArgumentTypes
      int*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int*, U: U}
    staticType: Map<int*, U*>* Function<U>(U*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      DoubleLiteral
        literal: 1.0
        parameter: ParameterMember
          base: root::@parameter::u
          substitution: {U: double*}
        staticType: double*
    rightParenthesis: )
  staticInvokeType: Map<int*, double*>* Function(double*)*
  staticType: Map<int*, double*>*
  typeArgumentTypes
    double*
''');
    }
  }

  test_override_inferTypeArguments_method_tearOff() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  Map<T, U> foo<U>(U u) => <T, U>{};
}

void f(A<int> a) {
  E(a).foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int>
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<int>
    staticType: null
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int, U: U}
    staticType: Map<int, U> Function<U>(U)
  staticType: Map<int, U> Function<U>(U)
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A<int*>*
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A<int*>*
    staticType: null
    typeArgumentTypes
      int*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int*, U: U}
    staticType: Map<int*, U*>* Function<U>(U*)*
  staticType: Map<int*, U*>* Function<U>(U*)*
''');
    }
  }

  test_override_inferTypeArguments_setter() async {
    await assertNoErrorsInCode('''
class A<T> {}

extension E<T> on A<T> {
  set foo(T value) {}
}

void f(A<int> a) {
  E(a).foo = 0;
}
''');

    if (isNullSafetyEnabled) {
      assertResolvedNodeText(findNode.assignment('foo ='), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A<int>
        rightParenthesis: )
      element: self::@extension::E
      extendedType: A<int>
      staticType: null
      typeArgumentTypes
        int
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: self::@extension::E::@setter::foo::@parameter::value
      substitution: {T: int}
    staticType: int
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::foo
    substitution: {T: int}
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(findNode.assignment('foo ='), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::f::@parameter::a
            staticType: A<int*>*
        rightParenthesis: )
      element: self::@extension::E
      extendedType: A<int*>*
      staticType: null
      typeArgumentTypes
        int*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: self::@extension::E::@setter::foo::@parameter::value
      substitution: {T: int*}
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: self::@extension::E::@setter::foo
    substitution: {T: int*}
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }
}

@reflectiveTest
class ExtensionMethodsWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, ExtensionMethodsTestCases {}
