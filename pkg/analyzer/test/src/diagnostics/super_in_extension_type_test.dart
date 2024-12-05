// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInExtensionTypeTest);
  });
}

@reflectiveTest
class SuperInExtensionTypeTest extends PubPackageResolutionTest {
  test_binaryOperator() async {
    await assertErrorsInCode('''
extension type A(int it) {
  void f() {
    super + 0;
  }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION_TYPE, 44, 5),
    ]);

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
    staticType: A
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_methodInvocation() async {
    await assertErrorsInCode('''
extension type A(int it) {
  void f() {
    super.foo();
  }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION_TYPE, 44, 5),
    ]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: A
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

  test_propertyAccess() async {
    await assertErrorsInCode('''
extension type A(int it) {
  void f() {
    super.foo;
  }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION_TYPE, 44, 5),
    ]);

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
