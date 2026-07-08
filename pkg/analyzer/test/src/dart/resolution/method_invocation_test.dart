// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    g(super);
//    ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}

void g(Object a) {}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  g(,,);
//  ^
// [diag.missingIdentifier] Expected an identifier.
//   ^
// [diag.missingIdentifier] Expected an identifier.
}

void g(int a, int b) {}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
  void bar() {}
}

void f(A a) {
  a..foo()..bar();
}
''');

    var node = result.findNode.singleCascadeExpression;
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''');

    var node = result.findNode.methodInvocation('h(a');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
//  ^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('h(a');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(double a) {
  a.clamp(f(), f());
}
''');

    var node = result.findNode.methodInvocation('a.clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(double a, double b, double c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(double a, double b, int c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(double a, int b, double c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(double a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
//  ^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'double'.
}
h(double x) {}
''');

    var node = result.findNode.methodInvocation('h(a');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('h(a');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  a.clamp(f(), f());
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, double b, double c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, double b, dynamic c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, double b, int c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, dynamic b, double c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, dynamic b, int c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, int b, double c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, int b, dynamic c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, int b, int c) {
  a..clamp(b, c).isEven;
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  String clamp(int x, int y) => '';
}
f(int a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp(b');
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
    element: <testLibrary>::@extension::E
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, int b, Never c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, Never b, int c) {
  a.clamp(b, c);
//           ^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(Never a, int b, int c) {
  a.clamp(b, c);
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//       ^^^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.methodInvocation('clamp');
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
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  num clamp(String x, String y);
}
T f<T>() => throw Error();
g(A a) {
  h(a.clamp(f(), f()));
//  ^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('h(a');
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
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  String clamp(int x, int y);
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp(b');
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp(b');
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
    element: <testLibrary>::@extension::E
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = result.findNode.methodInvocation('clamp(b');
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

  test_class_explicitThis_inAugmentation_augmentationDeclares() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var results = await resolveFilesWithDiagnostics({
      testFile: r'''
part 'a.dart';

void foo() {}

class A {}
''',
      a: r'''
part of 'test.dart';

augment class A {
  void foo() {}

  void f() {
    this.foo();
  }
}
''',
    });

    var result = results[a]!;

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ThisExpression
    thisKeyword: this
    staticType: A
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

  test_demoteType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void test<T>(T t) {}

void f<S>(S s) {
  if (s is int) {
    test(s);
  }
}

''');

    var node = result.findNode.methodInvocation('test(s)');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
//^^^
// [diag.ambiguousImport] The name 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
//  ^^^
// [diag.ambiguousImport] The name 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int _) {}
}

void f(A a) {
  a.foo(0);
//  ^^^
// [diag.instanceAccessToStaticMember] The static method 'foo' can't be accessed through an instance.
}
''');

    var node = result.findNode.methodInvocation('a.foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void Function() call = throw Error();
}

void f(C c) {
  c();
//^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.functionExpressionInvocation('c();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  var foo;
}

void f(C c) {
  c.foo();
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  var foo;
}

class B extends A {
  main() {
    foo();
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  var foo;

  main() {
    foo();
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Function foo) {
  foo(1, 2);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(1, 2);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef MyFunction = double Function(int _);

class C<T extends MyFunction> {
  T foo;
  C(this.foo);

  main() {
    foo(0);
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    element: SubstitutedGetterElementImpl
      baseElement: <testLibrary>::@class::C::@getter::foo
      substitution: {T: T}
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main(Object foo) {
  foo();
//^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main(foo) {
  foo();
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int foo = 0;
}

main() {
  C.foo();
//^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static int foo = 0;

  main() {
    foo();
//  ^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
//  ^^^^^^^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
//^^^^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'prefix' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix::prefix
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
//^^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'math' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.methodInvocation('loadLibrary()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix::math
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;

main() {
  foo();
//^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'foo' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.methodInvocation('foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibraryFragment>::@prefix::foo
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  foo(0);
//^^^
// [diag.undefinedFunction] The function 'foo' isn't defined.
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;

main() {
  math.foo(0);
//     ^^^
// [diag.undefinedFunction] The function 'foo' isn't defined.
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix::math
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  bar.foo(0);
//^^^
// [diag.undefinedIdentifier] Undefined name 'bar'.
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}
main() {
  C.foo(0);
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

int x = 0;
main() {
  C.foo(x);
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.methodInvocation('foo(x);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {}

main() {
  C.foo<int>();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.methodInvocation('foo<int>();');
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  static main() => C.T();
//                   ^
// [diag.undefinedMethod] The method 'T' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.methodInvocation('C.T();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  42.foo(0);
//   ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = () {};
  v.foo(0);
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'Function'.
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  main() {
    foo(0);
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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

  test_error_undefinedMethod_noTarget_synthetic_class() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class {
//    ^
// [diag.missingIdentifier] Expected an identifier.
  void f() {
    foo(0);
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  null.foo();
//     ^^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');

    var node = result.findNode.methodInvocation('foo();');
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
    await resolveTestCodeWithDiagnostics(r'''
main(Object o) {
  o.call();
//  ^^^^
// [diag.undefinedMethod] The method 'call' isn't defined for the type 'Object'.
}
''');
  }

  test_error_undefinedMethod_private() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
//  ^^^^
// [diag.undefinedMethod] The method '_foo' isn't defined for the type 'B'.
  }
}
''');

    var node = result.findNode.methodInvocation('_foo(0);');
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
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
//   ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'Type'.
}
''');
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
main() {
  A?.toString();
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
//   ^^^^^^^^
// [diag.undefinedMethod] The method 'toString' isn't defined for the type 'A'.
}
''');
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
//  ^^^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
//      ^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'missing.dart' as p;
//     ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'missing.dart'.

main() {
  p.foo(1);
  p.bar(2);
}
''');

    var node = result.findNode.methodInvocation('foo(1);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibraryFragment>::@prefix::p
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'missing.dart' show foo, bar;
//     ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'missing.dart'.

main() {
  foo(1);
  bar(2);
}
''');

    var node = result.findNode.methodInvocation('foo(1);');
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
    var result = await resolveTestCodeWithDiagnostics('''
class C<T>{
  T foo;
  C(this.foo);
}

void f(C<void> c) {
  c.foo();
//^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
      element: SubstitutedGetterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  void foo;
  foo();
//^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

main() {
  foo()();
//^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.methodInvocation('foo()()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo;

main() {
  foo();
//^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.functionExpressionInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  void foo;
  foo.toString();
//^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.methodInvocation('toString()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  void foo;
  foo..toString();
//^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.methodInvocation('toString()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  void foo;
  foo?.toString();
//^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');

    var node = result.findNode.methodInvocation('toString()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

main() {
  foo<int>();
//   ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 0 type parameters, but 1 type arguments are given.
}
''');

    var node = result.findNode.methodInvocation('foo<int>()');
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
Map<T, U> foo<T extends num, U>() => throw Error();

main() {
  foo<int>();
//   ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 2 type parameters, but 1 type arguments are given.
}
''');

    var node = result.findNode.methodInvocation('foo<int>()');
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(double Function(int p) g) {
  g.call(0);
}
''');

    var node = result.findNode.methodInvocation('call(0)');
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
        correspondingParameter: p@27
        staticType: int
    rightParenthesis: )
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_expression_interfaceType_explicitCall() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  double call(int p) => 0.0;
}

void f(C c) {
  c.call(0);
}
''');

    var node = result.findNode.methodInvocation('call(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}

  void f() {
    this.foo();
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}

  void f() {
    foo();
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static double Function(int) get foo => throw Error();
}

main() {
  C.foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo(int _) {}
}

main() {
  C.foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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

  test_hasReceiver_deferredImportPrefix_loadLibrary() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' deferred as math;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.

main() {
  math.loadLibrary();
}
''');

    var node = result.findNode.methodInvocation('loadLibrary()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix::math
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' deferred as math;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.

main() {
  math.loadLibrary(1 + 2);
//                 ^^^^^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
}
''');

    var node = result.findNode.methodInvocation('loadLibrary(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix::math
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a.hash(0, 1);
}
''');

    var node = result.findNode.methodInvocation('hash(');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A on int {
  static double Function(int) get foo => throw Error();
}

void f() {
  A.foo(0);
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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

  test_hasReceiver_extension_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A on int {
  static void foo(int _) {}
}

void f() {
  A.foo(0);
}
''');

    var node = result.findNode.singleMethodInvocation;
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

  test_hasReceiver_extensionTypeName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(int _) {}

main() {
  foo.call(0);
}
''');

    var node = result.findNode.methodInvocation('call(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T _) {}

main() {
  foo.call(0);
}
''');

    var node = result.findNode.methodInvocation('call(0)');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var node = result.findNode.methodInvocation('foo(1, 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix::prefix
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: package:test/a.dart::@function::foo::@formalParameter::a
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFormalParameterElementImpl
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(1, 2);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: a@null
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Function getFunction()) {
  Function foo = getFunction();

  foo.call(0);
}
''');

    var node = result.findNode.methodInvocation('call(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
Function foo = throw Error();

void main() {
  foo.call(0);
}
''');

    var node = result.findNode.methodInvocation('call(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  double Function(int) get foo => throw Error();
}

void f(C c) {
  c.foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCode(r'''
class C {
  double Function(int) get foo => 0;
}

var v = C()..foo(0) = 0;
''');

    var node = result.findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    operator: ..
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

  test_hasReceiver_instance_getter_switchStatementExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.functionExpressionInvocation('foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo(int _) {}
}

void f(C c) {
  c.foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  T foo<T>(T a) {
    return a;
  }
}

void f(C c) {
  c.foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.methodInvocation("foo('hi')");
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: SubstitutedGetterElementImpl
      baseElement: <testLibrary>::@class::C::@getter::a
      substitution: {T: T}
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Function? foo) {
  foo?.call();
}
''');

    var node = result.findNode.methodInvocation('foo?.call()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Function? foo) {
  foo.call();
//    ^^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'call' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.methodInvocation('foo.call()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  C foo() => throw 0;
  C bar() => throw 0;
}

void testShort(C? c) {
  c?.foo().bar();
}
''');

    var node = result.findNode.methodInvocation('bar();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  void Function(C) get foo;
}

void f(C? c) {
  c?.foo(c);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(c);');
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

  test_hasReceiver_interfaceType_enum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void foo() {}
}

void f(E e) {
  e.foo();
}
''');

    var node = result.findNode.methodInvocation('e.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.methodInvocation('e.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}
}

void f(A a) {
  a.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int? it) {
  void foo() {}
}

void f(A a) {
  a.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int foo() => 0;
}

void f(A? a) {
  a.foo();
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int foo() => 0;
}

void f(A? a) {
  a?.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B extends A {}

extension type X(B it) implements A {}

void f(X x) {
  x.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  void foo() {}
}

extension type X(B it) implements A {}

void f(X x) {
  x.foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'X'.
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  T foo() => throw 0;
}

class B extends A<int> {}

void f(B b) {
  b.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: SubstitutedMethodElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  double foo() => throw 0;
}

class B extends A<int> {}

void f(B b) {
  b.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
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

  test_hasReceiver_interfaceType_ofExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

void f() {
  0.foo();
}
''');

    var node = result.findNode.singleMethodInvocation;
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

  test_hasReceiver_interfaceType_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Object f(Object? x) {
  return switch (x) {
    _ => 0,
  }.toString();
}
''');

    var node = result.findNode.methodInvocation('toString()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

void f(A? a) {
  a.foo();
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.methodInvocation('a.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.methodInvocation('a.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.methodInvocation('a.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E<T> on T? {
  T foo() => throw 0;
}

void f(int? a) {
  a.foo();
}
''');

    var node = result.findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: SubstitutedMethodElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A? a) {
  a.foo();
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.methodInvocation('a.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.methodInvocation('a.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A? {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''');

    var node = result.findNode.methodInvocation('a.foo()');
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

  test_hasReceiver_neverQuestion_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never? a) {
  a?.foo();
//   ^^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.methodInvocation('foo');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Never?
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never?
''');
  }

  test_hasReceiver_prefixed_class_staticGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static double Function(int) get foo => null;
}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  void foo(int a) {}
}

void f((int, String) r) {
  r.foo(0);
}
''');

    var node = result.findNode.methodInvocation('r.foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String)? {
  void foo(int a) {}
}

void f((int, String)? r) {
  r.foo(0);
}
''');

    var node = result.findNode.methodInvocation('r.foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  void foo(int a) {}
}

void f((int, String)? r) {
  r.foo(0);
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node = result.findNode.methodInvocation('r.foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => 0;
}

class B extends A {
  late final v = super.foo();
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

  test_hasReceiver_super_class_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B extends A {
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

  test_hasReceiver_super_classAugmentation() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {
  void foo() {}
}

class B extends A {}
''',
      b: r'''
part of 'a.dart';

augment class B {
  void bar() {
    super.foo();
  }
}
''',
    });

    var result = results[b]!;

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_super_classAugmentation_noDeclaration() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var results = await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {
  void foo() {}
}
''',
      b: r'''
part of 'a.dart';

augment class B {
// [diag.augmentationWithoutDeclaration][column 1][length 7] The declaration being augmented doesn't exist.
  void bar() {
    super.foo(0);
//        ^^^
// [diag.undefinedSuperMethod] The method 'foo' isn't defined in a superclass of 'B'.
  }
}
''',
    });

    var result = results[b]!;

    var node = result.findNode.singleMethodInvocation;
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

  test_hasReceiver_super_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    super.foo(0);
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => 0;
}

mixin M on A {
  late final v = super.foo();
}
''');

    var node = result.findNode.methodInvocation('super.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

mixin M on A {
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int _) {}
}

typedef B = A;

void f() {
  B.foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static void foo(int _) {}
}

typedef B<T> = A<T>;

void f() {
  B.foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics('''
void f<T>(T? t) {
  if (t is int) {
    t.abs();
  }
}
''');

    var node = result.findNode.methodInvocation('t.abs()');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.methodInvocation('a.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final foo = 0;

  void f() {
    foo(0);
//  ^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  dynamic foo;

  void f() {
    foo(0);
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  dynamic get foo => null;

  void f() {
    foo(0);
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(foo) {
  foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics('''
final a = 0;

void foo({int? p}) {}

void f() {
  foo(p: 0, p: a);
//          ^
// [diag.duplicateNamedArgument] The argument for the named parameter 'p' was already specified.
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function({int? p})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: p
        colon: :
        argumentExpression: IntegerLiteral
          literal: 0
          staticType: int
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::p
      NamedArgument
        name: p
        colon: :
        argumentExpression: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = 0;

void f() {
  foo(0);
//^^^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
dynamic foo;

void f() {
  foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo(int p) {}

  void f() {
    foo(0);
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static E foo<E>(A<E> p) => throw 0;

  void f() {
    foo(this);
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo(int a) {}

void f() {
  foo(0);
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}

void f() {
  foo(0);
}
''');

    var node = result.findNode.singleMethodInvocation;
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void f({a = b?.foo()}) {}
//          ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');

    var node = result.findNode.methodInvocation('?.foo()');
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
    var result = await resolveTestCodeWithDiagnostics('''
typedef void F({a = b?.foo()});
//                ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
//                  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');

    var node = result.findNode.methodInvocation('?.foo()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo(int _) => 0;
}

const a = 0;
const b = A.foo(a);
//        ^^^^^^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const a = 0;
const b = 'abc'.codeUnitAt(a);
//        ^^^^^^^^^^^^^^^^^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  double g(int a, String b) => throw 0;
  g(1, '2');
}
''');

    var node = result.findNode.singleMethodInvocation;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  T g<T, U>(T a, U b) => throw 0;
  g(1, '2');
}
''');

    var node = result.findNode.singleMethodInvocation;
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  T g<T>([T? a]) => throw 0;
  g(0);
}
''');

    var node = result.findNode.singleMethodInvocation;
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  T g<T>({required T a}) => throw 0;
  g(a: 0);
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@15
    staticType: T Function<T>({required T a})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: a
        colon: :
        argumentExpression: IntegerLiteral
          literal: 0
          staticType: int
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: a@32
          substitution: {T: int}
    rightParenthesis: )
  staticInvokeType: int Function({required int a})
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_namedArgument() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo({int? a, bool? b}) {}

main() {
  foo(b: false, a: 0);
}
''');

    var node = result.findNode.methodInvocation('foo(b:');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function({int? a, bool? b})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: b
        colon: :
        argumentExpression: BooleanLiteral
          literal: false
          staticType: bool
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::b
      NamedArgument
        name: a
        colon: :
        argumentExpression: IntegerLiteral
          literal: 0
          staticType: int
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
    rightParenthesis: )
  staticInvokeType: void Function({int? a, bool? b})
  staticType: void
''');
  }

  test_namedArgument_anywhere() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.methodInvocation('foo(g');
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
      NamedArgument
        name: c
        colon: :
        argumentExpression: MethodInvocation
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
      NamedArgument
        name: d
        colon: :
        argumentExpression: MethodInvocation
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int Function() {
  void f() {
    call();
  }
}
''');

    var node = result.findNode.methodInvocation('call()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E<T extends int Function()> on T {
  void f() {
    call();
  }
}
''');

    var node = result.findNode.methodInvocation('call()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  double Function(int) get foo => throw Error();

  void bar() {
    foo(0);
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;

main() {
  math();
//^^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'math' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.methodInvocation('math()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: math
    element: <testLibraryFragment>::@prefix::math
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_noReceiver_localFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  void foo(int _) {}

  foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void call(int _) {}
}

void f(C c) {
  c(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('c(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var foo;
  if (foo is void Function(int)) {
    foo(0);
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo(int _) {}

  void bar() {
    foo(0);
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(void Function(int) foo) {
  foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics('''
double Function(int)? foo;

main() {
  foo?.call(1);
}
    ''');

    var node = result.findNode.methodInvocation('call(1)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function();

void f(F a) {
  a();
}
''');

    var node = result.findNode.functionExpressionInvocation('a();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(int _) {}

main() {
  foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
double Function(int) get foo => throw Error();

main() {
  foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void Function(int) foo = throw Error();

main() {
  foo(0);
}
''');

    var node = result.findNode.functionExpressionInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo()..bar();
}
''');

    var node = result.findNode.cascade('a?..');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo..bar();
}
''');

    var node = result.findNode.cascade('a?..');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? foo() => 0;
}

main() {
  A a = A()..foo()?.abs();
  a;
}
''');

    var node = result.findNode.cascade('A()..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(a, int b) {
  a.toString(b);
}
''');

    var node = result.findNode.methodInvocation('toString(b)');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(a) {
  a.toString();
}
''');

    var node = result.findNode.methodInvocation('toString()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {}

main() {
  f.toString();
}
''');

    var node = result.findNode.methodInvocation('toString();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo<T>({int? a}) {}

void f() {
  foo(a: 0);
}
''');

    // See https://github.com/dart-lang/sdk/issues/54669 for why we check for
    // isNotNull despite #50660 suggesting the source would be null.
    var element = result.findNode.namedArgument('a:').correspondingParameter!;
    var libraryFragment2 = element.firstFragment.libraryFragment!;
    expect(libraryFragment2.source, isNotNull);
  }

  test_remainder_int_context_cascaded() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  h(a..remainder(f()));
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('f()');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  h(a.remainder(f()));
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('f()');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int Function() a) {
  h(a().remainder(f()));
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('f()');
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
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a).remainder(f()));
//  ^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('f()');
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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  a.remainder(f());
}
''');

    var node = result.findNode.methodInvocation('f()');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, double b) {
  a.remainder(b);
}
''');

    var node = result.findNode.methodInvocation('remainder');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int a, int b) {
  a.remainder(b);
}
''');

    var node = result.findNode.methodInvocation('remainder');
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
    var result = await resolveTestCodeWithDiagnostics('''
