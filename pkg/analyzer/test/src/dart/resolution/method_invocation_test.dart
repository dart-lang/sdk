// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodInvocationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MethodInvocationResolutionTest extends PubPackageResolutionTest {
  test_arguments_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    g(super);
  }
}

void g(Object a) {}
''',
      [error(ParserErrorCode.missingAssignableSelector, 29, 5)],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: void Function(Object)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SuperExpression
        superKeyword: super
        staticType: A
    rightParenthesis: )
  staticInvokeType: void Function(Object)
  staticType: void
''');
  }

  test_arguments_synthetics() async {
    await assertErrorsInCode(
      r'''
void f() {
  g(,,);
}

void g(int a, int b) {}
''',
      [
        error(ParserErrorCode.missingIdentifier, 15, 1),
        error(ParserErrorCode.missingIdentifier, 16, 1),
      ],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: void Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: <empty> <synthetic>
        correspondingParameter: <testLibrary>::@function::g::@formalParameter::a
        element: <null>
        staticType: InvalidType
      SimpleIdentifier
        token: <empty> <synthetic>
        correspondingParameter: <testLibrary>::@function::g::@formalParameter::b
        element: <null>
        staticType: InvalidType
    rightParenthesis: )
  staticInvokeType: void Function(int, int)
  staticType: void
''');
  }

  test_cascadeExpression() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
  void bar() {}
}

void f(A a) {
  a..foo()..bar();
}
''');

    var node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  cascadeSections
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
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: bar
        element: <testLibrary>::@class::A::@method::bar
        staticType: void Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: void Function()
      staticType: void
  staticType: A
''');
  }

  test_clamp_double_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''');

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    element: <testLibrary>::@function::h
    staticType: dynamic Function(double)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::g::@formalParameter::a
          staticType: double
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          element: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
              staticInvokeType: double Function()
              staticType: double
              typeArgumentTypes
                double
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
              staticInvokeType: double Function()
              staticType: double
              typeArgumentTypes
                double
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@function::h::@formalParameter::x
        staticInvokeType: num Function(num, num)
        staticType: double
    rightParenthesis: )
  staticInvokeType: dynamic Function(double)
  staticType: dynamic
''');
  }

  test_clamp_double_context_int() async {
    await assertErrorsInCode(
      '''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 45, 17)],
    );

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    element: <testLibrary>::@function::h
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::g::@formalParameter::a
          staticType: double
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          element: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@function::h::@formalParameter::x
        staticInvokeType: num Function(num, num)
        staticType: num
    rightParenthesis: )
  staticInvokeType: dynamic Function(int)
  staticType: dynamic
