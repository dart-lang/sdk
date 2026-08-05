// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named() : it = 0, super.named();
//                    ^^^^^
// [diag.extensionTypeConstructorWithSuperInvocation] Extension type constructors can't include super initializers.
}
''');

    var node = result.findNode.singleSuperConstructorInvocation;
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
    await resolveTestCodeWithDiagnostics(r'''
extension type const E._(int it) {
  const E(int it) : super._(it), assert(it >= 0);
//      ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'it' isn't.
//                  ^^^^^
// [diag.extensionTypeConstructorWithSuperInvocation] Extension type constructors can't include super initializers.
}
''');
  }

  test_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named() : it = 0, super();
//                    ^^^^^
// [diag.extensionTypeConstructorWithSuperInvocation] Extension type constructors can't include super initializers.
}
''');

    var node = result.findNode.singleSuperConstructorInvocation;
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
