// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalFunctionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LocalFunctionResolutionTest extends PubPackageResolutionTest {
  test_defaultValue_functionReference() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  void g({void Function(int _) a = foo}) {}
//     ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
void foo<T>(T _) {}
''');

    var formalParameter = result.findElement.parameter('a');
    expect(formalParameter.constantInitializer, isA<FunctionReference>());
  }

  test_element_block() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f() {
  g() {}
  g();
}
''');

    var element = result.findElement.localFunction('g');
    var fragment = element.firstFragment;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 8);
    expect(element.name, 'g');

    var node = result.findNode.methodInvocation('g();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
f() {
  if (1 > 2)
    g() {}
//  ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
''');
    var node = result.findNode.functionDeclaration('g() {}');
    var fragment = node.declaredFragment!;
    var element = fragment.element;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 23);
    expect(element.name, 'g');
  }

  test_element_switchCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(int a) {
  switch (a) {
    case 1:
      g() {}
      g();
      break;
  }
}
''');

    var element = result.findElement.localFunction('g');
    var fragment = element.firstFragment;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 44);
    expect(element.name, 'g');

    var node = result.findNode.methodInvocation('g();');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var element = result.findElement.localFunction('g');
    var fragment = element.firstFragment;
    expect(fragment.name, 'g');
    expect(fragment.nameOffset, 60);
    expect(element.name, 'g');

    var node = result.findNode.methodInvocation('g();');
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

  test_recursiveReference_ifStatement_nonBlock() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(bool c) {
  if (c)
    g() {
//  ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
      g(); // ref
    }
}
''');

    var node = result.findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: g@25
    staticType: dynamic Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic Function()
  staticType: dynamic
''');
  }
}
