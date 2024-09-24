// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionInvocationTest);
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::A::@method::call::@parameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@class::A::@method::call
  element: <testLibraryFragment>::@class::A::@method::call#element
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
    staticElement: <testLibraryFragment>::@function::main::@parameter::a
    element: <testLibraryFragment>::@function::main::@parameter::a#element
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
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::A::@method::call::@parameter::_
          substitution: {T: int}
        staticType: List<int>
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@class::A::@method::call
  element: <testLibraryFragment>::@class::A::@method::call#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@class::A::@method::call
  element: <testLibraryFragment>::@class::A::@method::call#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@class::A::@method::call
  element: <testLibraryFragment>::@class::A::@method::call#element
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
        staticElement: <testLibraryFragment>::@function::main
        element: <testLibraryFragment>::@function::main#element
        staticType: dynamic Function()
      asOperator: as
      type: NamedType
        name: dynamic
        element: dynamic@-1
        element2: dynamic@-1
        type: dynamic
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
        staticElement: <testLibraryFragment>::@function::main
        element: <testLibraryFragment>::@function::main#element
        staticType: dynamic Function()
      asOperator: as
      type: NamedType
        name: dynamic
        element: dynamic@-1
        element2: dynamic@-1
        type: dynamic
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::<fragment>::@class::bool
        element2: dart:core::<fragment>::@class::bool#element
        type: bool
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@extension::0::@method::call
  element: <testLibraryFragment>::@extension::0::@method::call#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: (String,)
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@extension::0::@method::call
  element: <testLibraryFragment>::@extension::0::@method::call#element
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_expression_recordType_noCall() async {
    await assertErrorsInCode(r'''
void f((String,) a) {
  a();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 24, 1),
    ]);
    var node = findNode.functionExpressionInvocation('();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: (String,)
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::g
    element: <testLibraryFragment>::@function::f::@parameter::g#element
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int Function<T>(T)
      alias: <testLibraryFragment>::@typeAlias::F
        typeArguments
          int
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
        element: dart:core::<fragment>::@class::String
        element2: dart:core::<fragment>::@class::String#element
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: 'hello'
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: int Function(String)
  staticType: int
  typeArgumentTypes
    String
''');
  }

  test_formalParameter_tooManyArguments() async {
    await assertErrorsInCode(r'''
void f(int Function() g, int a) {
  g(a);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 38, 1),
    ]);

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: g
    staticElement: <testLibraryFragment>::@function::f::@parameter::g
    element: <testLibraryFragment>::@function::f::@parameter::g#element
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        parameter: <null>
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: String Function(int, {int b})
      alias: <testLibraryFragment>::@typeAlias::F
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: root::@parameter::a
        staticType: int
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            staticElement: root::@parameter::b
            element: root::@parameter::b#element
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 2
          staticType: int
        parameter: root::@parameter::b
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: String Function(int, {int b})
    alias: <testLibraryFragment>::@typeAlias::F
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: Function
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_invalidConst_topLevelVariable() async {
    await assertErrorsInCode(r'''
const id = identical;
const a = 0;
const b = 0;
const c = id(a, b);
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 58,
          8),
    ]);

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: id
    staticElement: <testLibraryFragment>::@getter::id
    element: <testLibraryFragment>::@getter::id#element
    staticType: bool Function(Object?, Object?)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        parameter: dart:core::<fragment>::@function::identical::@parameter::a
        staticElement: <testLibraryFragment>::@getter::a
        element: <testLibraryFragment>::@getter::a#element
        staticType: int
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@function::identical::@parameter::b
        staticElement: <testLibraryFragment>::@getter::b
        element: <testLibraryFragment>::@getter::b#element
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: bool Function(Object?, Object?)
  staticType: bool
''');
  }

  test_never() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x<int>(1 + 2);
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(WarningCode.DEAD_CODE, 26, 8),
    ]);

    var node = findNode.functionExpressionInvocation('x<int>(1 + 2)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Never
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
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
          parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::<fragment>::@class::num::@method::+
        element: dart:core::<fragment>::@class::num::@method::+#element
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: Never
  staticType: Never
  typeArgumentTypes
    int
''');
  }

  test_neverQ() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x<int>(1 + 2);
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE, 21, 1),
    ]);

    var node = findNode.functionExpressionInvocation('x<int>(1 + 2)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Never?
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
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
          parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::<fragment>::@class::num::@method::+
        element: dart:core::<fragment>::@class::num::@method::+#element
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@class::B::@method::bar::@parameter::a
      element: <testLibraryFragment>::@class::B::@method::bar::@parameter::a#element
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
        staticElement: <testLibraryFragment>::@class::B::@method::bar::@parameter::a
        element: <testLibraryFragment>::@class::B::@method::bar::@parameter::a#element
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@class::A::@getter::foo
        element: <testLibraryFragment>::@class::A::@getter::foo#element
        staticType: int Function()
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: isEven
    staticElement: dart:core::<fragment>::@class::int::@getter::isEven
    element: dart:core::<fragment>::@class::int::@getter::isEven#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
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
          staticElement: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
          staticType: void Function()
    rightBracket: }
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({void Function(int) foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: void Function(int)
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (void Function(int),)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      element: <null>
      staticType: void Function(int)
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::r
        element: <testLibraryFragment>::@function::f::@parameter::r#element
        staticType: (void Function(int),)
      operator: .
      propertyName: SimpleIdentifier
        token: $1
        staticElement: <null>
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
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
  }
}
