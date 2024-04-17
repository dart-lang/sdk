// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndTest);
    defineReflectiveTests(LogicalOrTest);
  });
}

@reflectiveTest
class LogicalAndTest extends PubPackageResolutionTest {
  test_downward() async {
    await resolveTestCode('''
void f(b) {
  var c = a() && b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: a
      staticElement: self::@function::a
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
      staticElement: self::@function::f::@parameter::b
      staticType: dynamic
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: dynamic
    staticType: dynamic
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_upward() async {
    await resolveTestCode('''
void f(bool a, bool b) {
  var c = a && b;
  print(c);
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: bool
  operator: &&
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }
}

@reflectiveTest
class LogicalOrTest extends PubPackageResolutionTest {
  test_downward() async {
    await resolveTestCode('''
void f(b) {
  var c = a() || b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: a
      staticElement: self::@function::a
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
      staticElement: self::@function::f::@parameter::b
      staticType: dynamic
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: dynamic
    staticType: dynamic
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_upward() async {
    await resolveTestCode('''
void f(bool a, bool b) {
  var c = a || b;
  print(c);
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: bool
  operator: ||
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }
}
