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

    var node = findNode.simple('foo + 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
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

    var node1 = findNode.namedType('a a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: a
  element2: <testLibrary>::@class::a
  type: a
''');

    var node2 = findNode.simple('a;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@class::B::@method::bar::@formalParameter::a
  staticType: a
''');
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
  element: <testLibrary>::@class::A::@getter::_
  staticType: int
''');
  }

  test_wildCardMethod() async {
    await assertErrorsInCode(
      '''
class C {
  _() {}
}
''',
      [error(WarningCode.unusedElement, 12, 1)],
    );

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
  declaredElement: <testLibraryFragment> _@12
    element: <testLibrary>::@class::C::@method::_
      type: dynamic Function()
''');
  }

  test_wildCardMethod_preWildCards() async {
    await assertErrorsInCode(
      '''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  _() {}
}
''',
      [error(WarningCode.unusedElement, 56, 1)],
    );

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
  declaredElement: <testLibraryFragment> _@56
    element: <testLibrary>::@class::C::@method::_
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
    element: <testLibrary>::@class::C::@getter::_
    staticType: int
  declaredFragment: isPrivate _@51
    element: isPrivate
      type: int
''');
  }
}