''');
  }

  test_clamp_double_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  a.clamp(f(), f());
}
''');

    var node = findNode.methodInvocation('a.clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          element: <testLibrary>::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          element: <testLibrary>::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_double_double_double() async {
    await assertNoErrorsInCode('''
f(double a, double b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: double
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: double
''');
  }

  test_clamp_double_double_int() async {
    await assertNoErrorsInCode('''
f(double a, double b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: double
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_double_int_double() async {
    await assertNoErrorsInCode('''
f(double a, int b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_double_int_int() async {
    await assertNoErrorsInCode('''
f(double a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_context_double() async {
    await assertErrorsInCode(
      '''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 42, 17)],
    );

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    element: <testLibrary>::@function::h
    staticType: dynamic Function(double)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::g::@formalParameter::a
          staticType: int
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          element: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@function::h::@formalParameter::x
        staticInvokeType: num Function(num, num)
        staticType: num
    rightParenthesis: )
  staticInvokeType: dynamic Function(double)
  staticType: dynamic
''');
  }

  test_clamp_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    element: <testLibrary>::@function::h
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::g::@formalParameter::a
          staticType: int
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          element: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
              staticInvokeType: int Function()
              staticType: int
              typeArgumentTypes
                int
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
              staticInvokeType: int Function()
              staticType: int
              typeArgumentTypes
                int
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@function::h::@formalParameter::x
        staticInvokeType: num Function(num, num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic Function(int)
  staticType: dynamic
''');
  }

  test_clamp_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a.clamp(f(), f());
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          element: <testLibrary>::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          element: <testLibrary>::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_double_double() async {
    await assertNoErrorsInCode('''
f(int a, double b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: double
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_double_dynamic() async {
    await assertNoErrorsInCode('''
f(int a, double b, dynamic c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: double
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_double_int() async {
    await assertNoErrorsInCode('''
f(int a, double b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: double
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_dynamic_double() async {
    await assertNoErrorsInCode('''
f(int a, dynamic b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: dynamic
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_dynamic_int() async {
    await assertNoErrorsInCode('''
f(int a, dynamic b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: dynamic
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_int_double() async {
    await assertNoErrorsInCode('''
f(int a, int b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_int_dynamic() async {
    await assertNoErrorsInCode('''
f(int a, int b, dynamic c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_int_int() async {
    await assertNoErrorsInCode('''
f(int a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: int
''');
  }

  test_clamp_int_int_int_from_cascade() async {
    await assertNoErrorsInCode('''
f(int a, int b, int c) {
  a..clamp(b, c).isEven;
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: int
''');
  }

  test_clamp_int_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
extension E on int {
  String clamp(int x, int y) => '';
}
f(int a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: <testLibrary>::@extension::E::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: <testLibrary>::@extension::E::@method::clamp::@formalParameter::x
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: <testLibrary>::@extension::E::@method::clamp::@formalParameter::y
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
  }

  test_clamp_int_int_never() async {
    await assertNoErrorsInCode('''
f(int a, int b, Never c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: Never
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_never_int() async {
    await assertErrorsInCode(
      '''
f(int a, Never b, int c) {
  a.clamp(b, c);
}
''',
      [error(WarningCode.deadCode, 40, 3)],
    );

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::lowerLimit
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: Never
      SimpleIdentifier
        token: c
        correspondingParameter: dart:core::@class::num::@method::clamp::@formalParameter::upperLimit
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_never_int_int() async {
    await assertErrorsInCode(
      '''
f(Never a, int b, int c) {
  a.clamp(b, c);
}
''',
      [
        error(WarningCode.receiverOfTypeNever, 29, 1),
        error(WarningCode.deadCode, 36, 7),
      ],
    );

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: <null>
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: <null>
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_clamp_other_context_int() async {
    await assertErrorsInCode(
      '''
abstract class A {
  num clamp(String x, String y);
}
T f<T>() => throw Error();
g(A a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 94, 17)],
    );

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    element: <testLibrary>::@function::h
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::g::@formalParameter::a
          staticType: A
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          element: <testLibrary>::@class::A::@method::clamp
          staticType: num Function(String, String)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: <testLibrary>::@class::A::@method::clamp::@formalParameter::x
              staticInvokeType: String Function()
              staticType: String
              typeArgumentTypes
                String
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                element: <testLibrary>::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              correspondingParameter: <testLibrary>::@class::A::@method::clamp::@formalParameter::y
              staticInvokeType: String Function()
              staticType: String
              typeArgumentTypes
                String
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@function::h::@formalParameter::x
        staticInvokeType: num Function(String, String)
        staticType: num
    rightParenthesis: )
  staticInvokeType: dynamic Function(int)
  staticType: dynamic
''');
  }

  test_clamp_other_int_int() async {
    await assertNoErrorsInCode('''
abstract class A {
  String clamp(int x, int y);
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: <testLibrary>::@class::A::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: <testLibrary>::@class::A::@method::clamp::@formalParameter::x
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: <testLibrary>::@class::A::@method::clamp::@formalParameter::y
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
  }

  test_clamp_other_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
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
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: <testLibrary>::@extension::E::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: <testLibrary>::@extension::E::@method::clamp::@formalParameter::x
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: <testLibrary>::@extension::E::@method::clamp::@formalParameter::y
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
  }

  test_clamp_other_int_int_via_extension_implicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    element: <testLibrary>::@extension::E::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: <testLibrary>::@extension::E::@method::clamp::@formalParameter::x
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      SimpleIdentifier
        token: c
        correspondingParameter: <testLibrary>::@extension::E::@method::clamp::@formalParameter::y
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_explicitThis_inAugmentation_augmentationDeclares() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  void foo() {}

  void f() {
    this.foo();
  }
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

void foo() {}

class A {}
''');

    await resolveFile2(a);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_explicitThis_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

void foo() {}

class A {
  void f() {
    this.foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_implicitStatic_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

void foo() {}

class A {
  void f() {
    foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_implicitThis_inDeclaration_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  void foo() {}

  void f() {
    foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@methodAugmentation::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_implicitThis_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

void foo() {}

class A {
  void f() {
    foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_demoteType() async {
    await assertNoErrorsInCode(r'''
void test<T>(T t) {}

void f<S>(S s) {
  if (s is int) {
    test(s);
  }
}

''');

    var node = findNode.methodInvocation('test(s)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: test
    element: <testLibrary>::@function::test
    staticType: void Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::test::@formalParameter::t
          substitution: {T: S}
        element: <testLibrary>::@function::f::@formalParameter::s
        staticType: S & int
    rightParenthesis: )
  staticInvokeType: void Function(S)
  staticType: void
  typeArgumentTypes
    S
''');
  }

  test_error_ambiguousImport_topFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(int _) {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
void foo(int _) {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
}
''',
      [error(CompileTimeErrorCode.ambiguousImport, 46, 3)],
    );

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: multiplyDefinedElement
      package:test/a.dart::@function::foo
      package:test/b.dart::@function::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@function::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_error_ambiguousImport_topFunction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(int _) {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
void foo(int _) {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
}
''',
      [error(CompileTimeErrorCode.ambiguousImport, 58, 3)],
    );

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix2::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: multiplyDefinedElement
      package:test/a.dart::@function::foo
      package:test/b.dart::@function::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@function::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_error_instanceAccessToStaticMember_method() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo(int _) {}
}

void f(A a) {
  a.foo(0);
}
''',
      [error(CompileTimeErrorCode.instanceAccessToStaticMember, 59, 3)],
    );

    var node = findNode.methodInvocation('a.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
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

  test_error_invocationOfNonFunction_interface_hasCall_field() async {
    await assertErrorsInCode(
      r'''
class C {
  void Function() call = throw Error();
}

void f(C c) {
  c();
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 69, 1)],
    );

    var node = findNode.functionExpressionInvocation('c();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_instance() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;
}

void f(C c) {
  c.foo();
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@getter::foo
      staticType: dynamic
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  var foo;
}

class B extends A {
  main() {
    foo();
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;

  main() {
    foo();
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_invocationOfNonFunction_OK_Function() async {
    await assertNoErrorsInCode(r'''
f(Function foo) {
  foo(1, 2);
}
''');

    var node = findNode.functionExpressionInvocation('foo(1, 2);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::f::@formalParameter::foo
    staticType: Function
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_invocationOfNonFunction_OK_functionTypeTypeParameter() async {
    await assertNoErrorsInCode(r'''
typedef MyFunction = double Function(int _);

class C<T extends MyFunction> {
  T foo;
  C(this.foo);

  main() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: T
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: _@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
    alias: <testLibrary>::@typeAlias::MyFunction
  staticType: double
''');
  }

  test_error_invocationOfNonFunction_parameter() async {
    await assertErrorsInCode(
      r'''
main(Object foo) {
  foo();
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 21, 3)],
    );

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::main::@formalParameter::foo
    staticType: Object
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_invocationOfNonFunction_parameter_dynamic() async {
    await assertNoErrorsInCode(r'''
main(var foo) {
  foo();
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::main::@formalParameter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_invocationOfNonFunction_static_hasTarget() async {
    await assertErrorsInCode(
      r'''
class C {
  static int foo = 0;
}

main() {
  C.foo();
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 46, 5)],
    );

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@getter::foo
      staticType: int
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_invocationOfNonFunction_static_noTarget() async {
    await assertErrorsInCode(
      r'''
class C {
  static int foo = 0;

  main() {
    foo();
  }
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 48, 3)],
    );

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_invocationOfNonFunction_super_getter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
  }
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 68, 9)],
    );

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_prefixIdentifierNotFollowedByDot() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 39, 6)],
    );

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix2::prefix
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@function::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_error_prefixIdentifierNotFollowedByDot_deferred() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 49, 4)],
    );

    var node = findNode.methodInvocation('loadLibrary()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: loadLibrary
    element: dart:math::@function::loadLibrary
    staticType: Future<dynamic> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>?
''');
  }

  test_error_prefixIdentifierNotFollowedByDot_invoke() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as foo;

main() {
  foo();
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 39, 3)],
    );

    var node = findNode.methodInvocation('foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibraryFragment>::@prefix2::foo
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedFunction() async {
    await assertErrorsInCode(
      r'''
main() {
  foo(0);
}
''',
      [error(CompileTimeErrorCode.undefinedFunction, 11, 3)],
    );

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedFunction_hasTarget_importPrefix() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as math;

main() {
  math.foo(0);
}
''',
      [error(CompileTimeErrorCode.undefinedFunction, 45, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedIdentifier_target() async {
    await assertErrorsInCode(
      r'''
main() {
  bar.foo(0);
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 11, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: bar
    element: <null>
    staticType: InvalidType
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_hasTarget_class() async {
    await assertErrorsInCode(
      r'''
class C {}
main() {
  C.foo(0);
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 24, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_hasTarget_class_arguments() async {
    await assertErrorsInCode(
      r'''
class C {}

int x = 0;
main() {
  C.foo(x);
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 36, 3)],
    );

    var node = findNode.methodInvocation('foo(x);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: x
        correspondingParameter: <null>
        element: <testLibrary>::@getter::x
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_hasTarget_class_inSuperclass() async {
    await assertErrorsInCode(
      r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 76, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_hasTarget_class_typeArguments() async {
    await assertErrorsInCode(
      r'''
class C {}

main() {
  C.foo<int>();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 25, 3)],
    );

    var node = findNode.methodInvocation('foo<int>();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
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
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_error_undefinedMethod_hasTarget_class_typeParameter() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  static main() => C.T();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 34, 1)],
    );

    var node = findNode.methodInvocation('C.T();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: T
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_hasTarget_instance() async {
    await assertErrorsInCode(
      r'''
main() {
  42.foo(0);
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 14, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 42
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_hasTarget_localVariable_function() async {
    await assertErrorsInCode(
      r'''
main() {
  var v = () {};
  v.foo(0);
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 30, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: v
    element: v@15
    staticType: Null Function()
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_noTarget() async {
    await assertErrorsInCode(
      r'''
class C {
  main() {
    foo(0);
  }
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 25, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_null() async {
    await assertErrorsInCode(
      r'''
main() {
  null.foo();
}
''',
      [error(CompileTimeErrorCode.invalidUseOfNullValue, 16, 3)],
    );

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: NullLiteral
    literal: null
    staticType: Null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_object_call() async {
    await assertErrorsInCode(
      r'''
main(Object o) {
  o.call();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 21, 4)],
    );
  }

  test_error_undefinedMethod_private() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo(int _) {}
}
''');
    await assertErrorsInCode(
      r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
  }
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 53, 4)],
    );

    var node = findNode.methodInvocation('_foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: _foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(
      r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 50, 3)],
    );
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    await assertErrorsInCode(
      r'''
class A {}
main() {
  A?.toString();
}
''',
      [
        error(StaticWarningCode.invalidNullAwareOperator, 23, 2),
        error(CompileTimeErrorCode.undefinedMethod, 25, 8),
      ],
    );
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
  }
}
''',
      [
        error(
          CompileTimeErrorCode.unqualifiedReferenceToNonLocalStaticMember,
          71,
          3,
        ),
        error(CompileTimeErrorCode.extraPositionalArguments, 75, 1),
      ],
    );

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'missing.dart' as p;

main() {
  p.foo(1);
  p.bar(2);
}
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 14)],
    );

    var node = findNode.methodInvocation('foo(1);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix2::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_show() async {
    await assertErrorsInCode(
      r'''
import 'missing.dart' show foo, bar;

main() {
  foo(1);
  bar(2);
}
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 14)],
    );

    var node = findNode.methodInvocation('foo(1);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_useOfVoidResult_name_getter() async {
    await assertErrorsInCode(
      '''
class C<T>{
  T foo;
  C(this.foo);
}

void f(C<void> c) {
  c.foo();
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 61, 5)],
    );

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C<void>
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: GetterMember
        baseElement: <testLibrary>::@class::C::@getter::foo
        substitution: {T: void}
      staticType: void
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_useOfVoidResult_name_localVariable() async {
    await assertErrorsInCode(
      r'''
main() {
  void foo;
  foo();
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 23, 3)],
    );

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: foo@16
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_useOfVoidResult_name_topFunction() async {
    await assertErrorsInCode(
      r'''
void foo() {}

main() {
  foo()();
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 26, 3)],
    );

    var node = findNode.methodInvocation('foo()()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_error_useOfVoidResult_name_topVariable() async {
    await assertErrorsInCode(
      r'''
void foo;

main() {
  foo();
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 22, 3)],
    );

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_useOfVoidResult_receiver() async {
    await assertErrorsInCode(
      r'''
main() {
  void foo;
  foo.toString();
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 23, 3)],
    );

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: foo@16
    staticType: void
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_useOfVoidResult_receiver_cascade() async {
    await assertErrorsInCode(
      r'''
main() {
  void foo;
  foo..toString();
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 23, 3)],
    );

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_useOfVoidResult_receiver_withNull() async {
    await assertErrorsInCode(
      r'''
main() {
  void foo;
  foo?.toString();
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 23, 3)],
    );

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: foo@16
    staticType: void
  operator: ?.
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_01() async {
    await assertErrorsInCode(
      r'''
void foo() {}

main() {
  foo<int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod, 29, 5)],
    );

    var node = findNode.methodInvocation('foo<int>()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function()
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
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_21() async {
    await assertErrorsInCode(
      r'''
Map<T, U> foo<T extends num, U>() => throw Error();

main() {
  foo<int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod, 67, 5)],
    );

    var node = findNode.methodInvocation('foo<int>()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: Map<T, U> Function<T extends num, U>()
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
  staticInvokeType: Map<dynamic, dynamic> Function()
  staticType: Map<dynamic, dynamic>
  typeArgumentTypes
    dynamic
    dynamic
''');
  }

  test_expression_functionType_explicitCall() async {
    await assertNoErrorsInCode(r'''
void f(double Function(int p) g) {
  g.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::f::@formalParameter::g
    staticType: double Function(int)
  operator: .
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: p@null
        staticType: int
    rightParenthesis: )
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_expression_interfaceType_explicitCall() async {
    await assertNoErrorsInCode(r'''
class C {
  double call(int p) => 0.0;
}

void f(C c) {
  c.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: call
    element: <testLibrary>::@class::C::@method::call
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::C::@method::call::@formalParameter::p
        staticType: int
    rightParenthesis: )
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_extensionType_explicitThis() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  void foo() {}

  void f() {
    this.foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_extensionType_implicitThis() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  void foo() {}

  void f() {
    foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_class_staticGetter() async {
    await assertNoErrorsInCode(r'''
class C {
  static double Function(int) get foo => throw Error();
}

main() {
  C.foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_hasReceiver_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  static void foo(int _) {}
}

main() {
  C.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::C::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_className_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  static void foo() {}
}

void f() {
  A.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibrary>::@class::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@methodAugmentation::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_className_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f() {
  A.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibrary>::@class::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary();
}
''',
      [error(WarningCode.unusedImport, 7, 11)],
    );

    var node = findNode.methodInvocation('loadLibrary()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    element: dart:math::@function::loadLibrary
    staticType: Future<dynamic> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>
''');
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary_extraArgument() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary(1 + 2);
}
''',
      [
        error(WarningCode.unusedImport, 7, 11),
        error(CompileTimeErrorCode.extraPositionalArguments, 66, 5),
      ],
    );

    var node = findNode.methodInvocation('loadLibrary(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    element: dart:math::@function::loadLibrary
    staticType: Future<dynamic> Function()
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
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>
''');
  }

  test_hasReceiver_dynamic_hash() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a.hash(0, 1);
}
''');

    var node = findNode.methodInvocation('hash(');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: hash
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
      IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_extension_staticGetter() async {
    await assertNoErrorsInCode(r'''
extension A on int {
  static double Function(int) get foo => throw Error();
}

void f() {
  A.foo(0);
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: A
      element: <testLibrary>::@extension::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::A::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_extension_staticGetter_inAugmentation() async {
    await assertNoErrorsInCode(r'''
extension A on int {}

augment extension A {
  static double Function(int) get foo => throw Error();
}

void f() {
  A.foo(0);
}
''');

    var node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@extension::A
      element: <testLibrary>::@extension::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extensionAugmentation::A::@getter::foo
      element: <testLibraryFragment>::@extensionAugmentation::A::@getter::foo#element
      staticType: double Function(int)
    staticType: double Function(int)
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
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_hasReceiver_extension_staticMethod() async {
    await assertNoErrorsInCode(r'''
extension A on int {
  static void foo(int _) {}
}

void f() {
  A.foo(0);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@extension::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extension::A::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_extension_staticMethod_inAugmentation() async {
    await assertNoErrorsInCode(r'''
extension A on int {}

augment extension A {
  static void foo(int _) {}
}

void f() {
  A.foo(0);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@extension::A
    element: <testLibrary>::@extension::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionAugmentation::A::@method::foo
    element: <testLibraryFragment>::@extensionAugmentation::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@extensionAugmentation::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_extensionTypeName() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_functionTyped() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function(int)
  operator: .
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_functionTyped_generic() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T _) {}

main() {
  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T)
  operator: .
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::_
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_hasReceiver_importPrefix_topFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
T foo<T extends num>(T a, T b) => a;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var node = findNode.methodInvocation('foo(1, 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix2::prefix
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@function::foo
    staticType: T Function<T extends num>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@function::foo::@formalParameter::a
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::@function::foo::@formalParameter::b
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int, int)
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_hasReceiver_importPrefix_topGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
T Function<T>(T a, T b) get foo => null;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var node = findNode.functionExpressionInvocation('foo(1, 2);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@getter::foo
      staticType: T Function<T>(T, T)
    element: package:test/a.dart::@getter::foo
    staticType: T Function<T>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: a@null
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: b@null
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function(int, int)
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_hasReceiver_instance_Function_call_localVariable() async {
    await assertNoErrorsInCode(r'''
void f(Function getFunction()) {
  Function foo = getFunction();

  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: foo@44
    staticType: Function
  operator: .
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_instance_Function_call_topVariable() async {
    await assertNoErrorsInCode(r'''
Function foo = throw Error();

void main() {
  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: Function
  operator: .
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_instance_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => throw Error();
}

void f(C c) {
  c.foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  /// It is important to use this expression as an initializer of a top-level
  /// variable, because of the way top-level inference works, at the time of
  /// writing this. We resolve initializers twice - first for dependencies,
  /// then for resolution. This has its issues (for example we miss some
  /// dependencies), but the important thing is that we rewrite `foo(0)` from
  /// being a [MethodInvocation] to [FunctionExpressionInvocation]. So, during
  /// the second pass we see [SimpleIdentifier] `foo` as a `function`. And
  /// we should be aware that it is not a stand-alone identifier, but a
  /// cascade section.
  test_hasReceiver_instance_getter_cascade() async {
    await resolveTestCode(r'''
class C {
  double Function(int) get foo => 0;
}

var v = C()..foo(0) = 0;
''');

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_hasReceiver_instance_getter_switchStatementExpression() async {
    await assertNoErrorsInCode(r'''
class C {
  int Function() get foo => throw Error();
}

void f(C c) {
  switch ( c.foo() ) {
    default:
      break;
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@getter::foo
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_instance_method() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}
}

void f(C c) {
  c.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::C::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_instance_method_generic() async {
    await assertNoErrorsInCode(r'''
class C {
  T foo<T>(T a) {
    return a;
  }
}

void f(C c) {
  c.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::C::@method::foo::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int)
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_hasReceiver_instance_method_issue30552() async {
    await assertNoErrorsInCode(r'''
abstract class I1 {
  void foo(int i);
}

abstract class I2 {
  void foo(Object o);
}

abstract class C implements I1, I2 {}

class D extends C {
  void foo(Object o) {}
}

void f(C c) {
  c.foo('hi');
}
''');

    var node = findNode.methodInvocation("foo('hi')");
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::I2::@method::foo
    staticType: void Function(Object)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: 'hi'
    rightParenthesis: )
  staticInvokeType: void Function(Object)
  staticType: void
''');
  }

  test_hasReceiver_instance_typeParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class C<T extends A> {
  T a;
  C(this.a);

  main() {
    a.foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@class::C::@getter::a
    staticType: T
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

  test_hasReceiver_interfaceQ_Function_call_checked() async {
    await assertNoErrorsInCode(r'''
void f(Function? foo) {
  foo?.call();
}
''');

    var node = findNode.methodInvocation('foo?.call()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::f::@formalParameter::foo
    staticType: Function?
  operator: ?.
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_interfaceQ_Function_call_unchecked() async {
    await assertErrorsInCode(
      r'''
void f(Function? foo) {
  foo.call();
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          30,
          4,
        ),
      ],
    );

    var node = findNode.methodInvocation('foo.call()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::f::@formalParameter::foo
    staticType: Function?
  operator: .
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_interfaceQ_nullShorting() async {
    await assertNoErrorsInCode(r'''
class C {
  C foo() => throw 0;
  C bar() => throw 0;
}

void testShort(C? c) {
  c?.foo().bar();
}
''');

    var node = findNode.methodInvocation('bar();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: MethodInvocation
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::testShort::@formalParameter::c
      staticType: C?
    operator: ?.
    methodName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@method::foo
      staticType: C Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: C Function()
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: bar
    element: <testLibrary>::@class::C::@method::bar
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: C Function()
  staticType: C?
''');
  }

  test_hasReceiver_interfaceQ_nullShorting_getter() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  void Function(C) get foo;
}

void f(C? c) {
  c?.foo(c);
}
''');

    var node = findNode.functionExpressionInvocation('foo(c);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::C::@getter::foo
      staticType: void Function(C)
    staticType: void Function(C)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: c
        correspondingParameter: <null-name>@null
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: C
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function(C)
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_interfaceType_class_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  void foo() {}
}

void f(A a) {
  a.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@methodAugmentation::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_interfaceType_class_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f(A a) {
  a.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_enum() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  void foo() {}
}

void f(E e) {
  e.foo();
}
''');

    var node = findNode.methodInvocation('e.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: e
    element: <testLibrary>::@function::f::@formalParameter::e
    staticType: E
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_enum_fromMixin() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  void foo() {}
}

enum E with M {
  v;
}

void f(E e) {
  e.foo();
}
''');

    var node = findNode.methodInvocation('e.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: e
    element: <testLibrary>::@function::f::@formalParameter::e
    staticType: E
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

  test_hasReceiver_interfaceType_extensionType_declared() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  void foo() {}
}

void f(A a) {
  a.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_extensionType_declared_nullableRepresentation() async {
    await assertNoErrorsInCode(r'''
extension type A(int? it) {
  void foo() {}
}

void f(A a) {
  a.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_extensionType_declared_nullableType() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  int foo() => 0;
}

void f(A? a) {
  a.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          67,
          3,
        ),
      ],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_interfaceType_extensionType_declared_nullableType_nullAware() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int foo() => 0;
}

void f(A? a) {
  a?.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int?
''');
  }

  test_hasReceiver_interfaceType_extensionType_exposed() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

class B extends A {}

extension type X(B it) implements A {}

void f(X x) {
  x.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: X
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

  test_hasReceiver_interfaceType_extensionType_notExposed() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  void foo() {}
}

extension type X(B it) implements A {}

void f(X x) {
  x.foo();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 109, 3)],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: X
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_hasReceiver_interfaceType_extensionType_redeclared() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension type X(A it) implements A {
  void foo() {}
}

void f(X x) {
  x.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: X
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::X::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_inheritedMethod_ofGenericClass_usesTypeParameter() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T foo() => throw 0;
}

class B extends A<int> {}

void f(B b) {
  b.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: MethodMember
      baseElement: <testLibrary>::@class::A::@method::foo
      substitution: {T: int}
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_interfaceType_inheritedMethod_ofGenericClass_usesTypeParameterNot() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  double foo() => throw 0;
}

class B extends A<int> {}

void f(B b) {
  b.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: double Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: double Function()
  staticType: double
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_interfaceType_mixin_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  augment void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

mixin A {
  void foo() {}
}

void f(A a) {
  a.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@methodAugmentation::foo
    element: <testLibraryFragment>::@mixin::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_interfaceType_mixin_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

mixin A {}

void f(A a) {
  a.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_ofExtension() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  void foo() {}
}

void f() {
  0.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_interfaceType_ofExtension_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment extension E {
  vois foo() {}
}
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';

extension E on int {}

void f() {
  0.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::foo#element
    staticType: InvalidType Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType Function()
  staticType: InvalidType
''');
  }

  test_hasReceiver_interfaceType_switchExpression() async {
    await assertNoErrorsInCode(r'''
Object f(Object? x) {
  return switch (x) {
    _ => 0,
  }.toString();
}
''');

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SwitchExpression
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
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightBracket: }
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: dart:core::@class::int::@method::toString
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_hasReceiver_interfaceTypeQ_defined() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          48,
          3,
        ),
      ],
    );

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
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

  test_hasReceiver_interfaceTypeQ_defined_extension() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          86,
          3,
        ),
      ],
    );

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
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

  test_hasReceiver_interfaceTypeQ_defined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A? {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceTypeQ_defined_extensionQ2() async {
    await assertNoErrorsInCode(r'''
extension E<T> on T? {
  T foo() => throw 0;
}

void f(int? a) {
  a.foo();
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: MethodMember
      baseElement: <testLibrary>::@extension::E::@method::foo
      substitution: {T: int}
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_interfaceTypeQ_notDefined() async {
    await assertErrorsInCode(
      r'''
class A {}

void f(A? a) {
  a.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          31,
          3,
        ),
      ],
    );

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extension() async {
    await assertErrorsInCode(
      r'''
class A {}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          69,
          3,
        ),
      ],
    );

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A? {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_prefixed_class_staticGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static double Function(int) get foo => null;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        element: package:test/a.dart::@class::C
        staticType: null
      element: package:test/a.dart::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::C::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_hasReceiver_prefixed_class_staticMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static void foo(int _) => null;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: C
      element: package:test/a.dart::@class::C
      staticType: null
    element: package:test/a.dart::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@class::C::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_record_defined_extension() async {
    await assertNoErrorsInCode(r'''
extension E on (int, String) {
  void foo(int a) {}
}

void f((int, String) r) {
  r.foo(0);
}
''');

    var node = findNode.methodInvocation('r.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extension::E::@method::foo::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_recordQ_defined_extension() async {
    await assertNoErrorsInCode(r'''
extension E on (int, String)? {
  void foo(int a) {}
}

void f((int, String)? r) {
  r.foo(0);
}
''');

    var node = findNode.methodInvocation('r.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extension::E::@method::foo::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_recordQ_notDefined_extension() async {
    await assertErrorsInCode(
      r'''
extension E on (int, String) {
  void foo(int a) {}
}

void f((int, String)? r) {
  r.foo(0);
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
          86,
          3,
        ),
      ],
    );

    var node = findNode.methodInvocation('r.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_hasReceiver_super_class_field() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
}

class B extends A {
  late final v = super.foo();
}
''');

    var node = findNode.methodInvocation('super.foo()');
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

  test_hasReceiver_super_class_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

class B extends A {
  void bar() {
    super.foo();
  }
}
''');

    var node = findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
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

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_super_classAugmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void foo() {}
}

class B extends A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class B {
  void bar() {
    super.foo();
  }
}
''');

    await resolveFile2(b);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@class::A::@method::foo
    element: package:test/a.dart::<fragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_hasReceiver_super_classAugmentation_noDeclaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void foo() {}
}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class B {
  void bar() {
    super.foo(0);
  }
}
''');

    await resolveFile2(b);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_hasReceiver_super_getter() async {
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    super.foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_hasReceiver_super_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0);');
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

  test_hasReceiver_super_mixin_field() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
}

mixin M on A {
  late final v = super.foo();
}
''');

    var node = findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: M
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

  test_hasReceiver_super_mixin_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

mixin M on A {
  void bar() {
    super.foo();
  }
}
''');

    var node = findNode.methodInvocation('super.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: M
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

  test_hasReceiver_typeAlias_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int _) {}
}

typedef B = A;

void f() {
  B.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
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
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_typeAlias_staticMethod_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  static void foo(int _) {}
}

typedef B<T> = A<T>;

void f() {
  B.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
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
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_typeParameter_promotedToNonNullable() async {
    await assertNoErrorsInCode('''
void f<T>(T? t) {
  if (t is int) {
    t.abs();
  }
}
''');

    var node = findNode.methodInvocation('t.abs()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: t
    element: <testLibrary>::@function::f::@formalParameter::t
    staticType: T & int
  operator: .
  methodName: SimpleIdentifier
    token: abs
    element: dart:core::@class::int::@method::abs
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_typeParameter_promotedToOtherTypeParameter() async {
    await assertNoErrorsInCode('''
abstract class A {}

abstract class B extends A {
  void foo();
}

void f<T extends A, U extends B>(T a) {
  if (a is U) {
    a.foo();
  }
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: T & U
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::B::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_identifier_class_field() async {
    await assertErrorsInCode(
      r'''
class A {
  final foo = 0;

  void f() {
    foo(0);
  }
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 45, 3)],
    );

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_identifier_class_field_dynamic() async {
    await assertNoErrorsInCode(r'''
class A {
  dynamic foo;

  void f() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
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

  test_identifier_class_getter_dynamic() async {
    await assertNoErrorsInCode(r'''
class A {
  dynamic get foo => null;

  void f() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
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

  test_identifier_formalParameter_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(foo) {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::f::@formalParameter::foo
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

  test_identifier_topLevelFunction_arguments_duplicateNamed() async {
    await assertErrorsInCode(
      '''
final a = 0;

void foo({int? p}) {}

void f() {
  foo(p: 0, p: a);
}
''',
      [error(CompileTimeErrorCode.duplicateNamedArgument, 60, 1)],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function({int? p})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: p
            element: <testLibrary>::@function::foo::@formalParameter::p
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::p
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: p
            element: <testLibrary>::@function::foo::@formalParameter::p
            staticType: null
          colon: :
        expression: SimpleIdentifier
          token: a
          element: <testLibrary>::@getter::a
          staticType: int
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::p
    rightParenthesis: )
  staticInvokeType: void Function({int? p})
  staticType: void
''');
  }

  test_identifier_topLevelVariable() async {
    await assertErrorsInCode(
      r'''
final foo = 0;

void f() {
  foo(0);
}
''',
      [error(CompileTimeErrorCode.invocationOfNonFunctionExpression, 29, 3)],
    );

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_identifier_topLevelVariable_dynamic() async {
    await assertNoErrorsInCode(r'''
dynamic foo;

void f() {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
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

  test_inClass_inInstanceMethod_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int p) {}

  void f() {
    foo(0);
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::p
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_inClass_inInstanceMethod_staticMethod_generic_contextTypeParameter() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  static E foo<E>(A<E> p) => throw 0;

  void f() {
    foo(this);
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: E Function<E>(A<E>)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      ThisExpression
        thisKeyword: this
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::A::@method::foo::@formalParameter::p
          substitution: {E: T}
        staticType: A<T>
    rightParenthesis: )
  staticInvokeType: T Function(A<T>)
  staticType: T
  typeArgumentTypes
    T
''');
  }

  test_inFunction_topLevelFunction() async {
    await assertNoErrorsInCode('''
void foo(int a) {}

void f() {
  foo(0);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_inFunction_topLevelFunction_generic() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void f() {
  foo(0);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_invalid_inDefaultValue_nullAware() async {
    await assertInvalidTestCode('''
void f({a = b?.foo()}) {}
''');

    var node = findNode.methodInvocation('?.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_invalid_inDefaultValue_nullAware2() async {
    await assertInvalidTestCode('''
typedef void F({a = b?.foo()});
''');

    var node = findNode.methodInvocation('?.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_invalidConst_class_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static int foo(int _) => 0;
}

const a = 0;
const b = A.foo(a);
''',
      [error(CompileTimeErrorCode.constEvalMethodInvocation, 66, 8)],
    );

    var node = findNode.singleMethodInvocation;
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
    staticType: int Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: <testLibrary>::@class::A::@method::foo::@formalParameter::_
        element: <testLibrary>::@getter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_invalidConst_expression_instanceMethod() async {
    await assertErrorsInCode(
      r'''
const a = 0;
const b = 'abc'.codeUnitAt(a);
''',
      [error(CompileTimeErrorCode.constEvalMethodInvocation, 23, 19)],
    );

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleStringLiteral
    literal: 'abc'
  operator: .
  methodName: SimpleIdentifier
    token: codeUnitAt
    element: dart:core::@class::String::@method::codeUnitAt
    staticType: int Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: dart:core::@class::String::@method::codeUnitAt::@formalParameter::index
        element: <testLibrary>::@getter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_localFunction() async {
    await assertNoErrorsInCode(r'''
void f() {
  double g(int a, String b) => throw 0;
  g(1, '2');
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@20
    staticType: double Function(int, String)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: a@26
        staticType: int
      SimpleStringLiteral
        literal: '2'
    rightParenthesis: )
  staticInvokeType: double Function(int, String)
  staticType: double
''');
  }

  test_localFunction_generic() async {
    await assertNoErrorsInCode(r'''
void f() {
  T g<T, U>(T a, U b) => throw 0;
  g(1, '2');
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@15
    staticType: T Function<T, U>(T, U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: a@25
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: '2'
    rightParenthesis: )
  staticInvokeType: int Function(int, String)
  staticType: int
  typeArgumentTypes
    int
    String
''');
  }

  test_localFunction_generic_formalParameters_optionalPositional() async {
    await assertNoErrorsInCode(r'''
void f() {
  T g<T>([T? a]) => throw 0;
  g(0);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@15
    staticType: T Function<T>([T?])
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: a@24
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function([int?])
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_localFunction_generic_formalParameters_requiredNamed() async {
    await assertNoErrorsInCode(r'''
void f() {
  T g<T>({required T a}) => throw 0;
  g(a: 0);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@15
    staticType: T Function<T>({required T a})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
            element: ParameterMember
              baseElement: a@32
              substitution: {T: int}
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
        correspondingParameter: ParameterMember
          baseElement: a@32
          substitution: {T: int}
    rightParenthesis: )
  staticInvokeType: int Function({required int a})
  staticType: int
  typeArgumentTypes
    int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_explicitThis_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

void foo() {}

mixin A {
  void f() {
    this.foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_implicitThis_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

void foo() {}

mixin A {
  void f() {
    foo();
  }
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_namedArgument() async {
    await assertNoErrorsInCode('''
void foo({int? a, bool? b}) {}

main() {
  foo(b: false, a: 0);
}
''');

    var node = findNode.methodInvocation('foo(b:');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function({int? a, bool? b})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            element: <testLibrary>::@function::foo::@formalParameter::b
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: false
          staticType: bool
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::b
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
            element: <testLibrary>::@function::foo::@formalParameter::a
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
    rightParenthesis: )
  staticInvokeType: void Function({int? a, bool? b})
  staticType: void
''');
  }

  test_namedArgument_anywhere() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}
class D {}

void foo(A a, B b, {C? c, D? d}) {}

T g1<T>() => throw 0;
T g2<T>() => throw 0;
T g3<T>() => throw 0;
T g4<T>() => throw 0;

void f() {
  foo(g1(), c: g3(), g2(), d: g4());
}
''');

    var node = findNode.methodInvocation('foo(g');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function(A, B, {C? c, D? d})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: g1
          element: <testLibrary>::@function::g1
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
        staticInvokeType: A Function()
        staticType: A
        typeArgumentTypes
          A
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            element: <testLibrary>::@function::foo::@formalParameter::c
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g3
            element: <testLibrary>::@function::g3
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: C? Function()
          staticType: C?
          typeArgumentTypes
            C?
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::c
      MethodInvocation
        methodName: SimpleIdentifier
          token: g2
          element: <testLibrary>::@function::g2
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::b
        staticInvokeType: B Function()
        staticType: B
        typeArgumentTypes
          B
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: d
            element: <testLibrary>::@function::foo::@formalParameter::d
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g4
            element: <testLibrary>::@function::g4
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: D? Function()
          staticType: D?
          typeArgumentTypes
            D?
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::d
    rightParenthesis: )
  staticInvokeType: void Function(A, B, {C? c, D? d})
  staticType: void
''');
  }

  test_noReceiver_call_extension_on_FunctionType() async {
    await assertNoErrorsInCode(r'''
extension E on int Function() {
  void f() {
    call();
  }
}
''');

    var node = findNode.methodInvocation('call()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_noReceiver_call_extension_on_FunctionType_bounded() async {
    await assertNoErrorsInCode(r'''
extension E<T extends int Function()> on T {
  void f() {
    call();
  }
}
''');

    var node = findNode.methodInvocation('call()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_noReceiver_getter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_noReceiver_getter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => throw Error();

  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_noReceiver_importPrefix() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as math;

main() {
  math();
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 40, 4)],
    );

    var node = findNode.methodInvocation('math()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix2::math
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noReceiver_localFunction() async {
    await assertNoErrorsInCode(r'''
main() {
  void foo(int _) {}

  foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: foo@16
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: _@24
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_noReceiver_localVariable_call() async {
    await assertNoErrorsInCode(r'''
class C {
  void call(int _) {}
}

void f(C c) {
  c(0);
}
''');

    var node = findNode.functionExpressionInvocation('c(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::C::@method::call::@formalParameter::_
        staticType: int
    rightParenthesis: )
  element: <testLibrary>::@class::C::@method::call
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_noReceiver_localVariable_promoted() async {
    await assertNoErrorsInCode(r'''
main() {
  var foo;
  if (foo is void Function(int)) {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: foo@15
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

  test_noReceiver_method_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
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

  test_noReceiver_method_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}

  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::C::@method::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_noReceiver_parameter() async {
    await assertNoErrorsInCode(r'''
void f(void Function(int) foo) {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::f::@formalParameter::foo
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

  test_noReceiver_parameter_call_nullAware() async {
    await assertNoErrorsInCode('''
double Function(int)? foo;

main() {
  foo?.call(1);
}
    ''');

    var node = findNode.methodInvocation('call(1)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: double Function(int)?
  operator: ?.
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  staticInvokeType: double Function(int)
  staticType: double?
''');
  }

  test_noReceiver_parameter_functionTyped_typedef() async {
    await assertNoErrorsInCode(r'''
typedef F = void Function();

void f(F a) {
  a();
}
''');

    var node = findNode.functionExpressionInvocation('a();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: void Function()
      alias: <testLibrary>::@typeAlias::F
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: void Function()
    alias: <testLibrary>::@typeAlias::F
  staticType: void
''');
  }

  test_noReceiver_topFunction() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_noReceiver_topGetter() async {
    await assertNoErrorsInCode(r'''
double Function(int) get foo => throw Error();

main() {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null-name>@null
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_noReceiver_topVariable() async {
    await assertNoErrorsInCode(r'''
void Function(int) foo = throw Error();

main() {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
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

  test_nullShorting_cascade_firstMethodInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo()..bar();
}
''');

    var node = findNode.cascade('a?..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  cascadeSections
    MethodInvocation
      operator: ?..
      methodName: SimpleIdentifier
        token: foo
        element: <testLibrary>::@class::A::@method::foo
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: bar
        element: <testLibrary>::@class::A::@method::bar
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
  staticType: A?
''');
  }

  test_nullShorting_cascade_firstPropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo..bar();
}
''');

    var node = findNode.cascade('a?..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  cascadeSections
    PropertyAccess
      operator: ?..
      propertyName: SimpleIdentifier
        token: foo
        element: <testLibrary>::@class::A::@getter::foo
        staticType: int
      staticType: int
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: bar
        element: <testLibrary>::@class::A::@method::bar
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
  staticType: A?
''');
  }

  test_nullShorting_cascade_nullAwareInside() async {
    await assertNoErrorsInCode(r'''
class A {
  int? foo() => 0;
}

main() {
  A a = A()..foo()?.abs();
  a;
}
''');

    var node = findNode.cascade('A()..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element2: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  cascadeSections
    MethodInvocation
      target: MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: foo
          element: <testLibrary>::@class::A::@method::foo
          staticType: int? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int? Function()
        staticType: int?
      operator: ?.
      methodName: SimpleIdentifier
        token: abs
        element: dart:core::@class::int::@method::abs
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int?
  staticType: A
''');
  }

  test_objectMethodOnDynamic_argumentsDontMatch() async {
    await assertNoErrorsInCode(r'''
void f(a, int b) {
  a.toString(b);
}
''');

    var node = findNode.methodInvocation('toString(b)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: <null>
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_objectMethodOnDynamic_argumentsMatch() async {
    await assertNoErrorsInCode(r'''
void f(a) {
  a.toString();
}
''');

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: dart:core::@class::Object::@method::toString
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_objectMethodOnFunction() async {
    await assertNoErrorsInCode(r'''
void f() {}

main() {
  f.toString();
}
''');

    var node = findNode.methodInvocation('toString();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: void Function()
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: dart:core::@class::Object::@method::toString
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_parameterMember_source() async {
    // See https://github.com/dart-lang/sdk/issues/50660
    await assertNoErrorsInCode(r'''
void foo<T>({int? a}) {}

void f() {
  foo(a: 0);
}
''');

    // See https://github.com/dart-lang/sdk/issues/54669 for why we check for
    // isNotNull despite #50660 suggesting the source would be null.
    var element = findNode.simple('a:').element!;
    var libraryFragment2 = element.firstFragment.libraryFragment!;
    expect(libraryFragment2.source, isNotNull);
  }

  test_remainder_int_context_cascaded() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a..remainder(f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::remainder::@formalParameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_remainder_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a.remainder(f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::remainder::@formalParameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_remainder_int_context_int_target_rewritten() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int Function() a) {
  h(a().remainder(f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::remainder::@formalParameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_remainder_int_context_int_via_extension_explicit() async {
    await assertErrorsInCode(
      '''
extension E on int {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 98, 19)],
    );

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@extension::E::@method::remainder::@formalParameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_remainder_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a.remainder(f());
}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::remainder::@formalParameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_remainder_int_double() async {
    await assertNoErrorsInCode('''
f(int a, double b) {
  a.remainder(b);
}
''');

    var node = findNode.methodInvocation('remainder');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    element: dart:core::@class::num::@method::remainder
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::remainder::@formalParameter::other
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_remainder_int_int() async {
    await assertNoErrorsInCode('''
f(int a, int b) {
  a.remainder(b);
}
''');

    var node = findNode.methodInvocation('remainder');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    element: dart:core::@class::num::@method::remainder
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::remainder::@formalParameter::other
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_remainder_int_int_target_rewritten() async {
    await assertNoErrorsInCode('''
f(int Function() a, int b) {
  a().remainder(b);
}
''');

    var node = findNode.methodInvocation('remainder');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    element: dart:core::@class::num::@method::remainder
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::remainder::@formalParameter::other
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_remainder_other_context_int_via_extension_explicit() async {
    await assertErrorsInCode(
      '''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 105, 19)],
    );

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@extension::E::@method::remainder::@formalParameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_remainder_other_context_int_via_extension_implicit() async {
    await assertErrorsInCode(
      '''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a.remainder(f()));
}
h(int x) {}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 105, 16)],
    );

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@extension::E::@method::remainder::@formalParameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_rewrite_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(this.content);
  final String Function() content;
}

class B {
  const B(this.a);
  final A a;
}

void main() {
  (null as B?)?.a.content();
}
''');
    var node = findNode.functionExpressionInvocation('content()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: PropertyAccess
      target: ParenthesizedExpression
        leftParenthesis: (
        expression: AsExpression
          expression: NullLiteral
            literal: null
            staticType: Null
          asOperator: as
          type: NamedType
            name: B
            question: ?
            element2: <testLibrary>::@class::B
            type: B?
          staticType: B?
        rightParenthesis: )
        staticType: B?
      operator: ?.
      propertyName: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: content
      element: <testLibrary>::@class::A::@getter::content
      staticType: String Function()
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: String Function()
  staticType: String?
''');
  }

  test_rewrite_with_target() async {
    await assertNoErrorsInCode(r'''
test<T extends Function>(List<T> x) {
  x.first();
}
''');

    var node = findNode.functionExpressionInvocation('x.first()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::test::@formalParameter::x
      staticType: List<T>
    operator: .
    propertyName: SimpleIdentifier
      token: first
      element: GetterMember
        baseElement: dart:core::@class::Iterable::@getter::first
        substitution: {E: T}
      staticType: T
    staticType: T
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_rewrite_without_target() async {
    await assertNoErrorsInCode(r'''
extension E<T extends Function> on List<T> {
  test() {
    first();
  }
}
''');

    var node = findNode.functionExpressionInvocation('first()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: first
    element: GetterMember
      baseElement: dart:core::@class::Iterable::@getter::first
      substitution: {E: T}
    staticType: T
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_superQualifier_identifier_methodOfMixin_inEnum() async {
    await assertNoErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  void f() {
    super.foo();
  }
}
''');

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: E
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

  test_superQualifier_identifier_unresolved_inClass() async {
    await assertErrorsInCode(
      r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''',
      [error(CompileTimeErrorCode.undefinedSuperMethod, 62, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_superQualifier_identifier_unresolved_inEnum() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void f() {
    super.foo(0);
  }
}
''',
      [error(CompileTimeErrorCode.undefinedSuperMethod, 37, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: E
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_superQualifier_identifier_unresolved_inMixin() async {
    await assertErrorsInCode(
      r'''
class A {}

mixin M on A {
  void bar() {
    super.foo(0);
  }
}
''',
      [error(CompileTimeErrorCode.undefinedSuperMethod, 52, 3)],
    );

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: M
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_syntheticName() async {
    // This code is invalid, and the constructor initializer has a method
    // invocation with a synthetic name. But we should still resolve the
    // invocation, and resolve all its arguments.
    await assertErrorsInCode(
      r'''
class A {
  A() : B(1 + 2, [0]);
}
''',
      [
        error(ParserErrorCode.missingAssignmentInInitializer, 18, 1),
        error(CompileTimeErrorCode.initializerForNonExistentField, 18, 13),
      ],
    );

    var node = findNode.methodInvocation(');');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: <empty> <synthetic>
    element: <null>
    staticType: InvalidType
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
      ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 0
            staticType: int
        rightBracket: ]
        correspondingParameter: <null>
        staticType: List<int>
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');

    assertType(findNode.binary('1 + 2'), 'int');
    assertType(findNode.listLiteral('[0]'), 'List<int>');
  }

  test_topLevelFunction_notGeneric_arguments_named() async {
    await assertNoErrorsInCode(r'''
void foo(int a, {required bool b}) {}

void f() {
  foo(0, b: true);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function(int, {required bool b})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
        staticType: int
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            element: <testLibrary>::@function::foo::@formalParameter::b
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: true
          staticType: bool
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::b
    rightParenthesis: )
  staticInvokeType: void Function(int, {required bool b})
  staticType: void
''');
  }

  test_typeArgumentTypes_generic_inferred() async {
    await assertErrorsInCode(
      r'''
U foo<T, U>(T a) => throw Error();

main() {
  bool v = foo(0);
}
''',
      [error(WarningCode.unusedLocalVariable, 52, 1)],
    );

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: U Function<T, U>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::a
          substitution: {T: int, U: bool}
        staticType: int
    rightParenthesis: )
  staticInvokeType: bool Function(int)
  staticType: bool
  typeArgumentTypes
    int
    bool
''');
  }

  test_typeArgumentTypes_generic_inferred_leftTop_dynamic() async {
    await assertNoErrorsInCode('''
void foo<T extends Object>(T? value) {}

void f(dynamic o) {
  foo(o);
}
''');

    var node = findNode.methodInvocation('foo(o)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T extends Object>(T?)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: o
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::value
          substitution: {T: Object}
        element: <testLibrary>::@function::f::@formalParameter::o
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: void Function(Object?)
  staticType: void
  typeArgumentTypes
    Object
''');
  }

  test_typeArgumentTypes_generic_inferred_leftTop_void() async {
    await assertNoErrorsInCode('''
void foo<T extends Object>(List<T?> value) {}

void f(List<void> o) {
  foo(o);
}
''');

    var node = findNode.methodInvocation('foo(o)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T extends Object>(List<T?>)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: o
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::value
          substitution: {T: Object}
        element: <testLibrary>::@function::f::@formalParameter::o
        staticType: List<void>
    rightParenthesis: )
  staticInvokeType: void Function(List<Object?>)
  staticType: void
  typeArgumentTypes
    Object
''');
  }

  test_typeArgumentTypes_generic_instantiateToBounds() async {
    await assertNoErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo();
}
''');

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T extends num>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
  typeArgumentTypes
    num
''');
  }

  test_typeArgumentTypes_generic_typeArguments_notBounds() async {
    await assertErrorsInCode(
      r'''
void foo<T extends num>() {}

main() {
  foo<bool>();
}
''',
      [error(CompileTimeErrorCode.typeArgumentNotMatchingBounds, 45, 4)],
    );

    var node = findNode.methodInvocation('foo<bool>();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T extends num>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element2: dart:core::@class::bool
        type: bool
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
  typeArgumentTypes
    bool
''');
  }

  test_typeArgumentTypes_generic_typeArguments_wrongNumber() async {
    await assertErrorsInCode(
      r'''
void foo<T>() {}

main() {
  foo<int, double>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod, 32, 13)],
    );

    var node = findNode.methodInvocation('foo<int, double>();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: double
        element2: dart:core::@class::double
        type: double
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
  typeArgumentTypes
    dynamic
''');
  }

  test_typeArgumentTypes_notGeneric() async {
    await assertNoErrorsInCode(r'''
void foo(int a) {}

main() {
  foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }
}
