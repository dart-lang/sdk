// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInExtensionTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperInExtensionTypeTest extends PubPackageResolutionTest {
  test_binaryOperator() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  void f() {
    super + 0;
//  ^^^^^
// [diag.superInExtensionType] The 'super' keyword can't be used in an extension type because an extension type doesn't have a superclass.
  }
}
''');

    var node = result.findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
    staticType: A
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_methodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  void f() {
    super.foo();
//  ^^^^^
// [diag.superInExtensionType] The 'super' keyword can't be used in an extension type because an extension type doesn't have a superclass.
  }
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: A
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

  test_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  void f() {
    super.foo;
//  ^^^^^
// [diag.superInExtensionType] The 'super' keyword can't be used in an extension type because an extension type doesn't have a superclass.
  }
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
