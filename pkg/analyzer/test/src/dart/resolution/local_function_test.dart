// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalFunctionResolutionTest);
  });
}

@reflectiveTest
class LocalFunctionResolutionTest extends PubPackageResolutionTest {
  test_element_block() async {
    await assertNoErrorsInCode(r'''
f() {
  g() {}
  g();
}
''');

    var element = findElement2.localFunction('g');
    var fragment = element.firstFragment;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 8);
    expect(element.name, 'g');

    var node = findNode.methodInvocation('g();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@8
    staticType: Null Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Null Function()
  staticType: Null
''');
  }

  test_element_ifStatement() async {
    await assertErrorsInCode(
      r'''
f() {
  if (1 > 2)
    g() {}
}
''',
      [error(WarningCode.unusedElement, 23, 1)],
    );
    var node = findNode.functionDeclaration('g() {}');
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 23);
    expect(element.name, 'g');
  }

  test_element_switchCase() async {
    await assertNoErrorsInCode(r'''
f(int a) {
  switch (a) {
    case 1:
      g() {}
      g();
      break;
  }
}
''');

    var element = findElement2.localFunction('g');
    var fragment = element.firstFragment;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 44);
    expect(element.name, 'g');

    var node = findNode.methodInvocation('g();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@44
    staticType: Null Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Null Function()
  staticType: Null
''');
  }

  test_element_switchCase_language219() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
f(int a) {
  switch (a) {
    case 1:
      g() {}
      g();
      break;
  }
}
''');

    var element = findElement2.localFunction('g');
    var fragment = element.firstFragment;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 60);
    expect(element.name, 'g');

    var node = findNode.methodInvocation('g();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@60
    staticType: Null Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Null Function()
  staticType: Null
''');
  }
}
