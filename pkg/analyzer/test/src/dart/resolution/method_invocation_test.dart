// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodInvocationResolutionTest);
  });
}

@reflectiveTest
class MethodInvocationResolutionTest extends PubPackageResolutionTest {
  test_arguments_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    g(super);
  }
}

void g(Object a) {}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 29, 5),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    staticElement: <testLibraryFragment>::@function::g
    element: <testLibraryFragment>::@function::g#element
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
    await assertErrorsInCode(r'''
void f() {
  g(,,);
}

void g(int a, int b) {}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 15, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 16, 1),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    staticElement: <testLibraryFragment>::@function::g
    element: <testLibraryFragment>::@function::g#element
    staticType: void Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: <empty> <synthetic>
        parameter: <testLibraryFragment>::@function::g::@parameter::a
        staticElement: <null>
        element: <null>
        staticType: InvalidType
      SimpleIdentifier
        token: <empty> <synthetic>
        parameter: <testLibraryFragment>::@function::g::@parameter::b
        staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  cascadeSections
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@class::A::@method::foo
        element: <testLibraryFragment>::@class::A::@method::foo#element
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
        staticElement: <testLibraryFragment>::@class::A::@method::bar
        element: <testLibraryFragment>::@class::A::@method::bar#element
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
    staticElement: <testLibraryFragment>::@function::h
    element: <testLibraryFragment>::@function::h#element
    staticType: dynamic Function(double)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@function::g::@parameter::a
          element: <testLibraryFragment>::@function::g::@parameter::a#element
          staticType: double
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::<fragment>::@class::num::@method::clamp
          element: dart:core::<fragment>::@class::num::@method::clamp#element
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: double Function()
              staticType: double
              typeArgumentTypes
                double
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: double Function()
              staticType: double
              typeArgumentTypes
                double
          rightParenthesis: )
        parameter: <testLibraryFragment>::@function::h::@parameter::x
        staticInvokeType: num Function(num, num)
        staticType: double
    rightParenthesis: )
  staticInvokeType: dynamic Function(double)
  staticType: dynamic
''');
  }

  test_clamp_double_context_int() async {
    await assertErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 45, 17),
    ]);

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: <testLibraryFragment>::@function::h
    element: <testLibraryFragment>::@function::h#element
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@function::g::@parameter::a
          element: <testLibraryFragment>::@function::g::@parameter::a#element
          staticType: double
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::<fragment>::@class::num::@method::clamp
          element: dart:core::<fragment>::@class::num::@method::clamp#element
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
          rightParenthesis: )
        parameter: <testLibraryFragment>::@function::h::@parameter::x
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
    staticElement: <testLibraryFragment>::@function::g::@parameter::a
    element: <testLibraryFragment>::@function::g::@parameter::a#element
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_context_double() async {
    await assertErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 17),
    ]);

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: <testLibraryFragment>::@function::h
    element: <testLibraryFragment>::@function::h#element
    staticType: dynamic Function(double)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@function::g::@parameter::a
          element: <testLibraryFragment>::@function::g::@parameter::a#element
          staticType: int
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::<fragment>::@class::num::@method::clamp
          element: dart:core::<fragment>::@class::num::@method::clamp#element
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
          rightParenthesis: )
        parameter: <testLibraryFragment>::@function::h::@parameter::x
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
    staticElement: <testLibraryFragment>::@function::h
    element: <testLibraryFragment>::@function::h#element
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@function::g::@parameter::a
          element: <testLibraryFragment>::@function::g::@parameter::a#element
          staticType: int
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::<fragment>::@class::num::@method::clamp
          element: dart:core::<fragment>::@class::num::@method::clamp#element
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: int Function()
              staticType: int
              typeArgumentTypes
                int
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: int Function()
              staticType: int
              typeArgumentTypes
                int
          rightParenthesis: )
        parameter: <testLibraryFragment>::@function::h::@parameter::x
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
    staticElement: <testLibraryFragment>::@function::g::@parameter::a
    element: <testLibraryFragment>::@function::g::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: dynamic
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: dynamic
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: int
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: int
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: <testLibraryFragment>::@extension::E::@method::clamp
    element: <testLibraryFragment>::@extension::E::@method::clamp#element
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <testLibraryFragment>::@extension::E::@method::clamp::@parameter::x
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: <testLibraryFragment>::@extension::E::@method::clamp::@parameter::y
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: Never
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_int_never_int() async {
    await assertErrorsInCode('''
f(int a, Never b, int c) {
  a.clamp(b, c);
}
''', [
      error(WarningCode.DEAD_CODE, 40, 3),
    ]);

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::<fragment>::@class::num::@method::clamp
    element: dart:core::<fragment>::@class::num::@method::clamp#element
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: Never
      SimpleIdentifier
        token: c
        parameter: dart:core::<fragment>::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
  }

  test_clamp_never_int_int() async {
    await assertErrorsInCode('''
f(Never a, int b, int c) {
  a.clamp(b, c);
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 29, 1),
      error(WarningCode.DEAD_CODE, 36, 7),
    ]);

    var node = findNode.methodInvocation('clamp');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <null>
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: <null>
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_clamp_other_context_int() async {
    await assertErrorsInCode('''
abstract class A {
  num clamp(String x, String y);
}
T f<T>() => throw Error();
g(A a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 94, 17),
    ]);

    var node = findNode.methodInvocation('h(a');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: <testLibraryFragment>::@function::h
    element: <testLibraryFragment>::@function::h#element
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@function::g::@parameter::a
          element: <testLibraryFragment>::@function::g::@parameter::a#element
          staticType: A
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: <testLibraryFragment>::@class::A::@method::clamp
          element: <testLibraryFragment>::@class::A::@method::clamp#element
          staticType: num Function(String, String)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: <testLibraryFragment>::@class::A::@method::clamp::@parameter::x
              staticInvokeType: String Function()
              staticType: String
              typeArgumentTypes
                String
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: <testLibraryFragment>::@function::f
                element: <testLibraryFragment>::@function::f#element
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: <testLibraryFragment>::@class::A::@method::clamp::@parameter::y
              staticInvokeType: String Function()
              staticType: String
              typeArgumentTypes
                String
          rightParenthesis: )
        parameter: <testLibraryFragment>::@function::h::@parameter::x
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: <testLibraryFragment>::@class::A::@method::clamp
    element: <testLibraryFragment>::@class::A::@method::clamp#element
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <testLibraryFragment>::@class::A::@method::clamp::@parameter::x
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: <testLibraryFragment>::@class::A::@method::clamp::@parameter::y
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: <testLibraryFragment>::@extension::E::@method::clamp
    element: <testLibraryFragment>::@extension::E::@method::clamp#element
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <testLibraryFragment>::@extension::E::@method::clamp::@parameter::x
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: <testLibraryFragment>::@extension::E::@method::clamp::@parameter::y
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: <testLibraryFragment>::@extension::E::@method::clamp
    element: <testLibraryFragment>::@extension::E::@method::clamp#element
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <testLibraryFragment>::@extension::E::@method::clamp::@parameter::x
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      SimpleIdentifier
        token: c
        parameter: <testLibraryFragment>::@extension::E::@method::clamp::@parameter::y
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
  }

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
    staticElement: <testLibraryFragment>::@function::test
    element: <testLibraryFragment>::@function::test#element
    staticType: void Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        parameter: ParameterMember
          base: <testLibraryFragment>::@function::test::@parameter::t
          substitution: {T: S}
        staticElement: <testLibraryFragment>::@function::f::@parameter::s
        element: <testLibraryFragment>::@function::f::@parameter::s#element
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

    await assertErrorsInCode(r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 46, 3),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::<fragment>::@function::foo::@parameter::_
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

    await assertErrorsInCode(r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 58, 3),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@prefix::p
    element: <testLibraryFragment>::@prefix2::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::<fragment>::@function::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_error_instanceAccessToStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo(int _) {}
}

