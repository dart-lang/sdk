// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideAccessToStaticMemberTest);
  });
}

@reflectiveTest
class ExtensionOverrideAccessToStaticMemberTest
    extends PubPackageResolutionTest {
  test_call() async {
    await assertErrorsInCode(
      '''
extension E on int {
  static void call() {}
}

void f() {
  E(0)();
}
''',
      [
        error(
          CompileTimeErrorCode.extensionOverrideAccessToStaticMember,
          65,
          2,
        ),
      ],
    );

    var node = findNode.functionExpressionInvocation('();');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <testLibrary>::@extension::E::@method::call
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_getter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static String get empty => '';
}
void f() {
  E('a').empty;
}
''',
      [
        error(
          CompileTimeErrorCode.extensionOverrideAccessToStaticMember,
          79,
          5,
        ),
      ],
    );
  }

  test_getterAndSetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static String get empty => '';
  static void set empty(String s) {}
}
void f() {
  E('a').empty += 'b';
}
''',
      [
        error(
          CompileTimeErrorCode.extensionOverrideAccessToStaticMember,
          116,
          5,
        ),
      ],
    );
  }

  test_method() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static String empty() => '';
}
void f() {
  E('a').empty();
}
''',
      [
        error(
          CompileTimeErrorCode.extensionOverrideAccessToStaticMember,
          77,
          5,
        ),
      ],
    );

    var node = findNode.methodInvocation('empty();');
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
    element2: <testLibrary>::@extension::E
    extendedType: String
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: empty
    element: <testLibrary>::@extension::E::@method::empty
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_setter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static void set empty(String s) {}
}
void f() {
  E('a').empty = 'b';
}
''',
      [
        error(
          CompileTimeErrorCode.extensionOverrideAccessToStaticMember,
          83,
          5,
        ),
      ],
    );
  }
}
