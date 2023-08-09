// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeConstructorWithSuperInvocationTest);
  });
}

@reflectiveTest
class ExtensionTypeConstructorWithSuperInvocationTest
    extends PubPackageResolutionTest {
  test_named() async {
    await assertErrorsInCode('''
extension type E(int it) {
  E.named() : it = 0, super.named();
}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION,
          49,
          5),
    ]);

    final node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: <null>
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
''');
  }

  test_unnamed() async {
    await assertErrorsInCode('''
extension type E(int it) {
  E.named() : it = 0, super();
}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION,
          49,
          5),
    ]);

    final node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
''');
  }
}
