// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParenthesizedExpressionResolutionTest);
  });
}

@reflectiveTest
class ParenthesizedExpressionResolutionTest extends PubPackageResolutionTest {
  test_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    (super);
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 28, 5),
    ]);

    final node = findNode.singleParenthesizedExpression;
    assertResolvedNodeText(node, r'''
ParenthesizedExpression
  leftParenthesis: (
  expression: SuperExpression
    superKeyword: super
    staticType: A
  rightParenthesis: )
  staticType: A
''');
  }
}
