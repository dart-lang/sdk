// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExtensionArgumentCountTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidExtensionArgumentCountTest extends PubPackageResolutionTest {
  test_many() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
f() {
  E('a', 'b', 'c').m();
// ^^^^^^^^^^^^^^^
// [diag.invalidExtensionArgumentCount] Extension overrides must have exactly one argument: the value of 'this' in the extension method.
}
''');
    var node = result.findNode.receiverMethodInvocation('E(');
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        SimpleStringLiteral
          literal: 'a'
        SimpleStringLiteral
          literal: 'b'
        SimpleStringLiteral
          literal: 'c'
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
  operator: .
  name: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extension::E::@method::m
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleStringLiteral
          literal: 'a'
        SimpleStringLiteral
          literal: 'b'
        SimpleStringLiteral
          literal: 'c'
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_many_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
void f() {
  E('a', 'b')?.m();
// ^^^^^^^^^^
// [diag.invalidExtensionArgumentCount] Extension overrides must have exactly one argument: the value of 'this' in the extension method.
}
''');
    var node = result.findNode.receiverMethodInvocation('E(');
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        SimpleStringLiteral
          literal: 'a'
        SimpleStringLiteral
          literal: 'b'
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
  operator: ?.
  name: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extension::E::@method::m
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleStringLiteral
          literal: 'a'
        SimpleStringLiteral
          literal: 'b'
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_one() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
f() {
  E('a').m();
}
''');
  }

  test_zero() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
f() {
  E().m();
// ^^
// [diag.invalidExtensionArgumentCount] Extension overrides must have exactly one argument: the value of 'this' in the extension method.
}
''');
    var node = result.findNode.receiverMethodInvocation('E(');
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
  operator: .
  name: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@extension::E::@method::m
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@extension::E::@method::m
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_zero_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  int operator [](int index) => 0;
}
void f() {
  E()?[0];
// ^^
// [diag.invalidExtensionArgumentCount] Extension overrides must have exactly one argument: the value of 'this' in the extension method.
}
''');
    var node = result.findNode.receiverIndexExpression('E(');
    assertResolvedNodeText(node, r'''
ReceiverIndexExpression
  receiver: ExtensionOverride2
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  resolution: MethodIndexReadResolution
    element: <testLibrary>::@extension::E::@method::[]
    invokeType: int Function(int)
    type: int
  staticType: int
V1: IndexExpression
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: dynamic
    staticType: null
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@extension::E::@method::[]
  staticType: int
''');
  }
}