f(int Function() a, int b) {
  a().remainder(b);
}
''');

    var node = result.findNode.methodInvocation('remainder');
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a).remainder(f()));
//  ^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('f()');
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a.remainder(f()));
//  ^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = result.findNode.methodInvocation('f()');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    var node = result.findNode.functionExpressionInvocation('content()');
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
            element: <testLibrary>::@class::B
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
    var result = await resolveTestCodeWithDiagnostics(r'''
test<T extends Function>(List<T> x) {
  x.first();
}
''');

    var node = result.findNode.functionExpressionInvocation('x.first()');
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
      element: SubstitutedGetterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E<T extends Function> on List<T> {
  test() {
    first();
  }
}
''');

    var node = result.findNode.functionExpressionInvocation('first()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: first
    element: SubstitutedGetterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.methodInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
//        ^^^
// [diag.undefinedSuperMethod] The method 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super.foo(0);
//        ^^^
// [diag.undefinedSuperMethod] The method 'foo' isn't defined in a superclass of 'E'.
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin M on A {
  void bar() {
    super.foo(0);
//        ^^^
// [diag.undefinedSuperMethod] The method 'foo' isn't defined in a superclass of 'M'.
  }
}
''');

    var node = result.findNode.methodInvocation('foo(0);');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : B(1 + 2, [0]);
//      ^
// [diag.missingAssignmentInInitializer] Expected an assignment after the field name.
//      ^^^^^^^^^^^^^
// [diag.initializerForNonExistentField] 'B' isn't a field in the enclosing class.
}
''');

    var node = result.findNode.methodInvocation(');');
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

    assertType(result.findNode.binary('1 + 2'), 'int');
    assertType(result.findNode.listLiteral('[0]'), 'List<int>');
  }

  test_topLevelFunction_notGeneric_arguments_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(int a, {required bool b}) {}

