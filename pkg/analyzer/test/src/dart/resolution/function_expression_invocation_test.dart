// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void call<T>(T t) {}
}

void f(A a) {
  a(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('a(0)');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  List<T> call<T>(List<T> _)  {
    throw 42;
  }
}

main(A a) {
//   ^
// [diag.mainFirstPositionalParameterType] The type of the first positional parameter of the 'main' function must be a supertype of 'List<String>'.
  a([0]);
}
''');

    var node = result.findNode.functionExpressionInvocation('a([');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a, int context) {
  context = a();
}
''');

    var node = result.findNode.functionExpressionInvocation('a()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a) {
  a<int>();
}
''');

    var node = result.findNode.functionExpressionInvocation('a<int>()');
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  (main as dynamic)(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('(0)');
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
        element: dynamic
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  (main as dynamic)<bool, int>(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('(0)');
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
        element: dynamic
        type: dynamic
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a();
}

extension on int? {
  int call() => 0;
}
''');
    var node = result.findNode.functionExpressionInvocation('();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int?
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::#0::@method::call
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_expression_recordType_hasCall_extensionMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((String,) a) {
  a();
}

extension on (String,) {
  int call() => 0;
}
''');
    var node = result.findNode.functionExpressionInvocation('();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: (String,)
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::#0::@method::call
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_expression_recordType_hasCall_namedField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var r = (call: () => 0);
  r();
//^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');
    var node = result.findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: r
    element: r@17
    staticType: ({int Function() call})
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_expression_recordType_noCall() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((String,) a) {
  a();
//^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');
    var node = result.findNode.functionExpressionInvocation('();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(T Function<T>(T a) g) {
  g(0);
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: a@23
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
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<S> = S Function<T>(T x);

void f(F<int> a) {
  a<String>('hello');
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
        element: dart:core::@class::String
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int Function() g, int a) {
  g(a);
//  ^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = String Function(int a, {int b});

class A {
  F get foo => throw 0;

  void f() {
    foo(1, b: 2);
  }
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
      NamedArgument
        name: b
        colon: :
        argumentExpression: IntegerLiteral
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.singleFunctionExpressionInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const id = identical;
const a = 0;
const b = 0;
const c = id(a, b);
//        ^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never x) {
  x<int>(1 + 2);
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//      ^^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.functionExpressionInvocation('x<int>(1 + 2)');
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Never? x) {
  x<int>(1 + 2);
//^
// [diag.uncheckedInvocationOfNullableValue] The function can't be unconditionally invoked because it can be 'null'.
}
''');

    var node = result.findNode.functionExpressionInvocation('x<int>(1 + 2)');
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo();
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('a?.foo()');
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
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  int Function() f();
}
test(A? a) => a?.f()();
''');

    var node = result.findNode.functionExpressionInvocation('a?.f()()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo().isEven;
  }
}
''');

    var node = result.findNode.propertyAccess('isEven');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  (switch (x) {
    _ => foo,
  }());
}

void foo() {}
''');

    var node = result.findNode.functionExpressionInvocation('}()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({void Function(int) foo}) r) {
  r.foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((void Function(int),) r) {
  r.$1(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((void Function(int),) r) {
  (r.$1)(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('(0)');
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
