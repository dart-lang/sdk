// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParenthesizedPatternResolutionTest);
  });
}

@reflectiveTest
class ParenthesizedPatternResolutionTest extends PatternsResolutionTest {
  test_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case (0)) {}
}
''');
    final node = findNode.caseClause('case');
    assertResolvedNodeText(node, r'''
CaseClause
  caseKeyword: case
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
    rightParenthesis: )
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (0):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 0
      staticType: int
  rightParenthesis: )
''');
  }
}
