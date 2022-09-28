// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PostfixPattern_NullAssert_ResolutionTest);
    defineReflectiveTests(PostfixPattern_NullCheck_ResolutionTest);
  });
}

@reflectiveTest
class PostfixPattern_NullAssert_ResolutionTest extends PatternsResolutionTest {
  test_inside_extractorPattern_namedExplicitly() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(f: 0!):
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
      pattern: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        operator: !
  rightParenthesis: )
''');
  }

  test_inside_extractorPattern_namedImplicitly() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(: var f!):
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
        colon: :
      pattern: PostfixPattern
        operand: VariablePattern
          keyword: var
          name: f
        operator: !
  rightParenthesis: )
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case var y!) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: var
    name: y
  operator: !
''');
  }

  test_inside_listPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [0!]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    PostfixPattern
      operand: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      operator: !
  rightBracket: ]
''');
  }

  test_inside_logicalAnd_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1! & 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: !
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
    case 1 & 2!:
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
  rightOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: !
''');
  }

  test_inside_logicalOr_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1! | 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: !
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
    case 1 | 2!:
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
  rightOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: !
''');
  }

  test_inside_mapPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {'a': 0!}:
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
      value: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        operator: !
  rightBracket: }
''');
  }

  test_inside_parenthesizedPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (0!):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 0
    operator: !
  rightParenthesis: )
''');
  }

  test_inside_recordPattern_namedExplicitly() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (n: 1!, 2):
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
        name: n
        colon: :
      pattern: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: !
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_inside_recordPattern_namedImplicitly() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (: var n!, 2):
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
        colon: :
      pattern: PostfixPattern
        operand: VariablePattern
          keyword: var
          name: n
        operator: !
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
    case (1!, 2):
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
      pattern: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: !
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x, y) {
  switch (x) {
    case y!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: !
''');
  }
}

@reflectiveTest
class PostfixPattern_NullCheck_ResolutionTest extends PatternsResolutionTest {
  test_inside_extractorPattern_namedExplicitly() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(f: 0?):
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
      pattern: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        operator: ?
  rightParenthesis: )
''');
  }

  test_inside_extractorPattern_namedImplicitly() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(: var f?):
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
        colon: :
      pattern: PostfixPattern
        operand: VariablePattern
          keyword: var
          name: f
        operator: ?
  rightParenthesis: )
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case var y?) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: var
    name: y
  operator: ?
''');
  }

  test_inside_listPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [0?]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    PostfixPattern
      operand: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      operator: ?
  rightBracket: ]
''');
  }

  test_inside_logicalAnd_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1? & 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: ?
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
    case 1 & 2?:
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
  rightOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: ?
''');
  }

  test_inside_logicalOr_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1? | 2:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: ?
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
    case 1 | 2?:
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
  rightOperand: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: ?
''');
  }

  test_inside_mapPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {'a': 0?}:
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
      value: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        operator: ?
  rightBracket: }
''');
  }

  test_inside_parenthesizedPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (0?):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: PostfixPattern
    operand: ConstantPattern
      expression: IntegerLiteral
        literal: 0
    operator: ?
  rightParenthesis: )
''');
  }

  test_inside_recordPattern_namedExplicitly() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (n: 1?, 2):
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
        name: n
        colon: :
      pattern: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: ?
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_inside_recordPattern_namedImplicitly() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (: var n?, 2):
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
        colon: :
      pattern: PostfixPattern
        operand: VariablePattern
          keyword: var
          name: n
        operator: ?
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
    case (1?, 2):
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
      pattern: PostfixPattern
        operand: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: ?
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x, y) {
  switch (x) {
    case y?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: ?
''');
  }
}
