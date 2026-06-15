// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodDeclarationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MethodDeclarationResolutionTest extends PubPackageResolutionTest {
  test_formalParameterScope_defaultValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static const foo = 0;

  void bar([int foo = foo + 1]) {
  }
}
''');

    var node = result.findNode.simple('foo + 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  test_formalParameterScope_type() async {
    var result = await resolveTestCodeWithDiagnostics('''
class a {}

class B {
  void bar(a a) {
    a;
  }
}
''');

    var node1 = result.findNode.namedType('a a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: a
  element: <testLibrary>::@class::a
  type: a
''');

    var node2 = result.findNode.simple('a;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@class::B::@method::bar::@formalParameter::a
  staticType: a
''');
  }

  test_formalParameterScope_wildcardVariable() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  var _ = 1;
  void m(int? _) {
    _;
  }
}
''');

    var node = result.findNode.simple('_;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: _
  element: <testLibrary>::@class::A::@getter::_
  staticType: int
''');
  }

  test_wildCardMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  _() {}
//^
// [diag.unusedElement] The declaration '_' isn't referenced.
}
''');

    var node = result.findNode.methodDeclaration('_()');
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
  declaredFragment: <testLibraryFragment> _@12
    element: <testLibrary>::@class::C::@method::_
      type: dynamic Function()
''');
  }

  test_wildCardMethod_preWildCards() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 3.4
// (pre wildcard-variables)

class C {
  _() {}
//^
// [diag.unusedElement] The declaration '_' isn't referenced.
}
''');

    var node = result.findNode.methodDeclaration('_()');
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
  declaredFragment: <testLibraryFragment> _@56
    element: <testLibrary>::@class::C::@method::_
      type: dynamic Function()
''');
  }

  test_wildcardMethodTypeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int _ = 0;

  void m<_, _>() {
    int _ = _;
  }
}
''');
    var node = result.findNode.variableDeclaration('_ = _;');
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