void f() {
  foo(0, b: true);
}
''');

    var node = result.findNode.singleMethodInvocation;
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
      NamedArgument
        name: b
        colon: :
        argumentExpression: BooleanLiteral
          literal: true
          staticType: bool
        correspondingParameter: <testLibrary>::@function::foo::@formalParameter::b
    rightParenthesis: )
  staticInvokeType: void Function(int, {required bool b})
  staticType: void
''');
  }

  test_typeArgumentTypes_generic_inferred() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
U foo<T, U>(T a) => throw Error();

main() {
  bool v = foo(0);
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T extends Object>(T? value) {}

void f(dynamic o) {
  foo(o);
}
''');

    var node = result.findNode.methodInvocation('foo(o)');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T extends Object>(List<T?> value) {}

void f(List<void> o) {
  foo(o);
}
''');

    var node = result.findNode.methodInvocation('foo(o)');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo<T extends num>() {}

main() {
  foo();
}
''');

    var node = result.findNode.methodInvocation('foo();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo<T extends num>() {}

main() {
  foo<bool>();
//    ^^^^
// [diag.typeArgumentNotMatchingBounds] 'bool' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');

    var node = result.findNode.methodInvocation('foo<bool>();');
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
        element: dart:core::@class::bool
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo<T>() {}

main() {
  foo<int, double>();
//   ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 1 type parameters, but 2 type arguments are given.
}
''');

    var node = result.findNode.methodInvocation('foo<int, double>();');
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
        element: dart:core::@class::int
        type: int
      NamedType
        name: double
        element: dart:core::@class::double
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo(int a) {}

main() {
  foo(0);
}
''');

    var node = result.findNode.methodInvocation('foo(0)');
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
