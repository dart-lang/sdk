// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParenthesizedExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ParenthesizedExpressionResolutionTest extends PubPackageResolutionTest {
  test_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    (super);
//   ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singleParenthesizedExpression;
    assertResolvedNodeText(node, r'''
ParenthesizedExpression
  leftParenthesis: (
  expression2: SuperExpression
    superKeyword: super
    staticType: A
  rightParenthesis: )
  staticType: A
''');
  }

  test_unParenthesized_views() async {
    var result = await resolveTestCode(r'''
void f(int? x) {
  ((x!));
}
''');

    var node = result.findNode.parenthesized('((x!))');
    expect(node.unParenthesized, isA<PostfixExpression>());
    expect(node.unParenthesized2, isA<NullAssertionExpression>());
  }
}
