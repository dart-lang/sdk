// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordPatternResolutionTest);
  });
}

@reflectiveTest
class RecordPatternResolutionTest extends PatternsResolutionTest {
  test_empty() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (1, 2) as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: RecordPattern
    leftParenthesis: (
    fields
      RecordPatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      RecordPatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (1, 2)!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: RecordPattern
    leftParenthesis: (
    fields
      RecordPatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      RecordPatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
    rightParenthesis: )
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (1, 2)?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: RecordPattern
    leftParenthesis: (
    fields
      RecordPatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      RecordPatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
    rightParenthesis: )
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 1
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_singleton() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (0,):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
  rightParenthesis: )
''');
  }
}
