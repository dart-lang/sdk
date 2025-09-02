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
    await assertErrorsInCode(
      '''
extension type E(int it) {
  E.named() : it = 0, super.named();
}
''',
      [
        error(
          CompileTimeErrorCode.extensionTypeConstructorWithSuperInvocation,
          49,
          5,
        ),
      ],
    );

    var node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <null>
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
''');
  }

  test_notLast() async {
    await assertErrorsInCode(
      r'''
extension type const E._(int it) {
  const E(int it) : super._(it), assert(it >= 0);
}
''',
      [
        error(CompileTimeErrorCode.finalNotInitializedConstructor1, 43, 1),
        error(
          CompileTimeErrorCode.extensionTypeConstructorWithSuperInvocation,
          55,
          5,
        ),
      ],
    );
  }

  test_unnamed() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {
  E.named() : it = 0, super();
}
''',
      [
        error(
          CompileTimeErrorCode.extensionTypeConstructorWithSuperInvocation,
          49,
          5,
        ),
      ],
    );

    var node = findNode.singleSuperConstructorInvocation;
    assertResolvedNodeText(node, r'''
SuperConstructorInvocation
  superKeyword: super
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
''');
  }
}