void f(A a) {
  a.foo(0);
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 59, 3),
    ]);

    var node = findNode.methodInvocation('a.foo(0)');
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_error_invocationOfNonFunction_interface_hasCall_field() async {
    await assertErrorsInCode(r'''
class C {
  void Function() call = throw Error();
}

void f(C c) {
  c();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 69, 1),
    ]);

    var node = findNode.functionExpressionInvocation('c();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@getter::foo
      element: <testLibraryFragment>::@class::C::@getter::foo#element
      staticType: dynamic
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::C::@getter::foo
    element: <testLibraryFragment>::@class::C::@getter::foo#element
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::foo
    element: <testLibraryFragment>::@function::f::@parameter::foo#element
    staticType: Function
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int
      IntegerLiteral
        literal: 2
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::C::@getter::foo
    element: <testLibraryFragment>::@class::C::@getter::foo#element
    staticType: double Function(int)
      alias: <testLibraryFragment>::@typeAlias::MyFunction
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::_
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: double Function(int)
    alias: <testLibraryFragment>::@typeAlias::MyFunction
  staticType: double
''');
  }

  test_error_invocationOfNonFunction_parameter() async {
    await assertErrorsInCode(r'''
main(Object foo) {
  foo();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 21, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::main::@parameter::foo
    element: <testLibraryFragment>::@function::main::@parameter::foo#element
    staticType: Object
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::main::@parameter::foo
    element: <testLibraryFragment>::@function::main::@parameter::foo#element
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_invocationOfNonFunction_static_hasTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;
}

main() {
  C.foo();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 46, 5),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: C
      staticElement: <testLibraryFragment>::@class::C
      element: <testLibraryFragment>::@class::C#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@getter::foo
      element: <testLibraryFragment>::@class::C::@getter::foo#element
      staticType: int
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_invocationOfNonFunction_static_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;

  main() {
    foo();
  }
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 48, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::C::@getter::foo
    element: <testLibraryFragment>::@class::C::@getter::foo#element
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_invocationOfNonFunction_super_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
  }
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 68, 9),
    ]);

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
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: int
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_prefixIdentifierNotFollowedByDot() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 6),
    ]);

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    staticElement: <testLibraryFragment>::@prefix::prefix
    element: <testLibraryFragment>::@prefix2::prefix
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@function::foo
    element: package:test/a.dart::<fragment>::@function::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_error_prefixIdentifierNotFollowedByDot_deferred() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 49, 4),
    ]);

    var node = findNode.methodInvocation('loadLibrary()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: <testLibraryFragment>::@prefix::math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: loadLibrary@-1
    element: loadLibrary@-1
    staticType: Future<dynamic> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>?
''');
  }

  test_error_prefixIdentifierNotFollowedByDot_invoke() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;

