// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinInstantiateTest);
  });
}

@reflectiveTest
class MixinInstantiateTest extends PubPackageResolutionTest {
  test_namedConstructor() async {
    await assertErrorsInCode(r'''
mixin M {
  M.named() {}
}

void f() {
  new M.named();
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 1),
      error(CompileTimeErrorCode.MIXIN_INSTANTIATE, 45, 1),
    ]);

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: M
      element: <testLibraryFragment>::@mixin::M
      element2: <testLibraryFragment>::@mixin::M#element
      type: M
    period: .
    name: SimpleIdentifier
      token: named
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: M
''');
  }

  test_unnamedConstructor() async {
    await assertErrorsInCode(r'''
mixin M {}

void f() {
  new M();
}
''', [
      error(CompileTimeErrorCode.MIXIN_INSTANTIATE, 29, 1),
    ]);

    var node = findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: M
      element: <testLibraryFragment>::@mixin::M
      element2: <testLibraryFragment>::@mixin::M#element
      type: M
    staticElement: <null>
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: M
''');
  }
}
