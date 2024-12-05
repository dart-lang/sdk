// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodDeclarationResolutionTest);
  });
}

@reflectiveTest
class MethodDeclarationResolutionTest extends PubPackageResolutionTest {
  test_formalParameterScope_defaultValue() async {
    await assertNoErrorsInCode('''
class A {
  static const foo = 0;

  void bar([int foo = foo + 1]) {
  }
}
''');

    assertElement(
      findNode.simple('foo + 1'),
      findElement.getter('foo', of: 'A'),
    );
  }

  test_formalParameterScope_type() async {
    await assertNoErrorsInCode('''
class a {}

class B {
  void bar(a a) {
    a;
  }
}
''');

    assertElement(
      findNode.namedType('a a'),
      findElement.class_('a'),
    );

    assertElement(
      findNode.simple('a;'),
      findElement.parameter('a'),
    );
  }

  test_formalParameterScope_wildcardVariable() async {
    await assertNoErrorsInCode('''
class A {
  var _ = 1;
  void m(int? _) {
    _;
  }
}
''');

    var node = findNode.simple('_;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  staticElement: <testLibraryFragment>::@class::A::@getter::_
  element: <testLibraryFragment>::@class::A::@getter::_#element
  staticType: int
''');
  }

  test_wildCardMethod() async {
    await assertErrorsInCode('''
class C {
  _() {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 12, 1),
    ]);

    var node = findNode.methodDeclaration('_');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  name: _
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment>::@class::C::@method::_
    type: dynamic Function()
''');
  }

  test_wildCardMethod_preWildCards() async {
    await assertErrorsInCode('''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  _() {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 56, 1),
    ]);

    var node = findNode.methodDeclaration('_');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  name: _
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment>::@class::C::@method::_
    type: dynamic Function()
''');
  }

  test_wildcardMethodTypeParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  int _ = 0;

  void m<_, _>() {
    int _ = _;
  }
}
''');
    var node = findNode.variableDeclaration('_ = _;');

    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: _
  equals: =
  initializer: SimpleIdentifier
    token: _
    staticElement: <testLibraryFragment>::@class::C::@getter::_
    element: <testLibraryFragment>::@class::C::@getter::_#element
    staticType: int
  declaredElement: _@51
    type: int
''');
  }
}