main() {
  foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 3),
    ]);

    var node = findNode.methodInvocation('foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@prefix::foo
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
    await assertErrorsInCode(r'''
main() {
  foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 11, 3),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
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

  test_error_undefinedFunction_hasTarget_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 45, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: <testLibraryFragment>::@prefix::math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
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

  test_error_undefinedIdentifier_target() async {
    await assertErrorsInCode(r'''
main() {
  bar.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 11, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: bar
    staticElement: <null>
    element: <null>
    staticType: InvalidType
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

  test_error_undefinedMethod_hasTarget_class() async {
    await assertErrorsInCode(r'''
class C {}
main() {
  C.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: <testLibraryFragment>::@class::C
    element: <testLibraryFragment>::@class::C#element
    staticType: null
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

  test_error_undefinedMethod_hasTarget_class_arguments() async {
    await assertErrorsInCode(r'''
class C {}

int x = 0;
main() {
  C.foo(x);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 36, 3),
    ]);

    var node = findNode.methodInvocation('foo(x);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: <testLibraryFragment>::@class::C
    element: <testLibraryFragment>::@class::C#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: x
        parameter: <null>
        staticElement: <testLibraryFragment>::@getter::x
        element: <testLibraryFragment>::@getter::x#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_undefinedMethod_hasTarget_class_inSuperclass() async {
    await assertErrorsInCode(r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 76, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: <testLibraryFragment>::@class::C
    element: <testLibraryFragment>::@class::C#element
    staticType: null
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

  test_error_undefinedMethod_hasTarget_class_typeArguments() async {
    await assertErrorsInCode(r'''
class C {}

main() {
  C.foo<int>();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);

    var node = findNode.methodInvocation('foo<int>();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: <testLibraryFragment>::@class::C
    element: <testLibraryFragment>::@class::C#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
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
  staticInvokeType: InvalidType
  staticType: InvalidType
  typeArgumentTypes
    int
''');
  }

  test_error_undefinedMethod_hasTarget_class_typeParameter() async {
    await assertErrorsInCode(r'''
class C<T> {
  static main() => C.T();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 34, 1),
    ]);

    var node = findNode.methodInvocation('C.T();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: <testLibraryFragment>::@class::C
    element: <testLibraryFragment>::@class::C#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: T
    staticElement: <null>
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
    await assertErrorsInCode(r'''
main() {
  42.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 14, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 42
    staticType: int
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

  test_error_undefinedMethod_hasTarget_localVariable_function() async {
    await assertErrorsInCode(r'''
main() {
  var v = () {};
  v.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 30, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: v
    staticElement: v@15
    element: v@15
    staticType: Null Function()
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

  test_error_undefinedMethod_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  main() {
    foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
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

  test_error_undefinedMethod_null() async {
    await assertErrorsInCode(r'''
main() {
  null.foo();
}
''', [
      error(CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE, 16, 3),
    ]);

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: NullLiteral
    literal: null
    staticType: Null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    await assertErrorsInCode(r'''
main(Object o) {
  o.call();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 21, 4),
    ]);
  }

  test_error_undefinedMethod_private() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo(int _) {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 53, 4),
    ]);

    var node = findNode.methodInvocation('_foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: _foo
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

  test_error_undefinedMethod_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 50, 3),
    ]);
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    await assertErrorsInCode(r'''
class A {}
main() {
  A?.toString();
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 23, 2),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 8),
    ]);
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
  }
}
''', [
      error(
          CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          71,
          3),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 75, 1),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
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
    await assertErrorsInCode(r'''
import 'missing.dart' as p;

main() {
  p.foo(1);
  p.bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);

    var node = findNode.methodInvocation('foo(1);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@prefix::p
    element: <testLibraryFragment>::@prefix2::p
    staticType: null
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
        literal: 1
        parameter: <null>
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
    await assertErrorsInCode(r'''
import 'missing.dart' show foo, bar;

main() {
  foo(1);
  bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);

    var node = findNode.methodInvocation('foo(1);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_error_useOfVoidResult_name_getter() async {
    await assertErrorsInCode('''
class C<T>{
  T foo;
  C(this.foo);
}

void f(C<void> c) {
  c.foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 61, 5),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C<void>
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: GetterMember
        base: <testLibraryFragment>::@class::C::@getter::foo
        substitution: {T: void}
      element: <testLibraryFragment>::@class::C::@getter::foo#element
      staticType: void
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_useOfVoidResult_name_localVariable() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: foo@16
    element: foo@16
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_useOfVoidResult_name_topFunction() async {
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo()();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 3),
    ]);

    var node = findNode.methodInvocation('foo()()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_error_useOfVoidResult_name_topVariable() async {
    await assertErrorsInCode(r'''
void foo;

main() {
  foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 22, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_error_useOfVoidResult_receiver() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo.toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@16
    element: foo@16
    staticType: void
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
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
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo..toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
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
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo?.toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.methodInvocation('toString()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@16
    element: foo@16
    staticType: void
  operator: ?.
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
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
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 29, 5),
    ]);

    var node = findNode.methodInvocation('foo<int>()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function()
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
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_21() async {
    await assertErrorsInCode(r'''
Map<T, U> foo<T extends num, U>() => throw Error();

main() {
  foo<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 67, 5),
    ]);

    var node = findNode.methodInvocation('foo<int>()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: Map<T, U> Function<T extends num, U>()
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::g
    element: <testLibraryFragment>::@function::f::@parameter::g#element
    staticType: double Function(int)
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::p
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <testLibraryFragment>::@class::C::@method::call
    element: <testLibraryFragment>::@class::C::@method::call#element
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::C::@method::call::@parameter::p
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
    staticElement: <testLibraryFragment>::@extensionType::A::@method::foo
    element: <testLibraryFragment>::@extensionType::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@extensionType::A::@method::foo
    element: <testLibraryFragment>::@extensionType::A::@method::foo#element
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
      staticElement: <testLibraryFragment>::@class::C
      element: <testLibraryFragment>::@class::C#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@getter::foo
      element: <testLibraryFragment>::@class::C::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::C
    element: <testLibraryFragment>::@class::C#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::C::@method::foo
    element: <testLibraryFragment>::@class::C::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::C::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

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
    element: <testLibraryFragment>::@class::A#element
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
    element: <testLibraryFragment>::@class::A#element
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
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary();
}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
    ]);

    var node = findNode.methodInvocation('loadLibrary()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: <testLibraryFragment>::@prefix::math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: loadLibrary@-1
    element: loadLibrary@-1
    staticType: Future<dynamic> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>
''');
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary_extraArgument() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary(1 + 2);
}
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 66, 5),
    ]);

    var node = findNode.methodInvocation('loadLibrary(1 + 2)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: <testLibraryFragment>::@prefix::math
    element: <testLibraryFragment>::@prefix2::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: loadLibrary@-1
    element: loadLibrary@-1
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
          parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::<fragment>::@class::num::@method::+
        element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: hash
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
      IntegerLiteral
        literal: 1
        parameter: <null>
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
      staticElement: <testLibraryFragment>::@extension::A
      element: <testLibraryFragment>::@extension::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::A::@getter::foo
      element: <testLibraryFragment>::@extension::A::@getter::foo#element
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
      element: <testLibraryFragment>::@extension::A#element
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
    staticElement: <testLibraryFragment>::@extension::A
    element: <testLibraryFragment>::@extension::A#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::A::@method::foo
    element: <testLibraryFragment>::@extension::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@extension::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

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
    element: <testLibraryFragment>::@extension::A#element
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
    staticElement: <testLibraryFragment>::@extensionType::A
    element: <testLibraryFragment>::@extensionType::A#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@method::foo
    element: <testLibraryFragment>::@extensionType::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function(int)
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@function::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T>(T)
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibraryFragment>::@function::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@prefix::prefix
    element: <testLibraryFragment>::@prefix2::prefix
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@function::foo
    element: package:test/a.dart::<fragment>::@function::foo#element
    staticType: T Function<T extends num>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: package:test/a.dart::<fragment>::@function::foo::@parameter::a
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        parameter: ParameterMember
          base: package:test/a.dart::<fragment>::@function::foo::@parameter::b
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@getter::foo
      element: package:test/a.dart::<fragment>::@getter::foo#element
      staticType: T Function<T>(T, T)
    staticElement: package:test/a.dart::<fragment>::@getter::foo
    element: package:test/a.dart::<fragment>::@getter::foo#element
    staticType: T Function<T>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        parameter: ParameterMember
          base: root::@parameter::b
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: foo@44
    element: foo@44
    staticType: Function
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
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
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
    staticType: Function
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@getter::foo
      element: <testLibraryFragment>::@class::C::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::C::@getter::foo
    element: <testLibraryFragment>::@class::C::@getter::foo#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@getter::foo
      element: <testLibraryFragment>::@class::C::@getter::foo#element
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::C::@method::foo
    element: <testLibraryFragment>::@class::C::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::C::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::C::@method::foo
    element: <testLibraryFragment>::@class::C::@method::foo#element
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::C::@method::foo::@parameter::a
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::I2::@method::foo
    element: <testLibraryFragment>::@class::I2::@method::foo#element
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
    staticElement: <testLibraryFragment>::@class::C::@getter::a
    element: <testLibraryFragment>::@class::C::@getter::a#element
    staticType: T
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
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::foo
    element: <testLibraryFragment>::@function::f::@parameter::foo#element
    staticType: Function?
  operator: ?.
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
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
    await assertErrorsInCode(r'''
void f(Function? foo) {
  foo.call();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          30, 4),
    ]);

    var node = findNode.methodInvocation('foo.call()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::f::@parameter::foo
    element: <testLibraryFragment>::@function::f::@parameter::foo#element
    staticType: Function?
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::testShort::@parameter::c
      element: <testLibraryFragment>::@function::testShort::@parameter::c#element
      staticType: C?
    operator: ?.
    methodName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@method::foo
      element: <testLibraryFragment>::@class::C::@method::foo#element
      staticType: C Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: C Function()
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: bar
    staticElement: <testLibraryFragment>::@class::C::@method::bar
    element: <testLibraryFragment>::@class::C::@method::bar#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::C::@getter::foo
      element: <testLibraryFragment>::@class::C::@getter::foo#element
      staticType: void Function(C)
    staticType: void Function(C)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: c
        parameter: root::@parameter::
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: C
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: void Function(C)
  staticType: void
''');
  }

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
    staticElement: <testLibraryFragment>::@function::f::@parameter::e
    element: <testLibraryFragment>::@function::f::@parameter::e#element
    staticType: E
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@enum::E::@method::foo
    element: <testLibraryFragment>::@enum::E::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::e
    element: <testLibraryFragment>::@function::f::@parameter::e#element
    staticType: E
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@mixin::M::@method::foo
    element: <testLibraryFragment>::@mixin::M::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@method::foo
    element: <testLibraryFragment>::@extensionType::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@method::foo
    element: <testLibraryFragment>::@extensionType::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_extensionType_declared_nullableType() async {
    await assertErrorsInCode(r'''
extension type A(int it) {
  int foo() => 0;
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          67, 3),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@method::foo
    element: <testLibraryFragment>::@extensionType::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@method::foo
    element: <testLibraryFragment>::@extensionType::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: X
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_extensionType_notExposed() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  void foo() {}
}

extension type X(B it) implements A {}

void f(X x) {
  x.foo();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 109, 3),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: X
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: X
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::X::@method::foo
    element: <testLibraryFragment>::@extensionType::X::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

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
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

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
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightBracket: }
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: dart:core::<fragment>::@class::int::@method::toString
    element: dart:core::<fragment>::@class::int::@method::toString#element
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_hasReceiver_interfaceTypeQ_defined() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          48, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceTypeQ_defined_extension() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          86, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: <testLibraryFragment>::@extension::E::@method::foo
      substitution: {T: int}
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_interfaceTypeQ_notDefined() async {
    await assertErrorsInCode(r'''
class A {}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          31, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          69, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
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
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        staticElement: package:test/a.dart::<fragment>::@class::C
        element: package:test/a.dart::<fragment>::@class::C#element
        staticType: null
      staticElement: package:test/a.dart::<fragment>::@class::C
      element: package:test/a.dart::<fragment>::@class::C#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::C::@getter::foo
      element: package:test/a.dart::<fragment>::@class::C::@getter::foo#element
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: C
      staticElement: package:test/a.dart::<fragment>::@class::C
      element: package:test/a.dart::<fragment>::@class::C#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::C
    element: package:test/a.dart::<fragment>::@class::C#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@class::C::@method::foo
    element: package:test/a.dart::<fragment>::@class::C::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::<fragment>::@class::C::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@extension::E::@method::foo::@parameter::a
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@extension::E::@method::foo::@parameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_recordQ_notDefined_extension() async {
    await assertErrorsInCode(r'''
extension E on (int, String) {
  void foo(int a) {}
}

void f((int, String)? r) {
  r.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          86, 3),
    ]);

    var node = findNode.methodInvocation('r.foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: r
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)?
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

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
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
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
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
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
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::t
    element: <testLibraryFragment>::@function::f::@parameter::t#element
    staticType: T & int
  operator: .
  methodName: SimpleIdentifier
    token: abs
    staticElement: dart:core::<fragment>::@class::int::@method::abs
    element: dart:core::<fragment>::@class::int::@method::abs#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: T & U
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::B::@method::foo
    element: <testLibraryFragment>::@class::B::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_identifier_class_field() async {
    await assertErrorsInCode(r'''
class A {
  final foo = 0;

  void f() {
    foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 45, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: int
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::foo
    element: <testLibraryFragment>::@function::f::@parameter::foo#element
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

  test_identifier_topLevelFunction_arguments_duplicateNamed() async {
    await assertErrorsInCode('''
final a = 0;

void foo({int? p}) {}

void f() {
  foo(p: 0, p: a);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 60, 1),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function({int? p})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: p
            staticElement: <testLibraryFragment>::@function::foo::@parameter::p
            element: <testLibraryFragment>::@function::foo::@parameter::p#element
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
        parameter: <testLibraryFragment>::@function::foo::@parameter::p
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: p
            staticElement: <testLibraryFragment>::@function::foo::@parameter::p
            element: <testLibraryFragment>::@function::foo::@parameter::p#element
            staticType: null
          colon: :
        expression: SimpleIdentifier
          token: a
          staticElement: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
          staticType: int
        parameter: <testLibraryFragment>::@function::foo::@parameter::p
    rightParenthesis: )
  staticInvokeType: void Function({int? p})
  staticType: void
''');
  }

  test_identifier_topLevelVariable() async {
    await assertErrorsInCode(r'''
final foo = 0;

void f() {
  foo(0);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 29, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
    staticType: int
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
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::p
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: E Function<E>(A<E>)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      ThisExpression
        thisKeyword: this
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::A::@method::foo::@parameter::p
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@function::foo::@parameter::a
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibraryFragment>::@function::foo::@parameter::a
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
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    await assertErrorsInCode(r'''
class A {
  static int foo(int _) => 0;
}

const a = 0;
const b = A.foo(a);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION, 66, 8),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: int Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::_
        staticElement: <testLibraryFragment>::@getter::a
        element: <testLibraryFragment>::@getter::a#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_invalidConst_expression_instanceMethod() async {
    await assertErrorsInCode(r'''
const a = 0;
const b = 'abc'.codeUnitAt(a);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION, 23, 19),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleStringLiteral
    literal: 'abc'
  operator: .
  methodName: SimpleIdentifier
    token: codeUnitAt
    staticElement: dart:core::<fragment>::@class::String::@method::codeUnitAt
    element: dart:core::<fragment>::@class::String::@method::codeUnitAt#element
    staticType: int Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        parameter: dart:core::<fragment>::@class::String::@method::codeUnitAt::@parameter::index
        staticElement: <testLibraryFragment>::@getter::a
        element: <testLibraryFragment>::@getter::a#element
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
    staticElement: g@20
    element: g@20
    staticType: double Function(int, String)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: g@20::@parameter::a
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
    staticElement: g@15
    element: g@15
    staticType: T Function<T, U>(T, U)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: g@15::@parameter::a
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
    staticElement: g@15
    element: g@15
    staticType: T Function<T>([T?])
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: g@15::@parameter::a
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
    staticElement: g@15
    element: g@15
    staticType: T Function<T>({required T a})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
            staticElement: ParameterMember
              base: g@15::@parameter::a
              substitution: {T: int}
            element: g@15::@parameter::a#element
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
        parameter: ParameterMember
          base: g@15::@parameter::a
          substitution: {T: int}
    rightParenthesis: )
  staticInvokeType: int Function({required int a})
  staticType: int
  typeArgumentTypes
    int
''');
  }

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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function({int? a, bool? b})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            staticElement: <testLibraryFragment>::@function::foo::@parameter::b
            element: <testLibraryFragment>::@function::foo::@parameter::b#element
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: false
          staticType: bool
        parameter: <testLibraryFragment>::@function::foo::@parameter::b
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
            staticElement: <testLibraryFragment>::@function::foo::@parameter::a
            element: <testLibraryFragment>::@function::foo::@parameter::a#element
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
        parameter: <testLibraryFragment>::@function::foo::@parameter::a
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function(A, B, {C? c, D? d})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: g1
          staticElement: <testLibraryFragment>::@function::g1
          element: <testLibraryFragment>::@function::g1#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: <testLibraryFragment>::@function::foo::@parameter::a
        staticInvokeType: A Function()
        staticType: A
        typeArgumentTypes
          A
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            staticElement: <testLibraryFragment>::@function::foo::@parameter::c
            element: <testLibraryFragment>::@function::foo::@parameter::c#element
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g3
            staticElement: <testLibraryFragment>::@function::g3
            element: <testLibraryFragment>::@function::g3#element
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: C? Function()
          staticType: C?
          typeArgumentTypes
            C?
        parameter: <testLibraryFragment>::@function::foo::@parameter::c
      MethodInvocation
        methodName: SimpleIdentifier
          token: g2
          staticElement: <testLibraryFragment>::@function::g2
          element: <testLibraryFragment>::@function::g2#element
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: <testLibraryFragment>::@function::foo::@parameter::b
        staticInvokeType: B Function()
        staticType: B
        typeArgumentTypes
          B
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: d
            staticElement: <testLibraryFragment>::@function::foo::@parameter::d
            element: <testLibraryFragment>::@function::foo::@parameter::d#element
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g4
            staticElement: <testLibraryFragment>::@function::g4
            element: <testLibraryFragment>::@function::g4#element
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: D? Function()
          staticType: D?
          typeArgumentTypes
            D?
        parameter: <testLibraryFragment>::@function::foo::@parameter::d
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
    staticElement: <null>
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
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::C::@getter::foo
    element: <testLibraryFragment>::@class::C::@getter::foo#element
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

  test_noReceiver_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 40, 4),
    ]);

    var node = findNode.methodInvocation('math()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: math
    staticElement: <testLibraryFragment>::@prefix::math
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
    staticElement: foo@16
    element: foo@16
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: foo@16::@parameter::_
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::C::@method::call::@parameter::_
        staticType: int
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@class::C::@method::call
  element: <testLibraryFragment>::@class::C::@method::call#element
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
    staticElement: foo@15
    element: foo@15
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: @-1
        staticType: int
    rightParenthesis: )
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@class::C::@method::foo
    element: <testLibraryFragment>::@class::C::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::C::@method::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::foo
    element: <testLibraryFragment>::@function::f::@parameter::foo#element
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
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
    staticType: double Function(int)?
  operator: ?.
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: root::@parameter::
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: void Function()
      alias: <testLibraryFragment>::@typeAlias::F
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: void Function()
    alias: <testLibraryFragment>::@typeAlias::F
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@function::foo::@parameter::_
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
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  cascadeSections
    MethodInvocation
      operator: ?..
      methodName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@class::A::@method::foo
        element: <testLibraryFragment>::@class::A::@method::foo#element
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
        staticElement: <testLibraryFragment>::@class::A::@method::bar
        element: <testLibraryFragment>::@class::A::@method::bar#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  cascadeSections
    PropertyAccess
      operator: ?..
      propertyName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@class::A::@getter::foo
        element: <testLibraryFragment>::@class::A::@getter::foo#element
        staticType: int
      staticType: int
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: bar
        staticElement: <testLibraryFragment>::@class::A::@method::bar
        element: <testLibraryFragment>::@class::A::@method::bar#element
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
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
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
          staticElement: <testLibraryFragment>::@class::A::@method::foo
          element: <testLibraryFragment>::@class::A::@method::foo#element
          staticType: int? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int? Function()
        staticType: int?
      operator: ?.
      methodName: SimpleIdentifier
        token: abs
        staticElement: dart:core::<fragment>::@class::int::@method::abs
        element: dart:core::<fragment>::@class::int::@method::abs#element
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <null>
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: dart:core::<fragment>::@class::Object::@method::toString
    element: dart:core::<fragment>::@class::Object::@method::toString#element
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
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: void Function()
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: dart:core::<fragment>::@class::Object::@method::toString
    element: dart:core::<fragment>::@class::Object::@method::toString#element
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

    var element = findNode.simple('a:').staticElement!;
    // See https://github.com/dart-lang/sdk/issues/54669 for why we check for
    // isNotNull despite #50660 suggesting the source would be null.
    expect(element.source, isNotNull);
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
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::<fragment>::@class::num::@method::remainder::@parameter::other
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
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::<fragment>::@class::num::@method::remainder::@parameter::other
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
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::<fragment>::@class::num::@method::remainder::@parameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_remainder_int_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
extension E on int {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 98, 19),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: <testLibraryFragment>::@extension::E::@method::remainder::@parameter::x
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
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::<fragment>::@class::num::@method::remainder::@parameter::other
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: dart:core::<fragment>::@class::num::@method::remainder
    element: dart:core::<fragment>::@class::num::@method::remainder#element
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::remainder::@parameter::other
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: dart:core::<fragment>::@class::num::@method::remainder
    element: dart:core::<fragment>::@class::num::@method::remainder#element
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::remainder::@parameter::other
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: dart:core::<fragment>::@class::num::@method::remainder
    element: dart:core::<fragment>::@class::num::@method::remainder#element
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::remainder::@parameter::other
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_remainder_other_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 19),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: <testLibraryFragment>::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_remainder_other_context_int_via_extension_implicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a.remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 16),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::f
    element: <testLibraryFragment>::@function::f#element
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: <testLibraryFragment>::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
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
    staticElement: <testLibraryFragment>::@mixin::M::@method::foo
    element: <testLibraryFragment>::@mixin::M::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_superQualifier_identifier_unresolved_inClass() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 62, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
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

  test_superQualifier_identifier_unresolved_inEnum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void f() {
    super.foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 37, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: E
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

  test_superQualifier_identifier_unresolved_inMixin() async {
    await assertErrorsInCode(r'''
class A {}

mixin M on A {
  void bar() {
    super.foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 52, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: M
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

  test_syntheticName() async {
    // This code is invalid, and the constructor initializer has a method
    // invocation with a synthetic name. But we should still resolve the
    // invocation, and resolve all its arguments.
    await assertErrorsInCode(r'''
class A {
  A() : B(1 + 2, [0]);
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 18, 1),
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 13),
    ]);

    var node = findNode.methodInvocation(');');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: <empty> <synthetic>
    staticElement: <null>
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
          parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::<fragment>::@class::num::@method::+
        element: dart:core::<fragment>::@class::num::@method::+#element
        staticInvokeType: num Function(num)
        staticType: int
      ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 0
            staticType: int
        rightBracket: ]
        parameter: <null>
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function(int, {required bool b})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@function::foo::@parameter::a
        staticType: int
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            staticElement: <testLibraryFragment>::@function::foo::@parameter::b
            element: <testLibraryFragment>::@function::foo::@parameter::b#element
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: true
          staticType: bool
        parameter: <testLibraryFragment>::@function::foo::@parameter::b
    rightParenthesis: )
  staticInvokeType: void Function(int, {required bool b})
  staticType: void
''');
  }

  test_typeArgumentTypes_generic_inferred() async {
    await assertErrorsInCode(r'''
U foo<T, U>(T a) => throw Error();

main() {
  bool v = foo(0);
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 52, 1),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: U Function<T, U>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: <testLibraryFragment>::@function::foo::@parameter::a
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T extends Object>(T?)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: o
        parameter: ParameterMember
          base: <testLibraryFragment>::@function::foo::@parameter::value
          substitution: {T: Object}
        staticElement: <testLibraryFragment>::@function::f::@parameter::o
        element: <testLibraryFragment>::@function::f::@parameter::o#element
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T extends Object>(List<T?>)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: o
        parameter: ParameterMember
          base: <testLibraryFragment>::@function::foo::@parameter::value
          substitution: {T: Object}
        staticElement: <testLibraryFragment>::@function::f::@parameter::o
        element: <testLibraryFragment>::@function::f::@parameter::o#element
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
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
    await assertErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo<bool>();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 45, 4),
    ]);

    var node = findNode.methodInvocation('foo<bool>();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T extends num>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::<fragment>::@class::bool
        element2: dart:core::<fragment>::@class::bool#element
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
    await assertErrorsInCode(r'''
void foo<T>() {}

main() {
  foo<int, double>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 32, 13),
    ]);

    var node = findNode.methodInvocation('foo<int, double>();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function<T>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      NamedType
        name: double
        element: dart:core::<fragment>::@class::double
        element2: dart:core::<fragment>::@class::double#element
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
    staticElement: <testLibraryFragment>::@function::foo
    element: <testLibraryFragment>::@function::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@function::foo::@parameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }
}
