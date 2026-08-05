// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedExtensionMethodTest extends PubPackageResolutionTest {
  test_method_defined() async {
    await resolveTestCodeWithDiagnostics('''
extension E on String {
  int m() => 0;
}
f() {
  E('a').m();
}
''');
  }

  test_method_undefined() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on String {}
f() {
  E('a').m();
//       ^
// [diag.undefinedExtensionMethod] The method 'm' isn't defined for the extension 'E'.
}
''');

    var node = result.findNode.methodInvocation('m();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleStringLiteral
          literal: 'a'
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: String
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_static_withInference() async {
    await resolveTestCodeWithDiagnostics('''
extension E on Object {}
var a = E.m();
//        ^
// [diag.undefinedExtensionMethod] The method 'm' isn't defined for the extension 'E'.
''');
  }

  test_static_withoutInference() async {
    await resolveTestCodeWithDiagnostics('''
extension E on Object {}
void f() {
  E.m();
//  ^
// [diag.undefinedExtensionMethod] The method 'm' isn't defined for the extension 'E'.
}
''');
  }
}
