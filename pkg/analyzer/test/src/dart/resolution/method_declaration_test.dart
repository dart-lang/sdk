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
  test_augmentation_formalParameter_missingInAugmentation() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int x);
//     ^^^
// [context 1] The declaration being augmented.
}

augment class A {
  augment void foo() {
//                 ^
// [diag.augmentationRequiredPositionalFormalParameterCount][context 1] The augmentation has 0 required positional formal parameters, but the declaration has 1.
    x;
//  ^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'x'.
  }
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: x
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: SimpleIdentifier
  token: x
  element: <null>
  staticType: InvalidType
''');
  }

  test_augmentation_formalParameter_onlyInAugmentation() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo();
//     ^^^
// [context 1] The declaration being augmented.
}

augment class A {
  augment void foo([int x = 0]) {
//                 ^
// [diag.augmentationOptionalPositionalFormalParameterCount][context 1] The augmentation has 1 optional positional formal parameters, but the declaration has 0.
    x;
  }
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: x
  resolution: VariableReadResolution
    element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
    type: int
  staticType: int
V1: SimpleIdentifier
  token: x
  element: <testLibrary>::@class::A::@method::foo::@formalParameter::x
  staticType: int
''');
  }

  test_formalParameterScope_defaultValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static const foo = 0;

  void bar([int foo = foo + 1]) {
  }
}
''');

    var node = result.findNode.unqualifiedNameExpression('foo + 1');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    type: int
  staticType: int
V1: SimpleIdentifier
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

    var node2 = result.findNode.unqualifiedNameExpression('a;');
    assertResolvedNodeText(node2, r'''
UnqualifiedNameExpression
  name: a
  resolution: VariableReadResolution
    element: <testLibrary>::@class::B::@method::bar::@formalParameter::a
    type: a
  staticType: a
V1: SimpleIdentifier
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

    var node = result.findNode.unqualifiedNameExpression('_;');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: _
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::_
    type: int
  staticType: int
V1: SimpleIdentifier
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
MethodDeclaration2
  name: _
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> _@12
    element: <testLibrary>::@class::C::@method::_
      type: dynamic Function()
V1: MethodDeclaration
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

  test_wildCardMethod_beforeWildcardVariables() async {
    var result = await resolveTestCodeWithDiagnostics('''
// %before-language-feature: wildcard-variables

class C {
  _() {}
//^
// [diag.unusedElement] The declaration '_' isn't referenced.
}
''');

    var node = result.findNode.methodDeclaration('_()');
    assertResolvedNodeText(node, r'''
MethodDeclaration2
  name: _
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> _@28
    element: <testLibrary>::@class::C::@method::_
      type: dynamic Function()
V1: MethodDeclaration
  name: _
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> _@28
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
    var node = result.findNode.localVariable('_ = _;');
    assertResolvedNodeText(node, r'''
LocalVariable
  name: _
  equals: =
  initializer: UnqualifiedNameExpression
    name: _
    resolution: GetterInvocationResolution
      element: <testLibrary>::@class::C::@getter::_
      type: int
    staticType: int
  declaredFragment: isPrivate _@51
    element: isPrivate
      type: int
''');
  }
}
