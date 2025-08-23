// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionInvocationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionExpressionInvocationTest extends PubPackageResolutionTest {
  test_call_infer_fromArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  void call<T>(T t) {}
}

void f(A a) {
  a(0);
}
''');

    var node = findNode.functionExpressionInvocation('a(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@method::call::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: <testLibrary>::@class::A::@method::call
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_call_infer_fromArguments_listLiteral() async {
    await resolveTestCode(r'''
class A {
  List<T> call<T>(List<T> _)  {
    throw 42;
  }
}

main(A a) {
  a([0]);
}
''');

    var node = findNode.functionExpressionInvocation('a([');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::main::@formalParameter::a
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 0
            staticType: int
        rightBracket: ]
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@method::call::@formalParameter::_
          substitution: {T: int}
        staticType: List<int>
    rightParenthesis: )
  element: <testLibrary>::@class::A::@method::call
  staticInvokeType: List<int> Function(List<int>)
  staticType: List<int>
  typeArgumentTypes
    int
''');
  }

  test_call_infer_fromContext() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a, int context) {
  context = a();
}
''');

    var node = findNode.functionExpressionInvocation('a()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@class::A::@method::call
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_call_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a) {
  a<int>();
}
''');

    var node = findNode.functionExpressionInvocation('a<int>()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
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
    rightParenthesis: )
  element: <testLibrary>::@class::A::@method::call
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_dynamic_withoutTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)(0);
}
''');

    var node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: AsExpression
      expression: SimpleIdentifier
        token: main
        element: <testLibrary>::@function::main
        staticType: dynamic Function()
      asOperator: as
      type: NamedType
        name: dynamic
        element2: dynamic
        type: dynamic
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_dynamic_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)<bool, int>(0);
}
''');

    var node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: AsExpression
      expression: SimpleIdentifier
        token: main
        element: <testLibrary>::@function::main
        staticType: dynamic Function()
      asOperator: as
      type: NamedType
        name: dynamic
        element2: dynamic
        type: dynamic
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element2: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
  typeArgumentTypes
    bool
    int
''');
  }

  test_expression_interfaceType_nullable_hasCall() async {
    await assertNoErrorsInCode(r'''
void f(int? a) {
  a();
}

extension on int? {
  int call() => 0;
}
''');
    var node = findNode.functionExpressionInvocation('();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int?
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::0::@method::call
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_expression_recordType_hasCall() async {
    await assertNoErrorsInCode(r'''
void f((String,) a) {
  a();
}

extension on (String,) {
  int call() => 0;
}
''');
    var node = findNode.functionExpressionInvocation('();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: (String,)
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::0::@method::call
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_expression_recordType_noCall() async {
    await assertErrorsInCode(
      r'''
