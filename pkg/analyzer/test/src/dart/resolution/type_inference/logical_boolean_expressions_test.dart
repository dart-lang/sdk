// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndTest);
    defineReflectiveTests(LogicalOrTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LogicalAndTest extends PubPackageResolutionTest {
  test_downward() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(b) {
  var c = a() && b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');

    var node = result.findNode.singleLogicalAnd;
    assertResolvedNodeText(node, r'''
LogicalAnd
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::a
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  operator: &&
  rightOperand: CallInvocation
    receiver: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: dynamic
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: DynamicInvocationResolution
      type: dynamic
    staticType: dynamic
  staticType: bool
V1: BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::a
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  operator: &&
  rightOperand: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: dynamic
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: dynamic
    staticType: dynamic
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_upward() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(bool a, bool b) {
  var c = a && b;
  print(c);
}
''');

    var node = result.findNode.singleLogicalAnd;
    assertResolvedNodeText(node, r'''
LogicalAnd
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: bool
  operator: &&
  rightOperand: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  staticType: bool
V1: BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: bool
  operator: &&
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }
}

@reflectiveTest
class LogicalOrTest extends PubPackageResolutionTest {
  test_downward() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(b) {
  var c = a() || b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');

    var node = result.findNode.singleLogicalOr;
    assertResolvedNodeText(node, r'''
LogicalOr
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::a
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  operator: ||
  rightOperand: CallInvocation
    receiver: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: dynamic
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    resolution: DynamicInvocationResolution
      type: dynamic
    staticType: dynamic
  staticType: bool
V1: BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::a
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: bool Function()
    staticType: bool
    typeArgumentTypes
      bool
  operator: ||
  rightOperand: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: dynamic
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: dynamic
    staticType: dynamic
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_upward() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(bool a, bool b) {
  var c = a || b;
  print(c);
}
''');

    var node = result.findNode.singleLogicalOr;
    assertResolvedNodeText(node, r'''
LogicalOr
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: bool
  operator: ||
  rightOperand: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  staticType: bool
V1: BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: bool
  operator: ||
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }
}
