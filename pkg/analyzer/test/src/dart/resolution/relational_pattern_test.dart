// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelationalPatternResolutionTest);
  });
}

@reflectiveTest
class RelationalPatternResolutionTest extends PatternsResolutionTest {
  test_equal() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case == 1 << 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 2
''');
  }

  test_greaterThan() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case > 1 << 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 2
''');
  }

  test_greaterThanOrEqualTo() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case >= 1 << 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 2
''');
  }

  test_inside_extractorPattern() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(f: == 0):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  typeName: SimpleIdentifier
    token: C
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: f
        colon: :
      pattern: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 0
  rightParenthesis: )
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case == 0) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
''');
  }

  test_inside_listPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [== 0]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    RelationalPattern
      operator: ==
      operand: IntegerLiteral
        literal: 0
  rightBracket: ]
''');
  }

  test_inside_logicalAnd_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case == 1 & 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 1
  operator: &
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_inside_logicalAnd_right() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1 & == 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: &
  rightOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 2
''');
  }

  test_inside_logicalOr_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case == 1 | 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 1
  operator: |
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_inside_logicalOr_right() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1 | == 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: |
  rightOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 2
''');
  }

  test_inside_mapPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {'a': == 0}:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  entries
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 0
  rightBracket: }
''');
  }

  test_inside_parenthesizedPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (== 0):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 0
  rightParenthesis: )
''');
  }

  test_inside_recordPattern_named() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (a: == 1, 2):
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
      fieldName: RecordPatternFieldName
        name: a
        colon: :
      pattern: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 1
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_inside_recordPattern_unnamed() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (== 1, 2):
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
      pattern: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 1
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
''');
  }

  test_lessThan() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case < 1 << 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 2
''');
  }

  test_lessThanOrEqualTo() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case <= 1 << 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 2
''');
  }

  test_notEqual() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case != 1 << 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: !=
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 2
''');
  }
}