void f((String,) a) {
  a();
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 24, 1)],
    );
    var node = findNode.functionExpressionInvocation('();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: (String,)
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_formalParameter_generic() async {
    await assertNoErrorsInCode(r'''
void f(T Function<T>(T a) g) {
  g(0);
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::f::@formalParameter::g
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: a@null
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function(int)
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_formalParameter_generic_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
typedef F<S> = S Function<T>(T x);

void f(F<int> a) {
  a<String>('hello');
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int Function<T>(T)
      alias: <testLibrary>::@typeAlias::F
        typeArguments
          int
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: 'hello'
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function(String)
  staticType: int
  typeArgumentTypes
    String
''');
  }

  test_formalParameter_tooManyArguments() async {
    await assertErrorsInCode(
      r'''
void f(int Function() g, int a) {
  g(a);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 38, 1)],
    );

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::f::@formalParameter::g
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: <null>
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_getter_functionTyped() async {
    await assertNoErrorsInCode(r'''
typedef F = String Function(int a, {int b});

class A {
  F get foo => throw 0;

  void f() {
    foo(1, b: 2);
  }
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: String Function(int, {int b})
      alias: <testLibrary>::@typeAlias::F
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: a@null
        staticType: int
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            element: b@null
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 2
          staticType: int
        correspondingParameter: b@null
    rightParenthesis: )
  element: <null>
  staticInvokeType: String Function(int, {int b})
    alias: <testLibrary>::@typeAlias::F
  staticType: String
''');
  }

  test_getter_functionTyped_withSetterDeclaredLocally() async {
    await assertNoErrorsInCode('''
class A {
  Function get foo => () {};
}
class B extends A {
  set foo(Function _) {}

  void f() {
    foo();
  }
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: Function
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_invalidConst_topLevelVariable() async {
    await assertErrorsInCode(
      r'''
const id = identical;
const a = 0;
const b = 0;
const c = id(a, b);
''',
      [error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 58, 8)],
    );

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: id
    element: <testLibrary>::@getter::id
    staticType: bool Function(Object?, Object?)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: dart:core::@function::identical::@formalParameter::a
        element: <testLibrary>::@getter::a
        staticType: int
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@function::identical::@formalParameter::b
        element: <testLibrary>::@getter::b
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: bool Function(Object?, Object?)
  staticType: bool
''');
  }

  test_never() async {
    await assertErrorsInCode(
      r'''
void f(Never x) {
  x<int>(1 + 2);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 20, 1),
        error(WarningCode.deadCode, 26, 8),
      ],
    );

    var node = findNode.functionExpressionInvocation('x<int>(1 + 2)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never
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
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        element: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: Never
  staticType: Never
  typeArgumentTypes
    int
''');
  }

  test_neverQ() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  x<int>(1 + 2);
}
''',
      [error(CompileTimeErrorCode.uncheckedInvocationOfNullableValue, 21, 1)],
    );

    var node = findNode.functionExpressionInvocation('x<int>(1 + 2)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Never?
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
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
          staticType: int
        correspondingParameter: <null>
        element: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_nullShorting() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo();
  }
}
''');

    var node = findNode.functionExpressionInvocation('a?.foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@class::B::@method::bar::@formalParameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function()
  staticType: int?
''');
  }

  test_nullShorting_extended() async {
    await assertNoErrorsInCode('''
abstract class A {
  int Function() f();
}
test(A? a) => a?.f()();
''');

    var node = findNode.functionExpressionInvocation('a?.f()()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: MethodInvocation
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::test::@formalParameter::a
      staticType: A?
    operator: ?.
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::A::@method::f
      staticType: int Function() Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: int Function() Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function()
  staticType: int?
''');
  }

  test_nullShorting_extends() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo().isEven;
  }
}
''');

    var node = findNode.propertyAccess('isEven');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: FunctionExpressionInvocation
    function: PropertyAccess
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@method::bar::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: foo
        element: <testLibrary>::@class::A::@getter::foo
        staticType: int Function()
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: isEven
    element: dart:core::@class::int::@getter::isEven
    staticType: bool
  staticType: bool?
''');
  }

  test_on_switchExpression() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    _ => foo,
  }());
}

void foo() {}
''');

    var node = findNode.functionExpressionInvocation('}()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: SimpleIdentifier
          token: foo
          element: <testLibrary>::@function::foo
          staticType: void Function()
    rightBracket: }
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_record_field_named() async {
    await assertNoErrorsInCode(r'''
void f(({void Function(int) foo}) r) {
  r.foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({void Function(int) foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: void Function(int)
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_record_field_positional_rewrite() async {
    await assertNoErrorsInCode(r'''
void f((void Function(int),) r) {
  r.$1(0);
}
''');

    var node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (void Function(int),)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: void Function(int)
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_record_field_positional_withParenthesis() async {
    await assertNoErrorsInCode(r'''
void f((void Function(int),) r) {
  (r.$1)(0);
}
''');

    var node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: PropertyAccess
      target: SimpleIdentifier
        token: r
        element: <testLibrary>::@function::f::@formalParameter::r
        staticType: (void Function(int),)
      operator: .
      propertyName: SimpleIdentifier
        token: $1
        element: <null>
        staticType: void Function(int)
      staticType: void Function(int)
    rightParenthesis: )
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
  }
}
