// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternsTest extends ParserDiagnosticsTest {
  late FindNode findNode;

  test_assignedVariable_namedAs() {
    _parse('''
void f(x) {
  dynamic as;
  (as) = x;
}
''', errors: [
      error(ParserErrorCode.ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME, 29, 2)
    ]);
    var node = findNode.singlePatternAssignment.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: AssignedVariablePattern
    name: as
  rightParenthesis: )
''');
  }

  test_assignedVariable_namedWhen() {
    _parse('''
void f(x) {
  dynamic when;
  (when) = x;
}
''', errors: [
      error(ParserErrorCode.ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME, 31, 4)
    ]);
    var node = findNode.singlePatternAssignment.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: AssignedVariablePattern
    name: when
  rightParenthesis: )
''');
  }

  test_case_identifier_dot_incomplete() {
    // Based on the repro from
    // https://github.com/Dart-Code/Dart-Code/issues/4407.
    _parse('''
void f(x) {
  switch (x) {
    case A.
  }
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 41, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 41, 1),
    ]);
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: A
        period: .
        identifier: SimpleIdentifier
          token: <empty> <synthetic>
  colon: : <synthetic>
''');
  }

  test_caseHead_withClassicPattern_guarded_insideIfElement() {
    _parse('''
void f(x) {
  <int>[if (x case 0 when true) 1];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
''');
  }

  test_caseHead_withClassicPattern_guarded_insideIfElement_hasElse() {
    _parse('''
void f(x) {
  <int>[if (x case 0 when true) 1 else 2];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
  elseKeyword: else
  elseElement: IntegerLiteral
    literal: 2
''');
  }

  test_caseHead_withClassicPattern_guarded_insideIfStatement() {
    _parse('''
void f(x) {
  if (x case 0 when true) {}
}
''');
    var node = findNode.ifStatement('if');
    assertParsedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_caseHead_withClassicPattern_guarded_insideIfStatement_hasElse() {
    _parse('''
void f(x) {
  if (x case 0 when true) {} else {}
}
''');
    var node = findNode.ifStatement('if');
    assertParsedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
  elseKeyword: else
  elseStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_caseHead_withClassicPattern_guarded_insideSwitchStatement() {
    _parse('''
void f(x) {
  switch (x) {
    case 0 when true:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
    whenClause: WhenClause
      whenKeyword: when
      expression: BooleanLiteral
        literal: true
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_caseHead_withClassicPattern_unguarded_insideIfElement() {
    _parse('''
void f(x) {
  <int>[if (x case 0) 1];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
''');
  }

  test_caseHead_withClassicPattern_unguarded_insideIfElement_hasElse() {
    _parse('''
void f(x) {
  <int>[if (x case 0) 1 else 2];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
  elseKeyword: else
  elseElement: IntegerLiteral
    literal: 2
''');
  }

  test_caseHead_withClassicPattern_unguarded_insideIfStatement() {
    _parse('''
void f(x) {
  if (x case 0) {}
}
''');
    var node = findNode.ifStatement('if');
    assertParsedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_caseHead_withClassicPattern_unguarded_insideSwitchStatement() {
    _parse('''
void f(x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_caseHead_withNewPattern_guarded_insideIfElement() {
    _parse('''
void f(x) {
  <int>[if (x case 0 as int when true) 1];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
''');
  }

  test_caseHead_withNewPattern_guarded_insideIfElement_hasElse() {
    _parse('''
void f(x) {
  <int>[if (x case 0 as int when true) 1 else 2];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
  elseKeyword: else
  elseElement: IntegerLiteral
    literal: 2
''');
  }

  test_caseHead_withNewPattern_guarded_insideIfStatement() {
    _parse('''
void f(x) {
  if (x case 0 as int when true) {}
}
''');
    var node = findNode.ifStatement('if');
    assertParsedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_caseHead_withNewPattern_guarded_insideSwitchStatement() {
    _parse('''
void f(x) {
  switch (x) {
    case 0 as int when true:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: int
    whenClause: WhenClause
      whenKeyword: when
      expression: BooleanLiteral
        literal: true
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_caseHead_withNewPattern_unguarded_insideIfElement() {
    _parse('''
void f(x) {
  <int>[if (x case 0 as int) 1];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: int
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
''');
  }

  test_caseHead_withNewPattern_unguarded_insideIfElement_hasElse() {
    _parse('''
void f(x) {
  <int>[if (x case 0 as int) 1 else 2];
}
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: int
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 1
  elseKeyword: else
  elseElement: IntegerLiteral
    literal: 2
''');
  }

  test_caseHead_withNewPattern_unguarded_insideIfStatement() {
    _parse('''
void f(x) {
  if (x case 0 as int) {}
}
''');
    var node = findNode.ifStatement('if');
    assertParsedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: int
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_caseHead_withNewPattern_unguarded_insideSwitchStatement() {
    _parse('''
void f(x) {
  switch (x) {
    case 0 as int:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: int
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_cast_insideCase() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  asToken: as
  type: NamedType
    name: int
''');
  }

  test_cast_insideCast() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int as num:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 8),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: CastPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    asToken: as
    type: NamedType
      name: int
  asToken: as
  type: NamedType
    name: num
''');
  }

  test_cast_insideCast_parenthesized() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case (y as int) as num:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: CastPattern
      pattern: ConstantPattern
        expression: SimpleIdentifier
          token: y
      asToken: as
      type: NamedType
        name: int
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: num
''');
  }

  test_cast_insideIfCase() {
    _parse('''
void f(x) {
  if (x case var y as int) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: CastPattern
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
      asToken: as
      type: NamedType
        name: int
''');
  }

  test_cast_insideList() {
    _parse('''
void f(x) {
  switch (x) {
    case [1 as int]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 1
      asToken: as
      type: NamedType
        name: int
  rightBracket: ]
''');
  }

  test_cast_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ as double? && Object? _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: CastPattern
    pattern: WildcardPattern
      type: NamedType
        name: int
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: double
      question: ?
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: Object
      question: ?
    name: _
''');
  }

  test_cast_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ && double? _ as Object?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      question: ?
    name: _
  operator: &&
  rightOperand: CastPattern
    pattern: WildcardPattern
      type: NamedType
        name: double
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: Object
      question: ?
''');
  }

  test_cast_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ as double? || Object? _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: CastPattern
    pattern: WildcardPattern
      type: NamedType
        name: int
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: double
      question: ?
  operator: ||
  rightOperand: WildcardPattern
    type: NamedType
      name: Object
      question: ?
    name: _
''');
  }

  test_cast_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ || double? _ as Object?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      question: ?
    name: _
  operator: ||
  rightOperand: CastPattern
    pattern: WildcardPattern
      type: NamedType
        name: double
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: Object
      question: ?
''');
  }

  test_cast_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1 as int}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        asToken: as
        type: NamedType
          name: int
  rightBracket: }
''');
  }

  test_cast_insideNullAssert() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int!:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 8),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: CastPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    asToken: as
    type: NamedType
      name: int
  operator: !
''');
  }

  test_cast_insideNullCheck() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int? ?:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 9),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: CastPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    asToken: as
    type: NamedType
      name: int
      question: ?
  operator: ?
''');
  }

  test_cast_insideObject_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: 1 as int):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: f
        colon: :
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        asToken: as
        type: NamedType
          name: int
  rightParenthesis: )
''');
  }

  test_cast_insideObject_implicitlyNamed() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(: var f as int):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: CastPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: f
        asToken: as
        type: NamedType
          name: int
  rightParenthesis: )
''');
  }

  test_cast_insideParenthesized() {
    _parse('''
void f(x) {
  switch (x) {
    case (1 as int):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: CastPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    asToken: as
    type: NamedType
      name: int
  rightParenthesis: )
''');
  }

  test_cast_insideRecord_explicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (n: 1 as int, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: n
        colon: :
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        asToken: as
        type: NamedType
          name: int
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_cast_insideRecord_implicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (: var n as int, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: CastPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: n
        asToken: as
        type: NamedType
          name: int
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_cast_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (1 as int, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        asToken: as
        type: NamedType
          name: int
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_constant_identifier_doublyPrefixed_builtin() {
    _parse('''
void f(x) {
  const y = abstract.as.get; // verify that this works
  switch (x) {
    case abstract.as.get:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: abstract
      period: .
      identifier: SimpleIdentifier
        token: as
    operator: .
    propertyName: SimpleIdentifier
      token: get
''');
  }

  test_constant_identifier_doublyPrefixed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b.c:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
      period: .
      identifier: SimpleIdentifier
        token: b
    operator: .
    propertyName: SimpleIdentifier
      token: c
''');
  }

  test_constant_identifier_doublyPrefixed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b.c as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: PropertyAccess
      target: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: a
        period: .
        identifier: SimpleIdentifier
          token: b
      operator: .
      propertyName: SimpleIdentifier
        token: c
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_identifier_doublyPrefixed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case a.b.c) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: PropertyAccess
        target: PrefixedIdentifier
          prefix: SimpleIdentifier
            token: a
          period: .
          identifier: SimpleIdentifier
            token: b
        operator: .
        propertyName: SimpleIdentifier
          token: c
''');
  }

  test_constant_identifier_doublyPrefixed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b.c!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: PropertyAccess
      target: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: a
        period: .
        identifier: SimpleIdentifier
          token: b
      operator: .
      propertyName: SimpleIdentifier
        token: c
  operator: !
''');
  }

  test_constant_identifier_doublyPrefixed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b.c?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: PropertyAccess
      target: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: a
        period: .
        identifier: SimpleIdentifier
          token: b
      operator: .
      propertyName: SimpleIdentifier
        token: c
  operator: ?
''');
  }

  test_constant_identifier_doublyPrefixed_pseudoKeyword() {
    _parse('''
void f(x) {
  const y = show.hide.when; // verify that this works
  switch (x) {
    case show.hide.when:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: show
      period: .
      identifier: SimpleIdentifier
        token: hide
    operator: .
    propertyName: SimpleIdentifier
      token: when
''');
  }

  test_constant_identifier_namedAs() {
    _parse('''
void f(x) {
  switch (x) {
    case as:
  }
}
''', errors: [error(ParserErrorCode.ILLEGAL_PATTERN_IDENTIFIER_NAME, 36, 2)]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: as
''');
  }

  test_constant_identifier_namedWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case when:
  }
}
''', errors: [error(ParserErrorCode.ILLEGAL_PATTERN_IDENTIFIER_NAME, 36, 4)]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: when
''');
  }

  test_constant_identifier_prefixed_builtin() {
    _parse('''
void f(x) {
  const y = abstract.as; // verify that this works
  switch (x) {
    case abstract.as:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: abstract
    period: .
    identifier: SimpleIdentifier
      token: as
''');
  }

  test_constant_identifier_prefixed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
    period: .
    identifier: SimpleIdentifier
      token: b
''');
  }

  test_constant_identifier_prefixed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
      period: .
      identifier: SimpleIdentifier
        token: b
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_identifier_prefixed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case a.b) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: a
        period: .
        identifier: SimpleIdentifier
          token: b
''');
  }

  test_constant_identifier_prefixed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
      period: .
      identifier: SimpleIdentifier
        token: b
  operator: !
''');
  }

  test_constant_identifier_prefixed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
      period: .
      identifier: SimpleIdentifier
        token: b
  operator: ?
''');
  }

  test_constant_identifier_prefixed_pseudoKeyword() {
    _parse('''
void f(x) {
  const y = show.hide; // verify that this works
  switch (x) {
    case show.hide:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: show
    period: .
    identifier: SimpleIdentifier
      token: hide
''');
  }

  test_constant_identifier_prefixedWithUnderscore_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _.b:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: _
    period: .
    identifier: SimpleIdentifier
      token: b
''');
  }

  test_constant_identifier_unprefixed_beforeWhen() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y when true:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_constant_identifier_unprefixed_builtin() {
    _parse('''
void f(x) {
  const y = abstract; // verify that this works
  switch (x) {
    case abstract:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: abstract
''');
  }

  test_constant_identifier_unprefixed_insideCase() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: y
''');
  }

  test_constant_identifier_unprefixed_insideCast() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_identifier_unprefixed_insideIfCase() {
    _parse('''
void f(x) {
  const y = 1;
  if (x case y) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
''');
  }

  test_constant_identifier_unprefixed_insideNullAssert() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: !
''');
  }

  test_constant_identifier_unprefixed_insideNullCheck() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: ?
''');
  }

  test_constant_identifier_unprefixed_insideSwitchExpression() {
    _parse('''
f(x) => switch (x) {
  y => 0
};
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: y
''');
  }

  test_constant_identifier_unprefixed_pseudoKeyword() {
    _parse('''
void f(x) {
  const y = show; // verify that this works
  switch (x) {
    case show:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: show
''');
  }

  test_constant_list_typed_empty_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    leftBracket: [
    rightBracket: ]
''');
  }

  test_constant_list_typed_empty_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[] as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: [
      rightBracket: ]
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_list_typed_empty_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const <int>[]) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: ListLiteral
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        leftBracket: [
        rightBracket: ]
''');
  }

  test_constant_list_typed_empty_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[]!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: [
      rightBracket: ]
  operator: !
''');
  }

  test_constant_list_typed_empty_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[]?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: [
      rightBracket: ]
  operator: ?
''');
  }

  test_constant_list_typed_nonEmpty_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[1]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    leftBracket: [
    elements
      IntegerLiteral
        literal: 1
    rightBracket: ]
''');
  }

  test_constant_list_typed_nonEmpty_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[1] as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_list_typed_nonEmpty_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const <int>[1]) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: ListLiteral
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        leftBracket: [
        elements
          IntegerLiteral
            literal: 1
        rightBracket: ]
''');
  }

  test_constant_list_typed_nonEmpty_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[1]!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
  operator: !
''');
  }

  test_constant_list_typed_nonEmpty_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>[1]?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
  operator: ?
''');
  }

  test_constant_list_untyped_empty_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const []:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    leftBracket: [
    rightBracket: ]
''');
  }

  test_constant_list_untyped_empty_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const [] as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      rightBracket: ]
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_list_untyped_empty_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const []) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: ListLiteral
        leftBracket: [
        rightBracket: ]
''');
  }

  test_constant_list_untyped_empty_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const []!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      rightBracket: ]
  operator: !
''');
  }

  test_constant_list_untyped_empty_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const []?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      rightBracket: ]
  operator: ?
''');
  }

  test_constant_list_untyped_nonEmpty_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const [1]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    leftBracket: [
    elements
      IntegerLiteral
        literal: 1
    rightBracket: ]
''');
  }

  test_constant_list_untyped_nonEmpty_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const [1] as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_list_untyped_nonEmpty_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const [1]) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 1
        rightBracket: ]
''');
  }

  test_constant_list_untyped_nonEmpty_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const [1]!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
  operator: !
''');
  }

  test_constant_list_untyped_nonEmpty_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const [1]?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
  operator: ?
''');
  }

  test_constant_map_typed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
        NamedType
          name: int
      rightBracket: >
    leftBracket: {
    elements
      MapLiteralEntry
        key: IntegerLiteral
          literal: 1
        separator: :
        value: IntegerLiteral
          literal: 2
    rightBracket: }
    isMap: false
''');
  }

  test_constant_map_typed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2} as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
          NamedType
            name: int
        rightBracket: >
      leftBracket: {
      elements
        MapLiteralEntry
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_map_typed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const <int, int>{1: 2}) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: SetOrMapLiteral
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
            NamedType
              name: int
          rightBracket: >
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 1
            separator: :
            value: IntegerLiteral
              literal: 2
        rightBracket: }
        isMap: false
''');
  }

  test_constant_map_typed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2}!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
          NamedType
            name: int
        rightBracket: >
      leftBracket: {
      elements
        MapLiteralEntry
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  operator: !
''');
  }

  test_constant_map_typed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2}?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
          NamedType
            name: int
        rightBracket: >
      leftBracket: {
      elements
        MapLiteralEntry
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  operator: ?
''');
  }

  test_constant_map_untyped_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1: 2}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    leftBracket: {
    elements
      MapLiteralEntry
        key: IntegerLiteral
          literal: 1
        separator: :
        value: IntegerLiteral
          literal: 2
    rightBracket: }
    isMap: false
''');
  }

  test_constant_map_untyped_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1: 2} as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        MapLiteralEntry
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_map_untyped_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const {1: 2}) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 1
            separator: :
            value: IntegerLiteral
              literal: 2
        rightBracket: }
        isMap: false
''');
  }

  test_constant_map_untyped_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1: 2}!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        MapLiteralEntry
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  operator: !
''');
  }

  test_constant_map_untyped_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1: 2}?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        MapLiteralEntry
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  operator: ?
''');
  }

  test_constant_objectExpression_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const Foo(1):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: Foo
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 1
      rightParenthesis: )
''');
  }

  test_constant_objectExpression_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const Foo(1) as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: Foo
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 1
        rightParenthesis: )
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_objectExpression_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const Foo(1)) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: Foo
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 1
          rightParenthesis: )
''');
  }

  test_constant_objectExpression_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const Foo(1)!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: Foo
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 1
        rightParenthesis: )
  operator: !
''');
  }

  test_constant_objectExpression_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const Foo(1)?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: Foo
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 1
        rightParenthesis: )
  operator: ?
''');
  }

  test_constant_parenthesized_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const (1):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 1
    rightParenthesis: )
''');
  }

  test_constant_parenthesized_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const (1) as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: IntegerLiteral
        literal: 1
      rightParenthesis: )
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_parenthesized_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const (1)) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: ParenthesizedExpression
        leftParenthesis: (
        expression: IntegerLiteral
          literal: 1
        rightParenthesis: )
''');
  }

  test_constant_parenthesized_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const (1)!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: IntegerLiteral
        literal: 1
      rightParenthesis: )
  operator: !
''');
  }

  test_constant_parenthesized_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const (1)?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: IntegerLiteral
        literal: 1
      rightParenthesis: )
  operator: ?
''');
  }

  test_constant_set_typed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>{1}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    leftBracket: {
    elements
      IntegerLiteral
        literal: 1
    rightBracket: }
    isMap: false
''');
  }

  test_constant_set_typed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>{1} as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: {
      elements
        IntegerLiteral
          literal: 1
      rightBracket: }
      isMap: false
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_set_typed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const <int>{1}) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: SetOrMapLiteral
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
        leftBracket: {
        elements
          IntegerLiteral
            literal: 1
        rightBracket: }
        isMap: false
''');
  }

  test_constant_set_typed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>{1}!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: {
      elements
        IntegerLiteral
          literal: 1
      rightBracket: }
      isMap: false
  operator: !
''');
  }

  test_constant_set_typed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const <int>{1}?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: {
      elements
        IntegerLiteral
          literal: 1
      rightBracket: }
      isMap: false
  operator: ?
''');
  }

  test_constant_set_untyped_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    leftBracket: {
    elements
      IntegerLiteral
        literal: 1
    rightBracket: }
    isMap: false
''');
  }

  test_constant_set_untyped_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1} as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        IntegerLiteral
          literal: 1
      rightBracket: }
      isMap: false
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_set_untyped_insideIfCase() {
    _parse('''
void f(x) {
  if (x case const {1}) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          IntegerLiteral
            literal: 1
        rightBracket: }
        isMap: false
''');
  }

  test_constant_set_untyped_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1}!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        IntegerLiteral
          literal: 1
      rightBracket: }
      isMap: false
  operator: !
''');
  }

  test_constant_set_untyped_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case const {1}?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        IntegerLiteral
          literal: 1
      rightBracket: }
      isMap: false
  operator: ?
''');
  }

  test_declaredVariable_inPatternAssignment_usingFinal() {
    _parse('''
void f() {
  [a, final d] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 23, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      DeclaredVariablePattern
        keyword: final
        name: d
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_declaredVariable_inPatternAssignment_usingFinalAndType() {
    _parse('''
void f() {
  [a, final int d] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 27, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      DeclaredVariablePattern
        keyword: final
        type: NamedType
          name: int
        name: d
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_declaredVariable_inPatternAssignment_usingType() {
    _parse('''
void f() {
  [a, int d] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 21, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      DeclaredVariablePattern
        type: NamedType
          name: int
        name: d
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_declaredVariable_inPatternAssignment_usingVar() {
    _parse('''
void f() {
  [a, var d] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 21, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      DeclaredVariablePattern
        keyword: var
        name: d
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_declaredVariable_inPatternAssignment_usingVarAndType() {
    _parse('''
void f() {
  [a, var int d] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 25, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      DeclaredVariablePattern
        keyword: var
        type: NamedType
          name: int
        name: d
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_errorRecovery_afterQuestionSuffixInExpression() {
    // Based on co19 test `Language/Expressions/Conditional/syntax_t06.dart`.
    // Even though we now support suffix `?` in patterns, we need to make sure
    // that a suffix `?` in an expression still causes the appropriate syntax
    // error.
    _parse('''
f() {
  try {
    true ?  : 2;
  } catch (e) {}
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);
  }

  test_functionExpression_allowed_afterSwitchExpression() {
    _parse('''
f(x) => switch(x) {} + () => 0;
''');
    var node = findNode.functionDeclaration('f');
    assertParsedNodeText(node, r'''
FunctionDeclaration
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        name: x
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: BinaryExpression
        leftOperand: SwitchExpression
          switchKeyword: switch
          leftParenthesis: (
          expression: SimpleIdentifier
            token: x
          rightParenthesis: )
          leftBracket: {
          rightBracket: }
        operator: +
        rightOperand: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  test_functionExpression_allowed_insideIfCaseWhenClause_element() {
    _parse('''
f(x, y) => [if (x case _ when y + () => 0) 0];
''');
    var node = findNode.ifElement('if');
    assertParsedNodeText(node, r'''
IfElement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: WildcardPattern
        name: _
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: y
          operator: +
          rightOperand: FunctionExpression
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
  rightParenthesis: )
  thenElement: IntegerLiteral
    literal: 0
''');
  }

  test_functionExpression_allowed_insideIfCaseWhenClause_statement() {
    _parse('''
f(x, y) {
  if (x case _ when y + () => 0) {}
}
''');
    var node = findNode.ifStatement('if');
    assertParsedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: WildcardPattern
        name: _
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: y
          operator: +
          rightOperand: FunctionExpression
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_functionExpression_allowed_insideListPattern() {
    _parse('''
f(x) => switch(x) { [== () => 0] => 0 };
''');
    var node = findNode.switchExpressionCase('() => 0').guardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    RelationalPattern
      operator: ==
      operand: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
  rightBracket: ]
''');
  }

  test_functionExpression_allowed_insideMapPattern() {
    _parse('''
f(x) => switch(x) { {'x': == () => 0} => 0 };
''');
    var node = findNode.switchExpressionCase('() => 0').guardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'x'
      separator: :
      value: RelationalPattern
        operator: ==
        operand: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: IntegerLiteral
              literal: 0
  rightBracket: }
''');
  }

  test_functionExpression_allowed_insideObjectPattern() {
    _parse('''
f(x) => switch(x) { Foo(bar: == () => 0) => 0 };
''');
    var node = findNode.switchExpressionCase('() => 0').guardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: Foo
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: bar
        colon: :
      pattern: RelationalPattern
        operator: ==
        operand: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: IntegerLiteral
              literal: 0
  rightParenthesis: )
''');
  }

  test_functionExpression_allowed_insideParenthesizedConstPattern() {
    _parse('''
f(x) => switch(x) { const (() => 0) => 0 };
''');
    var node = findNode.switchExpressionCase('() => 0').guardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ParenthesizedExpression
    leftParenthesis: (
    expression: FunctionExpression
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression: IntegerLiteral
          literal: 0
    rightParenthesis: )
''');
  }

  test_functionExpression_allowed_insideParenthesizedPattern() {
    _parse('''
f(x) => switch(x) { (== () => 0) => 0 };
''');
    var node = findNode.switchExpressionCase('() => 0').guardedPattern.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: RelationalPattern
    operator: ==
    operand: FunctionExpression
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression: IntegerLiteral
          literal: 0
  rightParenthesis: )
''');
  }

  test_functionExpression_allowed_insideSwitchExpressionCase_guarded() {
    _parse('''
f(x) => switch(x) { _ when switch(x) { _ when true => () => 0 } => 0 };
''');
    var node = findNode.switchExpressionCase('() => 0');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
    whenClause: WhenClause
      whenKeyword: when
      expression: BooleanLiteral
        literal: true
  arrow: =>
  expression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
''');
  }

  test_functionExpression_allowed_insideSwitchExpressionCase_unguarded() {
    _parse('''
f(x) => switch(x) { _ when switch(x) { _ => () => 0 } => 0 };
''');
    var node = findNode.switchExpressionCase('() => 0');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
  arrow: =>
  expression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
''');
  }

  test_functionExpression_allowed_insideSwitchExpressionScrutinee() {
    _parse('''
f() => switch(() => 0) {};
''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
  rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
  }

  test_functionExpression_allowed_insideSwitchStatementInWhenClause() {
    _parse('''
f(x, y) {
  switch(x) {
    case _ when y + () => 0:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('when');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
    whenClause: WhenClause
      whenKeyword: when
      expression: BinaryExpression
        leftOperand: SimpleIdentifier
          token: y
        operator: +
        rightOperand: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: IntegerLiteral
              literal: 0
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_functionExpression_disallowed_afterListPattern() {
    _parse('''
f(x) => switch(x) { [_] when () => 0 };
''');
    var node = findNode.switchExpressionCase('when');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: ListPattern
      leftBracket: [
      elements
        WildcardPattern
          name: _
      rightBracket: ]
    whenClause: WhenClause
      whenKeyword: when
      expression: RecordLiteral
        leftParenthesis: (
        rightParenthesis: )
  arrow: =>
  expression: IntegerLiteral
    literal: 0
''');
  }

  test_functionExpression_disallowed_afterMapPattern() {
    _parse('''
f(x) => switch(x) { {'x': _} when () => 0 };
''');
    var node = findNode.switchExpressionCase('when');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: MapPattern
      leftBracket: {
      elements
        MapPatternEntry
          key: SimpleStringLiteral
            literal: 'x'
          separator: :
          value: WildcardPattern
            name: _
      rightBracket: }
    whenClause: WhenClause
      whenKeyword: when
      expression: RecordLiteral
        leftParenthesis: (
        rightParenthesis: )
  arrow: =>
  expression: IntegerLiteral
    literal: 0
''');
  }

  test_functionExpression_disallowed_afterObjectPattern() {
    _parse('''
f(x) => switch(x) { Foo(bar: _) when () => 0 };
''');
    var node = findNode.switchExpressionCase('when');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: ObjectPattern
      type: NamedType
        name: Foo
      leftParenthesis: (
      fields
        PatternField
          name: PatternFieldName
            name: bar
            colon: :
          pattern: WildcardPattern
            name: _
      rightParenthesis: )
    whenClause: WhenClause
      whenKeyword: when
      expression: RecordLiteral
        leftParenthesis: (
        rightParenthesis: )
  arrow: =>
  expression: IntegerLiteral
    literal: 0
''');
  }

  test_functionExpression_disallowed_afterParenthesizedPattern() {
    _parse('''
f(x) => switch(x) { (_) when () => 0 };
''');
    var node = findNode.switchExpressionCase('when');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: WildcardPattern
        name: _
      rightParenthesis: )
    whenClause: WhenClause
      whenKeyword: when
      expression: RecordLiteral
        leftParenthesis: (
        rightParenthesis: )
  arrow: =>
  expression: IntegerLiteral
    literal: 0
''');
  }

  test_functionExpression_disallowed_afterSwitchExpressionInWhenClause() {
    _parse('''
f(x) => switch(x) { _ when switch(x) {} + () => 0 };
''');
    var node = findNode.switchExpressionCase('when');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
    whenClause: WhenClause
      whenKeyword: when
      expression: BinaryExpression
        leftOperand: SwitchExpression
          switchKeyword: switch
          leftParenthesis: (
          expression: SimpleIdentifier
            token: x
          rightParenthesis: )
          leftBracket: {
          rightBracket: }
        operator: +
        rightOperand: RecordLiteral
          leftParenthesis: (
          rightParenthesis: )
  arrow: =>
  expression: IntegerLiteral
    literal: 0
''');
  }

  test_functionExpression_disallowed_insideSwitchExpressionInWhenClause() {
    _parse('''
f(x, y) => switch(x) { _ when y + () => 0 };
''');
    var node = findNode.switchExpressionCase('when');
    assertParsedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
    whenClause: WhenClause
      whenKeyword: when
      expression: BinaryExpression
        leftOperand: SimpleIdentifier
          token: y
        operator: +
        rightOperand: RecordLiteral
          leftParenthesis: (
          rightParenthesis: )
  arrow: =>
  expression: IntegerLiteral
    literal: 0
''');
  }

  test_identifier_as_when() {
    // Based on the discussion at https://github.com/dart-lang/sdk/issues/52199.
    _parse('''
void f(x) {
  switch (x) {
    case foo as when:
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: CastPattern
      pattern: ConstantPattern
        expression: SimpleIdentifier
          token: foo
      asToken: as
      type: NamedType
        name: when
  colon: :
''');
  }

  test_identifier_when_as() {
    // Based on the discussion at https://github.com/dart-lang/sdk/issues/52199.
    _parse('''
void f(x) {
  switch (x) {
    case foo when as:
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: foo
    whenClause: WhenClause
      whenKeyword: when
      expression: SimpleIdentifier
        token: as
  colon: :
''');
  }

  test_identifier_when_not() {
    // Based on the repro from https://github.com/dart-lang/sdk/issues/52199.
    _parse('''
void f(x) {
  switch (x) {
    case foo when !flag:
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: foo
    whenClause: WhenClause
      whenKeyword: when
      expression: PrefixExpression
        operator: !
        operand: SimpleIdentifier
          token: flag
  colon: :
''');
  }

  test_identifier_when_when() {
    // Based on the discussion at https://github.com/dart-lang/sdk/issues/52199.
    _parse('''
void f(x) {
  switch (x) {
    case foo when when:
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: foo
    whenClause: WhenClause
      whenKeyword: when
      expression: SimpleIdentifier
        token: when
  colon: :
''');
  }

  test_issue50591_example1() {
    _parse('''
f(x, bool Function() a) => switch(x) {
  _ when a() => 0
};
''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
        whenClause: WhenClause
          whenKeyword: when
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: a
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
      arrow: =>
      expression: IntegerLiteral
        literal: 0
  rightBracket: }
''');
  }

  test_issue50591_example2() {
    _parse('''
void f(Object? x) {
  (switch (x) {
    const A() => 0,
    _ => 1,
  });
}''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          const: const
          expression: MethodInvocation
            methodName: SimpleIdentifier
              token: A
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
      arrow: =>
      expression: IntegerLiteral
        literal: 0
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 1
  rightBracket: }
''');
  }

  test_list_insideAssignment_typed_nonEmpty() {
    _parse('''
void f(x) {
  <int>[a, b] = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: [
  elements
    AssignedVariablePattern
      name: a
    AssignedVariablePattern
      name: b
  rightBracket: ]
''');
  }

  test_list_insideAssignment_untyped_empty() {
    _parse('''
void f(x) {
  [] = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideAssignment_untyped_emptyWithWhitespace() {
    _parse('''
void f(x) {
  [ ] = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideAssignment_untyped_nonEmpty() {
    _parse('''
void f(x) {
  [a, b] = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    AssignedVariablePattern
      name: a
    AssignedVariablePattern
      name: b
  rightBracket: ]
''');
  }

  test_list_insideCase_typed_nonEmpty() {
    _parse('''
void f(x) {
  switch (x) {
    case <int>[1, 2]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 1
    ConstantPattern
      expression: IntegerLiteral
        literal: 2
  rightBracket: ]
''');
  }

  test_list_insideCase_untyped_empty() {
    _parse('''
void f(x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideCase_untyped_emptyWithWhitespace() {
    _parse('''
void f(x) {
  switch (x) {
    case [ ]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideCase_untyped_nonEmpty() {
    _parse('''
void f(x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 1
    ConstantPattern
      expression: IntegerLiteral
        literal: 2
  rightBracket: ]
''');
  }

  test_list_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case [1] as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ListPattern
    leftBracket: [
    elements
      ConstantPattern
        expression: IntegerLiteral
          literal: 1
    rightBracket: ]
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_list_insideDeclaration_typed_nonEmpty() {
    _parse('''
void f(x) {
  var <int>[a, b] = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: [
  elements
    DeclaredVariablePattern
      name: a
    DeclaredVariablePattern
      name: b
  rightBracket: ]
''');
  }

  test_list_insideDeclaration_untyped_empty() {
    _parse('''
void f(x) {
  var [] = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideDeclaration_untyped_emptyWithWhitespace() {
    _parse('''
void f(x) {
  var [ ] = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideDeclaration_untyped_nonEmpty() {
    _parse('''
void f(x) {
  var [a, b] = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      name: a
    DeclaredVariablePattern
      name: b
  rightBracket: ]
''');
  }

  test_list_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case [1]!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ListPattern
    leftBracket: [
    elements
      ConstantPattern
        expression: IntegerLiteral
          literal: 1
    rightBracket: ]
  operator: !
''');
  }

  test_list_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case [1]?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ListPattern
    leftBracket: [
    elements
      ConstantPattern
        expression: IntegerLiteral
          literal: 1
    rightBracket: ]
  operator: ?
''');
  }

  test_list_recovery_bogusTokensAfterListElement() {
    // If the extra tokens after a list element don't look like they could be a
    // pattern, the parser skips to the end of the list to avoid a large number
    // of parse errors.
    _parse('''
void f(x) {
  switch (x) {
    case [int() * 2]:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 43, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ObjectPattern
      type: NamedType
        name: int
      leftParenthesis: (
      rightParenthesis: )
  rightBracket: ]
''');
  }

  test_list_recovery_missingClosingBracket() {
    // If the extra tokens after a list element don't look like they could be a
    // pattern, and the pattern doesn't have a matching `]`, the parser assumes
    // it's the `]` that is missing.
    _parse('''
void f(x) {
  switch (x) {
    case [int():
      break;
  }
}
''', errors: [
      error(ScannerErrorCode.EXPECTED_TOKEN, 59, 1),
    ]);
    var node = findNode.switchStatement('switch').members.single;
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ListPattern
      leftBracket: [
      elements
        ObjectPattern
          type: NamedType
            name: int
          leftParenthesis: (
          rightParenthesis: )
      rightBracket: ] <synthetic>
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_list_recovery_missingComma() {
    // If the extra tokens after a list element look like they could be a
    // pattern, the parser assumes there's a missing comma.
    _parse('''
void f(x) {
  switch (x) {
    case [int() int()]:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 43, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ObjectPattern
      type: NamedType
        name: int
      leftParenthesis: (
      rightParenthesis: )
    ObjectPattern
      type: NamedType
        name: int
      leftParenthesis: (
      rightParenthesis: )
  rightBracket: ]
''');
  }

  test_literal_boolean_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case true:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: BooleanLiteral
    literal: true
''');
  }

  test_literal_boolean_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case true as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_literal_boolean_insideIfCase() {
    _parse('''
void f(x) {
  if (x case true) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: BooleanLiteral
        literal: true
''');
  }

  test_literal_boolean_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
  operator: !
''');
  }

  test_literal_boolean_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case true?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
  operator: ?
''');
  }

  test_literal_double_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case 1.0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: DoubleLiteral
    literal: 1.0
''');
  }

  test_literal_double_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case 1.0 as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_literal_double_insideIfCase() {
    _parse('''
void f(x) {
  if (x case 1.0) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: DoubleLiteral
        literal: 1.0
''');
  }

  test_literal_double_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case 1.0!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
  operator: !
''');
  }

  test_literal_double_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case 1.0?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
  operator: ?
''');
  }

  test_literal_integer_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case 1:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 1
''');
  }

  test_literal_integer_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_literal_integer_insideIfCase() {
    _parse('''
void f(x) {
  if (x case 1) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
''');
  }

  test_literal_integer_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case 1!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: !
''');
  }

  test_literal_integer_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case 1?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: ?
''');
  }

  test_literal_null_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case null:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: NullLiteral
    literal: null
''');
  }

  test_literal_null_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case null as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: NullLiteral
      literal: null
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_literal_null_insideIfCase() {
    _parse('''
void f(x) {
  if (x case null) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: NullLiteral
        literal: null
''');
  }

  test_literal_null_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case null!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: NullLiteral
      literal: null
  operator: !
''');
  }

  test_literal_null_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case null?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: NullLiteral
      literal: null
  operator: ?
''');
  }

  test_literal_string_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case "x":
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleStringLiteral
    literal: "x"
''');
  }

  test_literal_string_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case "x" as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleStringLiteral
      literal: "x"
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_literal_string_insideIfCase() {
    _parse('''
void f(x) {
  if (x case "x") {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: SimpleStringLiteral
        literal: "x"
''');
  }

  test_literal_string_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case "x"!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: SimpleStringLiteral
      literal: "x"
  operator: !
''');
  }

  test_literal_string_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case "x"?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: SimpleStringLiteral
      literal: "x"
  operator: ?
''');
  }

  test_logicalAnd_insideIfCase() {
    _parse('''
void f(x) {
  if (x case int? _ && double? _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: LogicalAndPattern
      leftOperand: WildcardPattern
        type: NamedType
          name: int
          question: ?
        name: _
      operator: &&
      rightOperand: WildcardPattern
        type: NamedType
          name: double
          question: ?
        name: _
''');
  }

  test_logicalAnd_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ && double? _ && Object? _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: LogicalAndPattern
    leftOperand: WildcardPattern
      type: NamedType
        name: int
        question: ?
      name: _
    operator: &&
    rightOperand: WildcardPattern
      type: NamedType
        name: double
        question: ?
      name: _
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: Object
      question: ?
    name: _
''');
  }

  test_logicalAnd_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ && double? _ || Object? _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalAndPattern
    leftOperand: WildcardPattern
      type: NamedType
        name: int
        question: ?
      name: _
    operator: &&
    rightOperand: WildcardPattern
      type: NamedType
        name: double
        question: ?
      name: _
  operator: ||
  rightOperand: WildcardPattern
    type: NamedType
      name: Object
      question: ?
    name: _
''');
  }

  test_logicalAnd_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ || double? _ && Object? _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      question: ?
    name: _
  operator: ||
  rightOperand: LogicalAndPattern
    leftOperand: WildcardPattern
      type: NamedType
        name: double
        question: ?
      name: _
    operator: &&
    rightOperand: WildcardPattern
      type: NamedType
        name: Object
        question: ?
      name: _
''');
  }

  test_logicalOr_insideIfCase() {
    _parse('''
void f(x) {
  if (x case int? _ || double? _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: LogicalOrPattern
      leftOperand: WildcardPattern
        type: NamedType
          name: int
          question: ?
        name: _
      operator: ||
      rightOperand: WildcardPattern
        type: NamedType
          name: double
          question: ?
        name: _
''');
  }

  test_logicalOr_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ || double? _ || Object? _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: WildcardPattern
      type: NamedType
        name: int
        question: ?
      name: _
    operator: ||
    rightOperand: WildcardPattern
      type: NamedType
        name: double
        question: ?
      name: _
  operator: ||
  rightOperand: WildcardPattern
    type: NamedType
      name: Object
      question: ?
    name: _
''');
  }

  test_map_insideAssignment_typed_nonEmpty() {
    _parse('''
void f(x) {
  <String, int>{'a': a, 'b': b} = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: AssignedVariablePattern
        name: a
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'b'
      separator: :
      value: AssignedVariablePattern
        name: b
  rightBracket: }
''');
  }

  test_map_insideAssignment_untyped_empty() {
    // Note: statements aren't allowed to start with `{` so we need parens
    // around the assignment.  See
    // https://github.com/dart-lang/language/issues/2662.
    _parse('''
void f(x) {
  ({} = x);
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_map_insideAssignment_untyped_empty_beginningOfStatement() {
    _parse('''
void f(x) {
  {} = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_map_insideAssignment_untyped_nonEmpty() {
    // Note: statements aren't allowed to start with `{` so we need parens
    // around the assignment.  See
    // https://github.com/dart-lang/language/issues/2662.
    _parse('''
void f(x) {
  ({'a': a, 'b': b} = x);
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: AssignedVariablePattern
        name: a
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'b'
      separator: :
      value: AssignedVariablePattern
        name: b
  rightBracket: }
''');
  }

  test_map_insideAssignment_untyped_nonEmpty_beginningOfStatement() {
    _parse('''
void f(x) {
  {'a': a, 'b': b} = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: AssignedVariablePattern
        name: a
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'b'
      separator: :
      value: AssignedVariablePattern
        name: b
  rightBracket: }
''');
  }

  test_map_insideCase_typed_nonEmpty() {
    _parse('''
void f(x) {
  switch (x) {
    case <String, int>{'a': 1, 'b': 2}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 1
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'b'
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightBracket: }
''');
  }

  test_map_insideCase_untyped_empty() {
    _parse('''
void f(x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_map_insideCase_untyped_nonEmpty() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1, 'b': 2}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 1
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'b'
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightBracket: }
''');
  }

  test_map_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1} as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: SimpleStringLiteral
          literal: 'a'
        separator: :
        value: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightBracket: }
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_map_insideDeclaration_typed_nonEmpty() {
    _parse('''
void f(x) {
  var <String, int>{'a': a, 'b': b} = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: DeclaredVariablePattern
        name: a
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'b'
      separator: :
      value: DeclaredVariablePattern
        name: b
  rightBracket: }
''');
  }

  test_map_insideDeclaration_untyped_empty() {
    _parse('''
void f(x) {
  var {} = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_map_insideDeclaration_untyped_nonEmpty() {
    _parse('''
void f(x) {
  var {'a': a, 'b': b} = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: DeclaredVariablePattern
        name: a
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'b'
      separator: :
      value: DeclaredVariablePattern
        name: b
  rightBracket: }
''');
  }

  test_map_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1}!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: SimpleStringLiteral
          literal: 'a'
        separator: :
        value: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightBracket: }
  operator: !
''');
  }

  test_map_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1}?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: SimpleStringLiteral
          literal: 'a'
        separator: :
        value: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightBracket: }
  operator: ?
''');
  }

  test_map_recovery_bogusTokensAfterMapElement() {
    // If the extra tokens after a map element don't look like they could be a
    // key expression, the parser skips to the end of the map to avoid a large
    // number of parse errors.
    _parse('''
void f(x) {
  switch (x) {
    case {'foo': int() * 2}:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 50, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'foo'
      separator: :
      value: ObjectPattern
        type: NamedType
          name: int
        leftParenthesis: (
        rightParenthesis: )
  rightBracket: }
''');
  }

  void test_map_recovery_incompleteEntry() {
    _parse('''
const c = 0;

void f(Object o) {
  switch (o) {
    case {c}:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 59, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 59, 1),
    ]);
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: MapPattern
      leftBracket: {
      elements
        MapPatternEntry
          key: SimpleIdentifier
            token: c
          separator: : <synthetic>
          value: ConstantPattern
            expression: SimpleIdentifier
              token: <empty> <synthetic>
      rightBracket: }
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_map_recovery_missingClosingBrace() {
    // If the extra tokens after a map element don't look like they could be a
    // key expression, and the pattern doesn't have a matching `}`, the parser
    // assumes it's the `}` that is missing.
    _parse('''
void f(x) {
  switch (x) {
    case ({'foo': int()):
      break;
  }
}
''', errors: [
      error(ScannerErrorCode.EXPECTED_TOKEN, 50, 1),
    ]);
    var node = findNode.switchStatement('switch').members.single;
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: MapPattern
        leftBracket: {
        elements
          MapPatternEntry
            key: SimpleStringLiteral
              literal: 'foo'
            separator: :
            value: ObjectPattern
              type: NamedType
                name: int
              leftParenthesis: (
              rightParenthesis: )
        rightBracket: } <synthetic>
      rightParenthesis: )
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_map_recovery_missingComma() {
    // If the extra tokens after a map element look like they could be a key
    // expression, the parser assumes there's a missing comma.
    _parse('''
void f(x) {
  switch (x) {
    case {'foo': int() 'bar': int()}:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 50, 5),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'foo'
      separator: :
      value: ObjectPattern
        type: NamedType
          name: int
        leftParenthesis: (
        rightParenthesis: )
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'bar'
      separator: :
      value: ObjectPattern
        type: NamedType
          name: int
        leftParenthesis: (
        rightParenthesis: )
  rightBracket: }
''');
  }

  test_nullAssert_insideCase() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: !
''');
  }

  test_nullAssert_insideCast() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y! as num:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: NullAssertPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    operator: !
  asToken: as
  type: NamedType
    name: num
''');
  }

  test_nullAssert_insideIfCase() {
    _parse('''
void f(x) {
  if (x case var y!) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: NullAssertPattern
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
      operator: !
''');
  }

  test_nullAssert_insideList() {
    _parse('''
void f(x) {
  switch (x) {
    case [1!]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    NullAssertPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 1
      operator: !
  rightBracket: ]
''');
  }

  test_nullAssert_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1! && 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: NullAssertPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: !
  operator: &&
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_nullAssert_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 && 2!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: &&
  rightOperand: NullAssertPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: !
''');
  }

  test_nullAssert_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1! || 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: NullAssertPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: !
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_nullAssert_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 || 2!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: ||
  rightOperand: NullAssertPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: !
''');
  }

  test_nullAssert_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1!}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: NullAssertPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: !
  rightBracket: }
''');
  }

  test_nullAssert_insideNullAssert() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!!:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: NullAssertPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    operator: !
  operator: !
''');
  }

  test_nullAssert_insideNullCheck() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!?:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: NullAssertPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    operator: !
  operator: ?
''');
  }

  test_nullAssert_insideObject_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: 1!):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: f
        colon: :
      pattern: NullAssertPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: !
  rightParenthesis: )
''');
  }

  test_nullAssert_insideObject_implicitlyNamed() {
    _parse('''
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
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullAssertPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: f
        operator: !
  rightParenthesis: )
''');
  }

  test_nullAssert_insideParenthesized() {
    _parse('''
void f(x) {
  switch (x) {
    case (1!):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: NullAssertPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: !
  rightParenthesis: )
''');
  }

  test_nullAssert_insideRecord_explicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (n: 1!, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: n
        colon: :
      pattern: NullAssertPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: !
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_nullAssert_insideRecord_implicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (: var n!, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullAssertPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: n
        operator: !
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_nullAssert_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (1!, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: NullAssertPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: !
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_nullCheck_insideCase() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: ?
''');
  }

  test_nullCheck_insideCast() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y? as num:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: NullCheckPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    operator: ?
  asToken: as
  type: NamedType
    name: num
''');
  }

  test_nullCheck_insideIfCase() {
    _parse('''
void f(x) {
  if (x case var y?) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: NullCheckPattern
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
      operator: ?
''');
  }

  test_nullCheck_insideList() {
    _parse('''
void f(x) {
  switch (x) {
    case [1?]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    NullCheckPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 1
      operator: ?
  rightBracket: ]
''');
  }

  test_nullCheck_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1? && 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: NullCheckPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: ?
  operator: &&
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_nullCheck_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 && 2?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: &&
  rightOperand: NullCheckPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: ?
''');
  }

  test_nullCheck_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1? || 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: NullCheckPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: ?
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_nullCheck_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 || 2?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: ||
  rightOperand: NullCheckPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 2
    operator: ?
''');
  }

  test_nullCheck_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1?}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: NullCheckPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: ?
  rightBracket: }
''');
  }

  test_nullCheck_insideNullAssert() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y?!:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: NullCheckPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    operator: ?
  operator: !
''');
  }

  test_nullCheck_insideNullCheck() {
    _parse('''
void f(x) {
  const y = 1;
  switch (x) {
    case y? ?:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 51, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: NullCheckPattern
    pattern: ConstantPattern
      expression: SimpleIdentifier
        token: y
    operator: ?
  operator: ?
''');
  }

  test_nullCheck_insideObject_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: 1?):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: f
        colon: :
      pattern: NullCheckPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: ?
  rightParenthesis: )
''');
  }

  test_nullCheck_insideObject_implicitlyNamed() {
    _parse('''
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
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullCheckPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: f
        operator: ?
  rightParenthesis: )
''');
  }

  test_nullCheck_insideParenthesized() {
    _parse('''
void f(x) {
  switch (x) {
    case (1?):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: NullCheckPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    operator: ?
  rightParenthesis: )
''');
  }

  test_nullCheck_insideRecord_explicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (n: 1?, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: n
        colon: :
      pattern: NullCheckPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: ?
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_nullCheck_insideRecord_implicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (: var n?, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullCheckPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: n
        operator: ?
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_nullCheck_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (1?, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: NullCheckPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        operator: ?
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_object_dynamic() {
    _parse('''
void f(x) {
  switch (x) {
    case dynamic():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: dynamic
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_async() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var async() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: async
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_await() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var await() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: await
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_hide() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var hide() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: hide
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_of() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var of() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: of
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_on() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var on() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: on
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_show() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var show() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: show
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_sync() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var sync() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: sync
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_otherIdentifier_yield() {
    // The type name in an object pattern is a `typeIdentifier`; in the spec
    // grammar, `typeIdentifier` includes `OTHER_IDENTIFIER`, so this is
    // allowed.
    _parse('''
void f(x) {
  var yield() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: yield
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_prefixed_withTypeArgs_insideAssignment() {
    _parse('''
void f(x) {
  async.Future<int>() = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    importPrefix: ImportPrefixReference
      name: async
      period: .
    name: Future
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_prefixed_withTypeArgs_insideCase() {
    _parse('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    importPrefix: ImportPrefixReference
      name: async
      period: .
    name: Future
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_prefixed_withTypeArgs_insideCast() {
    _parse('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>() as Object:
      break;
  }
}
''');
    var node = findNode.switchPatternCase("async.Future<int>() as Object");
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: CastPattern
      pattern: ObjectPattern
        type: NamedType
          importPrefix: ImportPrefixReference
            name: async
            period: .
          name: Future
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
            rightBracket: >
        leftParenthesis: (
        rightParenthesis: )
      asToken: as
      type: NamedType
        name: Object
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_object_prefixed_withTypeArgs_insideDeclaration() {
    _parse('''
void f(x) {
  var async.Future<int>() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    importPrefix: ImportPrefixReference
      name: async
      period: .
    name: Future
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_prefixed_withTypeArgs_insideNullAssert() {
    _parse('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>()!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ObjectPattern
    type: NamedType
      importPrefix: ImportPrefixReference
        name: async
        period: .
      name: Future
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: !
''');
  }

  test_object_prefixed_withTypeArgs_insideNullCheck() {
    _parse('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>()?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ObjectPattern
    type: NamedType
      importPrefix: ImportPrefixReference
        name: async
        period: .
      name: Future
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: ?
''');
  }

  test_object_prefixedNamedUnderscore_withoutTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _.Future():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    importPrefix: ImportPrefixReference
      name: _
      period: .
    name: Future
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_prefixedNamedUnderscore_withoutTypeArgs_insideDeclaration() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  var _.Future() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    importPrefix: ImportPrefixReference
      name: _
      period: .
    name: Future
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_prefixedNamedUnderscore_withTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _.Future<int>():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    importPrefix: ImportPrefixReference
      name: _
      period: .
    name: Future
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_recovery_bogusTokensAfterPatternField() {
    // If the extra tokens after a pattern field don't look like they could be a
    // subsequent pattern field, the parser skips to the closing parenthesis to
    // avoid a large number of parse errors.
    _parse('''
void f(x) {
  switch (x) {
    case dynamic(foo: int() * 2):
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 55, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: dynamic
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: ObjectPattern
        type: NamedType
          name: int
        leftParenthesis: (
        rightParenthesis: )
  rightParenthesis: )
''');
  }

  test_object_recovery_missingClosingParen() {
    // If the extra tokens after a pattern don't look like they could be a
    // subsequent pattern field, and the pattern doesn't have a matching `)`,
    // the parser assumes it's the `)` that is missing.
    _parse('''
void f(x) {
  switch (x) {
    case dynamic(foo: int():
      break;
  }
}
''', errors: [
      error(ScannerErrorCode.EXPECTED_TOKEN, 71, 1),
    ]);
    var node = findNode.switchStatement('switch').members.single;
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ObjectPattern
      type: NamedType
        name: dynamic
      leftParenthesis: (
      fields
        PatternField
          name: PatternFieldName
            name: foo
            colon: :
          pattern: ObjectPattern
            type: NamedType
              name: int
            leftParenthesis: (
            rightParenthesis: )
      rightParenthesis: ) <synthetic>
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_object_recovery_missingComma() {
    // If the extra tokens after a pattern field look like they could be a
    // subsequent pattern field, the parser assumes there's a missing comma.
    _parse('''
void f(x) {
  switch (x) {
    case dynamic(foo: int() bar: int()):
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 55, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: dynamic
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: ObjectPattern
        type: NamedType
          name: int
        leftParenthesis: (
        rightParenthesis: )
    PatternField
      name: PatternFieldName
        name: bar
        colon: :
      pattern: ObjectPattern
        type: NamedType
          name: int
        leftParenthesis: (
        rightParenthesis: )
  rightParenthesis: )
''');
  }

  test_object_unprefixed_withoutTypeArgs_insideCast() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: 1) as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ObjectPattern
    type: NamedType
      name: C
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_object_unprefixed_withoutTypeArgs_insideNullAssert() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: 1)!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ObjectPattern
    type: NamedType
      name: C
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  operator: !
''');
  }

  test_object_unprefixed_withoutTypeArgs_insideNullCheck() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: 1)?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ObjectPattern
    type: NamedType
      name: C
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  operator: ?
''');
  }

  test_object_unprefixed_withTypeArgs_insideCase() {
    _parse('''
class C<T> {}
void f(x) {
  switch (x) {
    case C<int>():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_unprefixed_withTypeArgs_insideDeclaration() {
    _parse('''
class C<T> {}
void f(x) {
  var C<int>() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_unprefixed_withTypeArgs_insideNullAssert() {
    _parse('''
class C<T> {
  T? f;
}
void f(x) {
  switch (x) {
    case C<int>(f: 1)!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ObjectPattern
    type: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  operator: !
''');
  }

  test_object_unprefixedNamedUnderscore_withoutTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: _
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_unprefixedNamedUnderscore_withoutTypeArgs_insideDeclaration() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  var _() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: _
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_unprefixedNamedUnderscore_withTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _<int>():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: _
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_unprefixedNamedUnderscore_withTypeArgs_insideDeclaration() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  var _<int>() = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: _
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_parenthesized_insideAssignment() {
    _parse('''
f(x) {
  (a) = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: AssignedVariablePattern
    name: a
  rightParenthesis: )
''');
  }

  test_parenthesized_insideCase() {
    _parse('''
f(x) {
  switch (x) {
    case (1):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  rightParenthesis: )
''');
  }

  test_parenthesized_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case (1) as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_parenthesized_insideDeclaration() {
    _parse('''
f(x) {
  var (a) = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    name: a
  rightParenthesis: )
''');
  }

  test_parenthesized_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case (1)!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    rightParenthesis: )
  operator: !
''');
  }

  test_parenthesized_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case (1)?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    rightParenthesis: )
  operator: ?
''');
  }

  test_pattern_inForIn_element_noMetadata() {
    _parse('''
void f(x) => [for (var (a, b) in x) 0];
''');
    var node = findNode.forElement('for');
    assertParsedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
        PatternField
          pattern: DeclaredVariablePattern
            name: b
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
''');
  }

  test_pattern_inForIn_element_withMetadata() {
    _parse('''
void f(x) => [for (@annotation var (a, b) in x) 0];
''');
    var node = findNode.forElement('for');
    assertParsedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
        PatternField
          pattern: DeclaredVariablePattern
            name: b
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
''');
  }

  test_pattern_inForIn_statement_noMetadata() {
    _parse('''
void f(x) {
  for (var (a, b) in x) {}
}
''');
    var node = findNode.forStatement('for');
    assertParsedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
        PatternField
          pattern: DeclaredVariablePattern
            name: b
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_pattern_inForIn_statement_withMetadata() {
    _parse('''
void f(x) {
  for (@annotation var (a, b) in x) {}
}
''');
    var node = findNode.forStatement('for');
    assertParsedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
        PatternField
          pattern: DeclaredVariablePattern
            name: b
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_pattern_inForInitializer_element() {
    _parse('''
void f(x) => [for (var (a, b) = x; ;) 0];
''');
    var node = findNode.forElement('for');
    assertParsedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
          PatternField
            pattern: DeclaredVariablePattern
              name: b
        rightParenthesis: )
      equals: =
      expression: SimpleIdentifier
        token: x
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
''');
  }

  test_pattern_inForInitializer_statement() {
    _parse('''
void f(x) {
  for (var (a, b) = x; ;) {}
}
''');
    var node = findNode.forStatement('for');
    assertParsedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
          PatternField
            pattern: DeclaredVariablePattern
              name: b
        rightParenthesis: )
      equals: =
      expression: SimpleIdentifier
        token: x
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_pattern_inForPartsWithExpression_element() {
    _parse('''
void f(x) => [for ((a, b) = x; ;) 0];
''');
    var node = findNode.forElement('for');
    assertParsedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    initialization: PatternAssignment
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: AssignedVariablePattern
              name: a
          PatternField
            pattern: AssignedVariablePattern
              name: b
        rightParenthesis: )
      equals: =
      expression: SimpleIdentifier
        token: x
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
''');
  }

  test_pattern_inForPartsWithExpression_statement() {
    _parse('''
void f(x) {
  for ((a, b) = x; ;) {}
}
''');
    var node = findNode.forStatement('for');
    assertParsedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    initialization: PatternAssignment
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: AssignedVariablePattern
              name: a
          PatternField
            pattern: AssignedVariablePattern
              name: b
        rightParenthesis: )
      equals: =
      expression: SimpleIdentifier
        token: x
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_patternAssignment_declaresVariableWithMissingName() {
    // Test case from https://github.com/dart-lang/sdk/issues/54178.
    _parse('''
void main() {
  final b = (final g, final ) = 55;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 33, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 42, 1),
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 42, 1),
    ]);
    // No assertion on the parsed node text; all we are concerned with is that
    // the parser doesn't crash.
  }

  test_patternVariableDeclaration_inClass() {
    // If a pattern variable declaration appears outside a function or method,
    // the parser recovers by replacing the pattern with a synthetic identifier,
    // so that it parses as an ordinary field or top level variable declaration.
    _parse('''
class C {
  var (a, b) = (0, 1);
}
''', errors: [
      error(
          ParserErrorCode
              .PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD,
          16,
          6),
    ]);
    var node = findNode.classDeclaration('class');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  name: C
  leftBracket: {
  members
    FieldDeclaration
      fields: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: <empty> <synthetic>
            equals: =
            initializer: RecordLiteral
              leftParenthesis: (
              fields
                IntegerLiteral
                  literal: 0
                IntegerLiteral
                  literal: 1
              rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_patternVariableDeclaration_topLevel() {
    // If a pattern variable declaration appears outside a function or method,
    // the parser recovers by replacing the pattern with a synthetic identifier,
    // so that it parses as an ordinary field or top level variable declaration.
    _parse('''
var (a, b) = (0, 1);
''', errors: [
      error(
          ParserErrorCode
              .PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD,
          4,
          6),
    ]);
    var node = findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: <empty> <synthetic>
            equals: =
            initializer: RecordLiteral
              leftParenthesis: (
              fields
                IntegerLiteral
                  literal: 0
                IntegerLiteral
                  literal: 1
              rightParenthesis: )
      semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_disallowsConst() {
    // TODO(paulberry): do better error recovery.
    _parse('''
f(x) {
  const (_) = x;
}
''', errors: [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 9, 9),
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 9, 9),
      error(ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA, 17,
          1),
    ]);
  }

  test_patternVariableDeclarationStatement_disallowsLate() {
    _parse('''
f(x) {
  late var (_) = x;
}
''', errors: [
      error(ParserErrorCode.LATE_PATTERN_VARIABLE_DECLARATION, 9, 4),
    ]);
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: WildcardPattern
        name: _
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_final_extractor() {
    _parse('''
f(x) {
  final C(f: a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ObjectPattern
      type: NamedType
        name: C
      leftParenthesis: (
      fields
        PatternField
          name: PatternFieldName
            name: f
            colon: :
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_final_list() {
    _parse('''
f(x) {
  final [a] = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ListPattern
      leftBracket: [
      elements
        DeclaredVariablePattern
          name: a
      rightBracket: ]
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_final_map() {
    _parse('''
f(x) {
  final {'a': a} = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: MapPattern
      leftBracket: {
      elements
        MapPatternEntry
          key: SimpleStringLiteral
            literal: 'a'
          separator: :
          value: DeclaredVariablePattern
            name: a
      rightBracket: }
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_final_parenthesized() {
    _parse('''
f(x) {
  final (a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_final_record() {
    _parse('''
f(x) {
  final (a,) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_var_extractor() {
    _parse('''
f(x) {
  var C(f: a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ObjectPattern
      type: NamedType
        name: C
      leftParenthesis: (
      fields
        PatternField
          name: PatternFieldName
            name: f
            colon: :
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_var_list() {
    _parse('''
f(x) {
  var [a] = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ListPattern
      leftBracket: [
      elements
        DeclaredVariablePattern
          name: a
      rightBracket: ]
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_var_map() {
    _parse('''
f(x) {
  var {'a': a} = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: MapPattern
      leftBracket: {
      elements
        MapPatternEntry
          key: SimpleStringLiteral
            literal: 'a'
          separator: :
          value: DeclaredVariablePattern
            name: a
      rightBracket: }
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_var_parenthesized() {
    _parse('''
f(x) {
  var (a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_noMetadata_var_record() {
    _parse('''
f(x) {
  var (a,) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_final_extractor() {
    _parse('''
f(x) {
  @annotation
  final C(f: a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: final
    pattern: ObjectPattern
      type: NamedType
        name: C
      leftParenthesis: (
      fields
        PatternField
          name: PatternFieldName
            name: f
            colon: :
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_final_list() {
    _parse('''
f(x) {
  @annotation
  final [a] = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: final
    pattern: ListPattern
      leftBracket: [
      elements
        DeclaredVariablePattern
          name: a
      rightBracket: ]
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_final_map() {
    _parse('''
f(x) {
  @annotation
  final {'a': a} = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: final
    pattern: MapPattern
      leftBracket: {
      elements
        MapPatternEntry
          key: SimpleStringLiteral
            literal: 'a'
          separator: :
          value: DeclaredVariablePattern
            name: a
      rightBracket: }
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_final_parenthesized() {
    _parse('''
f(x) {
  @annotation
  final (a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_final_record() {
    _parse('''
f(x) {
  @annotation
  final (a,) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: final
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_var_extractor() {
    _parse('''
f(x) {
  @annotation
  var C(f: a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: var
    pattern: ObjectPattern
      type: NamedType
        name: C
      leftParenthesis: (
      fields
        PatternField
          name: PatternFieldName
            name: f
            colon: :
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_var_list() {
    _parse('''
f(x) {
  @annotation
  var [a] = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: var
    pattern: ListPattern
      leftBracket: [
      elements
        DeclaredVariablePattern
          name: a
      rightBracket: ]
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_var_map() {
    _parse('''
f(x) {
  @annotation
  var {'a': a} = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: var
    pattern: MapPattern
      leftBracket: {
      elements
        MapPatternEntry
          key: SimpleStringLiteral
            literal: 'a'
          separator: :
          value: DeclaredVariablePattern
            name: a
      rightBracket: }
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_var_parenthesized() {
    _parse('''
f(x) {
  @annotation
  var (a) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_patternVariableDeclarationStatement_withMetadata_var_record() {
    _parse('''
f(x) {
  @annotation
  var (a,) = x;
}
''');
    var node = findNode.patternVariableDeclarationStatement('= x');
    assertParsedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    metadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: annotation
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
  semicolon: ;
''');
  }

  test_prefixedIdentifier_when_not() {
    // Based on the repro from https://github.com/dart-lang/sdk/issues/52199.
    _parse('''
void f(x) {
  switch (x) {
    case Enum.value when !flag:
  }
}
''');
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: Enum
        period: .
        identifier: SimpleIdentifier
          token: value
    whenClause: WhenClause
      whenKeyword: when
      expression: PrefixExpression
        operator: !
        operand: SimpleIdentifier
          token: flag
  colon: :
''');
  }

  test_record_insideAssignment_empty() {
    _parse('''
void f(x) {
  () = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_record_insideAssignment_oneField() {
    _parse('''
void f(x) {
  (a,) = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: AssignedVariablePattern
        name: a
  rightParenthesis: )
''');
  }

  test_record_insideAssignment_twoFields() {
    _parse('''
void f(x) {
  (a, b) = x;
}
''');
    var node = findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: AssignedVariablePattern
        name: a
    PatternField
      pattern: AssignedVariablePattern
        name: b
  rightParenthesis: )
''');
  }

  test_record_insideCase_empty() {
    _parse('''
void f(x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_record_insideCase_oneField() {
    _parse('''
void f(x) {
  switch (x) {
    case (1,):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 1
  rightParenthesis: )
''');
  }

  test_record_insideCase_twoFields() {
    _parse('''
void f(x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 1
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_record_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case (1, 2) as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      PatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_record_insideDeclaration_empty() {
    _parse('''
void f(x) {
  var () = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_record_insideDeclaration_oneField() {
    _parse('''
void f(x) {
  var (a,) = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        name: a
  rightParenthesis: )
''');
  }

  test_record_insideDeclaration_twoFields() {
    _parse('''
void f(x) {
  var (a, b) = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        name: a
    PatternField
      pattern: DeclaredVariablePattern
        name: b
  rightParenthesis: )
''');
  }

  test_record_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case (1, 2)!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      PatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
    rightParenthesis: )
  operator: !
''');
  }

  test_record_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case (1, 2)?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      PatternField
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
    rightParenthesis: )
  operator: ?
''');
  }

  test_recordPattern_nonNullable_beforeAs() {
    _parse('''
void f(x) {
  switch (x) {
    case (_,) as (Object,):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: CastPattern
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: WildcardPattern
            name: _
      rightParenthesis: )
    asToken: as
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: Object
      rightParenthesis: )
''');
  }

  test_recordPattern_nonNullable_beforeWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case (_,) when true:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: WildcardPattern
          name: _
    rightParenthesis: )
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_recordPattern_nullable_beforeAs() {
    _parse('''
void f(x) {
  switch (x) {
    case (_,)? as (Object,):
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 36, 5),
    ]);
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: CastPattern
    pattern: NullCheckPattern
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: WildcardPattern
              name: _
        rightParenthesis: )
      operator: ?
    asToken: as
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: Object
      rightParenthesis: )
''');
  }

  test_recordPattern_nullable_beforeWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case (_,)? when true:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullCheckPattern
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: WildcardPattern
            name: _
      rightParenthesis: )
    operator: ?
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeAnd() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) y && _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalAndPattern
    leftOperand: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: y
    operator: &&
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeAs() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) y as (Object,):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: CastPattern
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: y
    asToken: as
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: Object
      rightParenthesis: )
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeColon() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) y:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
    name: y
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeComma() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,) y, _]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      DeclaredVariablePattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
        name: y
      WildcardPattern
        name: _
    rightBracket: ]
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeExclamation() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) y!:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullAssertPattern
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: y
    operator: !
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeOr() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) y || _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: y
    operator: ||
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeQuestion() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) y?:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullCheckPattern
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: y
    operator: ?
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeRightArrow() {
    _parse('''
void f(x) => switch (x) { (int,) y => 0 };
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
    name: y
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeRightBrace() {
    _parse('''
void f(x) {
  switch (x) {
    case {0: (int,) y}:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: IntegerLiteral
          literal: 0
        separator: :
        value: DeclaredVariablePattern
          type: RecordTypeAnnotation
            leftParenthesis: (
            positionalFields
              RecordTypeAnnotationPositionalField
                type: NamedType
                  name: int
            rightParenthesis: )
          name: y
    rightBracket: }
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeRightBracket() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,) y]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      DeclaredVariablePattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
        name: y
    rightBracket: ]
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeRightParen() {
    _parse('''
void f(x) {
  switch (x) {
    case ((int,) y):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: y
    rightParenthesis: )
''');
  }

  test_recordTypedVariablePattern_nonNullable_beforeWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) y when true:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
    name: y
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_recordTypedVariablePattern_nullable_beforeAnd() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? y && _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalAndPattern
    leftOperand: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: y
    operator: &&
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedVariablePattern_nullable_beforeAs() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? y as (Object,):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: CastPattern
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: y
    asToken: as
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: Object
      rightParenthesis: )
''');
  }

  test_recordTypedVariablePattern_nullable_beforeColon() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? y:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
      question: ?
    name: y
''');
  }

  test_recordTypedVariablePattern_nullable_beforeComma() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,)? y, _]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      DeclaredVariablePattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
          question: ?
        name: y
      WildcardPattern
        name: _
    rightBracket: ]
''');
  }

  test_recordTypedVariablePattern_nullable_beforeExclamation() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? y!:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullAssertPattern
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: y
    operator: !
''');
  }

  test_recordTypedVariablePattern_nullable_beforeOr() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? y || _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: y
    operator: ||
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedVariablePattern_nullable_beforeQuestion() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? y?:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullCheckPattern
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: y
    operator: ?
''');
  }

  test_recordTypedVariablePattern_nullable_beforeRightArrow() {
    _parse('''
void f(x) => switch (x) { (int,)? y => 0 };
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
      question: ?
    name: y
''');
  }

  test_recordTypedVariablePattern_nullable_beforeRightBrace() {
    _parse('''
void f(x) {
  switch (x) {
    case {0: (int,)? y}:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: IntegerLiteral
          literal: 0
        separator: :
        value: DeclaredVariablePattern
          type: RecordTypeAnnotation
            leftParenthesis: (
            positionalFields
              RecordTypeAnnotationPositionalField
                type: NamedType
                  name: int
            rightParenthesis: )
            question: ?
          name: y
    rightBracket: }
''');
  }

  test_recordTypedVariablePattern_nullable_beforeRightBracket() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,)? y]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      DeclaredVariablePattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
          question: ?
        name: y
    rightBracket: ]
''');
  }

  test_recordTypedVariablePattern_nullable_beforeRightParen() {
    _parse('''
void f(x) {
  switch (x) {
    case ((int,)? y):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: DeclaredVariablePattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: y
    rightParenthesis: )
''');
  }

  test_recordTypedVariablePattern_nullable_beforeWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? y when true:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
      question: ?
    name: y
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeAnd() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) _ && _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalAndPattern
    leftOperand: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: _
    operator: &&
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeAs() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) _ as (Object,):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: CastPattern
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: _
    asToken: as
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: Object
      rightParenthesis: )
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeColon() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
    name: _
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeComma() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,) _, _]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      WildcardPattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
        name: _
      WildcardPattern
        name: _
    rightBracket: ]
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeExclamation() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) _!:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullAssertPattern
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: _
    operator: !
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeOr() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) _ || _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalOrPattern
    leftOperand: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: _
    operator: ||
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeQuestion() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) _?:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullCheckPattern
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: _
    operator: ?
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeRightArrow() {
    _parse('''
void f(x) => switch (x) { (int,) _ => 0 };
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
    name: _
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeRightBrace() {
    _parse('''
void f(x) {
  switch (x) {
    case {0: (int,) _}:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: IntegerLiteral
          literal: 0
        separator: :
        value: WildcardPattern
          type: RecordTypeAnnotation
            leftParenthesis: (
            positionalFields
              RecordTypeAnnotationPositionalField
                type: NamedType
                  name: int
            rightParenthesis: )
          name: _
    rightBracket: }
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeRightBracket() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,) _]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      WildcardPattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
        name: _
    rightBracket: ]
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeRightParen() {
    _parse('''
void f(x) {
  switch (x) {
    case ((int,) _):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
      name: _
    rightParenthesis: )
''');
  }

  test_recordTypedWildcardPattern_nonNullable_beforeWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,) _ when true:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
    name: _
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeAnd() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? _ && _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalAndPattern
    leftOperand: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: _
    operator: &&
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeAs() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? _ as (Object,):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: CastPattern
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: _
    asToken: as
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: Object
      rightParenthesis: )
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeColon() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
      question: ?
    name: _
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeComma() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,)? _, _]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      WildcardPattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
          question: ?
        name: _
      WildcardPattern
        name: _
    rightBracket: ]
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeExclamation() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? _!:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullAssertPattern
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: _
    operator: !
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeOr() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? _ || _:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: LogicalOrPattern
    leftOperand: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: _
    operator: ||
    rightOperand: WildcardPattern
      name: _
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeQuestion() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? _?:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: NullCheckPattern
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: _
    operator: ?
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeRightArrow() {
    _parse('''
void f(x) => switch (x) { (int,)? _ => 0 };
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
      question: ?
    name: _
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeRightBrace() {
    _parse('''
void f(x) {
  switch (x) {
    case {0: (int,)? _}:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: IntegerLiteral
          literal: 0
        separator: :
        value: WildcardPattern
          type: RecordTypeAnnotation
            leftParenthesis: (
            positionalFields
              RecordTypeAnnotationPositionalField
                type: NamedType
                  name: int
            rightParenthesis: )
            question: ?
          name: _
    rightBracket: }
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeRightBracket() {
    _parse('''
void f(x) {
  switch (x) {
    case [(int,)? _]:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ListPattern
    leftBracket: [
    elements
      WildcardPattern
        type: RecordTypeAnnotation
          leftParenthesis: (
          positionalFields
            RecordTypeAnnotationPositionalField
              type: NamedType
                name: int
          rightParenthesis: )
          question: ?
        name: _
    rightBracket: ]
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeRightParen() {
    _parse('''
void f(x) {
  switch (x) {
    case ((int,)? _):
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: WildcardPattern
      type: RecordTypeAnnotation
        leftParenthesis: (
        positionalFields
          RecordTypeAnnotationPositionalField
            type: NamedType
              name: int
        rightParenthesis: )
        question: ?
      name: _
    rightParenthesis: )
''');
  }

  test_recordTypedWildcardPattern_nullable_beforeWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case (int,)? _ when true:
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
      rightParenthesis: )
      question: ?
    name: _
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_relational_containingBitwiseOrExpression_equality() {
    _parse('''
void f(x) {
  switch (x) {
    case == 1 | 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: |
    rightOperand: IntegerLiteral
      literal: 2
''');
  }

  test_relational_containingBitwiseOrExpression_relational() {
    _parse('''
void f(x) {
  switch (x) {
    case > 1 | 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: |
    rightOperand: IntegerLiteral
      literal: 2
''');
  }

  test_relational_containingRelationalExpression_equality() {
    // The patterns grammar doesn't allow a relational expression inside a
    // relational pattern (even though technically it would be unambiguous).
    // TODO(paulberry): try to improve parser error recovery in this scenario.
    _parse('''
void f(x) {
  switch (x) {
    case == 1 > 0:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 41, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 41, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 43, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 44, 1),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 44, 1),
    ]);
    // We don't care what the parsed AST is, just that there are errors.
  }

  test_relational_containingRelationalExpression_relational() {
    // The patterns grammar doesn't allow a relational expression inside a
    // relational pattern (even though technically it would be unambiguous).
    // TODO(paulberry): try to improve parser error recovery in this scenario.
    _parse('''
void f(x) {
  switch (x) {
    case > 1 > 0:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 40, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 40, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 42, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 43, 1),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 43, 1),
    ]);
    // We don't care what the parsed AST is, just that there are errors.
  }

  test_relational_insideCase_equal() {
    _parse('''
void f(x) {
  switch (x) {
    case == 1 << 1:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 1
''');
  }

  test_relational_insideCase_greaterThan() {
    _parse('''
void f(x) {
  switch (x) {
    case > 1 << 1:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 1
''');
  }

  test_relational_insideCase_greaterThanOrEqual() {
    _parse('''
void f(x) {
  switch (x) {
    case >= 1 << 1:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 1
''');
  }

  test_relational_insideCase_lessThan() {
    _parse('''
void f(x) {
  switch (x) {
    case < 1 << 1:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 1
''');
  }

  test_relational_insideCase_lessThanOrEqual() {
    _parse('''
void f(x) {
  switch (x) {
    case <= 1 << 1:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 1
''');
  }

  test_relational_insideCase_notEqual() {
    _parse('''
void f(x) {
  switch (x) {
    case != 1 << 1:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: !=
  operand: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 1
    operator: <<
    rightOperand: IntegerLiteral
      literal: 1
''');
  }

  test_relational_insideIfCase() {
    _parse('''
void f(x) {
  if (x case == 1) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: RelationalPattern
      operator: ==
      operand: IntegerLiteral
        literal: 1
''');
  }

  test_relational_insideList() {
    _parse('''
void f(x) {
  switch (x) {
    case [== 1]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    RelationalPattern
      operator: ==
      operand: IntegerLiteral
        literal: 1
  rightBracket: ]
''');
  }

  test_relational_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case == 1 && 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 1
  operator: &&
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_relational_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 && == 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalAndPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: &&
  rightOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 2
''');
  }

  test_relational_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case == 1 || 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 1
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_relational_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 || == 2:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
LogicalOrPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: ||
  rightOperand: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 2
''');
  }

  test_relational_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': == 1}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 1
  rightBracket: }
''');
  }

  test_relational_insideNullCheck_equal() {
    _parse('''
void f(x) {
  switch (x) {
    case == 1?:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 36, 4),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 1
  operator: ?
''');
  }

  test_relational_insideNullCheck_greaterThan() {
    _parse('''
void f(x) {
  switch (x) {
    case > 1?:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN, 36, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: RelationalPattern
    operator: >
    operand: IntegerLiteral
      literal: 1
  operator: ?
''');
  }

  test_relational_insideObject_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: == 1):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: f
        colon: :
      pattern: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 1
  rightParenthesis: )
''');
  }

  test_relational_insideParenthesized() {
    _parse('''
void f(x) {
  switch (x) {
    case (== 1):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: RelationalPattern
    operator: ==
    operand: IntegerLiteral
      literal: 1
  rightParenthesis: )
''');
  }

  test_relational_insideRecord_explicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (n: == 1, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: n
        colon: :
      pattern: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 1
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_relational_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (== 1, 2):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: RelationalPattern
        operator: ==
        operand: IntegerLiteral
          literal: 1
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_rest_subpatternStartingTokens() {
    // Test a wide variety of rest subpatterns to make sure the parser properly
    // identifies each as a subpattern.  (The logic for deciding if a rest
    // pattern has a subpattern is based on the token that follows the `..`, so
    // we test every kind of token that can legally follow `...`).  Note that
    // not all of these are semantically meaningful, but they should all be
    // parseable.
    // TODO(paulberry): if support for symbol literal patterns is added (see
    // https://github.com/dart-lang/language/issues/2636), adjust this test
    // accordingly.
    _parse('''
void f(x) {
  switch (x) {
    case [...== null]:
    case [...!= null]:
    case [...< 0]:
    case [...> 0]:
    case [...<= 0]:
    case [...>= 0]:
    case [...0]:
    case [...0.0]:
    case [...0x0]:
    case [...null]:
    case [...false]:
    case [...true]:
    case [...'foo']:
    case [...x]:
    case [...const List()]:
    case [...var x]:
    case [...final x]:
    case [...List x]:
    case [..._]:
    case [...(_)]:
    case [...[_]]:
    case [...[]]:
    case [...<int>[]]:
    case [...{}]:
    case [...List()]:
      break;
  }
}
''');
    // No assertions; it's sufficient to make sure the parse succeeds without
    // errors.
  }

  test_rest_withoutSubpattern_insideList() {
    _parse('''
void f(x) {
  switch (x) {
    case [...]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    RestPatternElement
      operator: ...
  rightBracket: ]
''');
  }

  test_rest_withoutSubpattern_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {...}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    RestPatternElement
      operator: ...
  rightBracket: }
''');
  }

  test_rest_withSubpattern_insideList() {
    _parse('''
void f(x) {
  switch (x) {
    case [...var y]:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    RestPatternElement
      operator: ...
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
  rightBracket: ]
''');
  }

  test_rest_withSubpattern_insideMap() {
    // The parser accepts this syntax even though it's not legal dart, because
    // we suspect it's a mistake a user is likely to make, and we want to ensure
    // that we give a helpful error message.
    _parse('''
void f(x) {
  switch (x) {
    case {...var y}:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    RestPatternElement
      operator: ...
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
  rightBracket: }
''');
  }

  test_skipOuterPattern_eof() {
    // See https://github.com/dart-lang/sdk/issues/50563
    _parse('''
main() {
  int var = 0;
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 11, 3),
      error(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
      error(ScannerErrorCode.EXPECTED_TOKEN, 24, 1),
    ]);
  }

  test_switchExpression_empty() {
    // Even though an empty switch expression is illegal (because it's not
    // exhaustive), it should be accepted by the parser to enable analyzer code
    // completions.
    _parse('''
f(x) => switch(x) {};
''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
  }

  test_switchExpression_onePattern_guarded() {
    _parse('''
f(x) => switch(x) {
  _ when true => 0
};
''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
        whenClause: WhenClause
          whenKeyword: when
          expression: BooleanLiteral
            literal: true
      arrow: =>
      expression: IntegerLiteral
        literal: 0
  rightBracket: }
''');
  }

  test_switchExpression_onePattern_noTrailingComma() {
    _parse('''
f(x) => switch(x) {
  _ => 0
};
''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 0
  rightBracket: }
''');
  }

  test_switchExpression_onePattern_trailingComma() {
    _parse('''
f(x) => switch(x) {
  _ => 0,
};
''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 0
  rightBracket: }
''');
  }

  test_switchExpression_recovery_bogusTokensAfterCase() {
    // If the extra tokens after a switch case don't look like they could be a
    // pattern, the parser skips to the end of the switch expression to avoid a
    // large number of parse errors.
    _parse('''
f(x) => switch(x) {
  int() => 0 : 1
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 33, 1),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ObjectPattern
          type: NamedType
            name: int
          leftParenthesis: (
          rightParenthesis: )
      arrow: =>
      expression: IntegerLiteral
        literal: 0
  rightBracket: }
''');
  }

  test_switchExpression_recovery_bogusTokensAfterCase_laterComma() {
    // If the extra tokens after a switch case don't look like they could be a
    // pattern, the parser doesn't try to skip beyond the closing `}` to find
    // the next case.
    _parse('''
f(x) => [switch(x) {
  int() => 0 : 1
}, 0];
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 34, 1),
    ]);
    var node = findNode.listLiteral('[');
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    SwitchExpression
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
      rightParenthesis: )
      leftBracket: {
      cases
        SwitchExpressionCase
          guardedPattern: GuardedPattern
            pattern: ObjectPattern
              type: NamedType
                name: int
              leftParenthesis: (
              rightParenthesis: )
          arrow: =>
          expression: IntegerLiteral
            literal: 0
      rightBracket: }
    IntegerLiteral
      literal: 0
  rightBracket: ]
''');
  }

  test_switchExpression_recovery_bogusTokensAfterCase_nestedComma() {
    // If the extra tokens after a switch case don't look like they could be a
    // pattern, the parser doesn't try to skip to a nested `,` trying to find
    // the next case.
    _parse('''
f(x) => switch(x) {
  int() => 0 : (1, 2)
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 33, 1),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ObjectPattern
          type: NamedType
            name: int
          leftParenthesis: (
          rightParenthesis: )
      arrow: =>
      expression: IntegerLiteral
        literal: 0
  rightBracket: }
''');
  }

  test_switchExpression_recovery_caseKeyword() {
    _parse('''
f(x) => switch (x) {
  case 1 => 'one',
  case 2 => 'two'
};
''', errors: [
      error(ParserErrorCode.UNEXPECTED_TOKEN, 23, 4),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 42, 4),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      arrow: =>
      expression: SimpleStringLiteral
        literal: 'one'
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
      arrow: =>
      expression: SimpleStringLiteral
        literal: 'two'
  rightBracket: }
''');
  }

  test_switchExpression_recovery_colonInsteadOfArrow() {
    _parse('''
f(x) => switch (x) {
  1: 'one',
  2: 'two'
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 24, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 36, 1),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      arrow: :
      expression: SimpleStringLiteral
        literal: 'one'
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
      arrow: :
      expression: SimpleStringLiteral
        literal: 'two'
  rightBracket: }
''');
  }

  test_switchExpression_recovery_defaultKeyword() {
    _parse('''
f(x) => switch (x) {
  1 => 'one',
  default => 'other'
};
''', errors: [
      error(ParserErrorCode.DEFAULT_IN_SWITCH_EXPRESSION, 37, 7),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      arrow: =>
      expression: SimpleStringLiteral
        literal: 'one'
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: default
      arrow: =>
      expression: SimpleStringLiteral
        literal: 'other'
  rightBracket: }
''');
  }

  test_switchExpression_recovery_illegalFunctionExpressionInGuard() {
    // If a function expression occurs in a guard, parsing skips to the case
    // that follows.
    _parse('''
f(x) => switch (x) {
  _ when () => true => 1,
  _ => 2
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 41, 2),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
        whenClause: WhenClause
          whenKeyword: when
          expression: RecordLiteral
            leftParenthesis: (
            rightParenthesis: )
      arrow: =>
      expression: BooleanLiteral
        literal: true
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 2
  rightBracket: }
''');
  }

  test_switchExpression_recovery_illegalFunctionExpressionInGuard_semicolon() {
    // If a function expression occurs in a guard, parsing skips to the case
    // that follows.  The logic to skip to the next case understands that a
    // naive user might have mistakenly used `;` instead of `,` to separate
    // cases.
    _parse('''
f(x) => switch (x) {
  _ when () => true => 1;
  _ => 2
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 41, 2),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
        whenClause: WhenClause
          whenKeyword: when
          expression: RecordLiteral
            leftParenthesis: (
            rightParenthesis: )
      arrow: =>
      expression: BooleanLiteral
        literal: true
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 2
  rightBracket: }
''');
  }

  test_switchExpression_recovery_missingComma() {
    // If the extra tokens after a switch case look like they could be a
    // pattern, the parser assumes there's a missing comma.
    _parse('''
f(x) => switch(x) {
  int() => 0
  double() => 1
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 35, 6),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ObjectPattern
          type: NamedType
            name: int
          leftParenthesis: (
          rightParenthesis: )
      arrow: =>
      expression: IntegerLiteral
        literal: 0
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ObjectPattern
          type: NamedType
            name: double
          leftParenthesis: (
          rightParenthesis: )
      arrow: =>
      expression: IntegerLiteral
        literal: 1
  rightBracket: }
''');
  }

  test_switchExpression_recovery_semicolonInsteadOfComma() {
    _parse('''
f(x) => switch (x) {
  1 => 'one';
  2 => 'two'
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 33, 1),
    ]);
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
      arrow: =>
      expression: SimpleStringLiteral
        literal: 'one'
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 2
      arrow: =>
      expression: SimpleStringLiteral
        literal: 'two'
  rightBracket: }
''');
  }

  test_switchExpression_recovery_unmatchedLessThanInTokensToBeSkipped() {
    // Test case from https://github.com/dart-lang/sdk/issues/54236.
    _parse('''
f(x) => switch (x) {
    1 => 2
    > 1 => 1
    < 1 => 0
};
''', errors: [
      error(ParserErrorCode.EXPECTED_TOKEN, 40, 2),
    ]);
    // No assertion on the parsed node text; all we are concerned with is that
    // the parser doesn't crash.
  }

  test_switchExpression_twoPatterns() {
    _parse('''
f(x) => switch(x) {
  int _ => 0,
  _ => 1
};
''');
    var node = findNode.switchExpression('switch');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          type: NamedType
            name: int
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 0
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 1
  rightBracket: }
''');
  }

  test_syntheticIdentifier_insideListPattern() {
    _parse('''
void f(Object? x) {
  switch (x) {
    case [if]:
  };
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 45, 2),
    ]);
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ListPattern
      leftBracket: [
      elements
        ConstantPattern
          expression: SimpleIdentifier
            token: <empty> <synthetic>
      rightBracket: ]
  colon: :
''');
  }

  test_syntheticIdentifier_insideMapPattern() {
    _parse('''
void f(Object? x) {
  switch (x) {
    case {0: if}:
  };
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 48, 2),
      error(ParserErrorCode.EXPECTED_TOKEN, 48, 2),
      error(ParserErrorCode.EXPECTED_TOKEN, 48, 2),
    ]);
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: MapPattern
      leftBracket: {
      elements
        MapPatternEntry
          key: IntegerLiteral
            literal: 0
          separator: :
          value: ConstantPattern
            expression: SimpleIdentifier
              token: <empty> <synthetic>
        MapPatternEntry
          key: SimpleIdentifier
            token: <empty> <synthetic>
          separator: : <synthetic>
          value: ConstantPattern
            expression: SimpleIdentifier
              token: <empty> <synthetic>
      rightBracket: }
  colon: :
''');
  }

  test_syntheticIdentifier_insideParenthesizedPattern() {
    _parse('''
void f(Object? x) {
  switch (x) {
    case (if):
  };
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 45, 2),
      error(ParserErrorCode.EXPECTED_TOKEN, 45, 2),
    ]);
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: ConstantPattern
        expression: SimpleIdentifier
          token: <empty> <synthetic>
      rightParenthesis: )
  colon: :
''');
  }

  test_syntheticIdentifier_insideRecordPattern() {
    _parse('''
void f(Object? x) {
  switch (x) {
    case (_, if):
  };
}
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 48, 2),
      error(ParserErrorCode.EXPECTED_TOKEN, 48, 2),
    ]);
    var node = findNode.switchPatternCase('case');
    assertParsedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: WildcardPattern
            name: _
        PatternField
          pattern: ConstantPattern
            expression: SimpleIdentifier
              token: <empty> <synthetic>
      rightParenthesis: )
  colon: :
''');
  }

  test_syntheticIdentifier_insideSwitchExpression() {
    _parse('''
void f(Object? x) => switch (x) {if};
''', errors: [
      error(ParserErrorCode.MISSING_IDENTIFIER, 33, 2),
      error(ParserErrorCode.EXPECTED_TOKEN, 33, 2),
      error(ParserErrorCode.EXPECTED_TOKEN, 33, 2),
    ]);
    var node = findNode.switchExpression('if');
    assertParsedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: SimpleIdentifier
            token: <empty> <synthetic>
      arrow: => <synthetic>
      expression: SimpleIdentifier
        token: <empty> <synthetic>
  rightBracket: }
''');
  }

  test_typeQuestionBeforeWhen_conditional() {
    // The logic for parsing types has special disambiguation rules for deciding
    // whether a trailing `?` should be included in the type; these rules are
    // based primarily on what token(s) follow the `?`.  Make sure that these
    // rules do the right thing if the token that follows the `?` is `when`, but
    // the `when` is an ordinary identifier.
    _parse('''
void f(condition, when, otherwise) => condition as bool ? when : otherwise;
''');
    var node = findNode.functionDeclaration('=>').functionExpression.body;
    assertParsedNodeText(node, r'''
ExpressionFunctionBody
  functionDefinition: =>
  expression: ConditionalExpression
    condition: AsExpression
      expression: SimpleIdentifier
        token: condition
      asOperator: as
      type: NamedType
        name: bool
    question: ?
    thenExpression: SimpleIdentifier
      token: when
    colon: :
    elseExpression: SimpleIdentifier
      token: otherwise
  semicolon: ;
''');
  }

  test_typeQuestionBeforeWhen_guard() {
    // The logic for parsing types has special disambiguation rules for deciding
    // whether a trailing `?` should be included in the type; these rules are
    // based primarily on what token(s) follow the `?`.  Make sure that these
    // rules do the right thing if the token that follows the `?` is the `when`
    // of a pattern guard.
    _parse('''
void f(x) {
  switch (x) {
    case _ as int? when x == null:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: CastPattern
    pattern: WildcardPattern
      name: _
    asToken: as
    type: NamedType
      name: int
      question: ?
  whenClause: WhenClause
    whenKeyword: when
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: ==
      rightOperand: NullLiteral
        literal: null
''');
  }

  test_variable_bare_insideCast() {
    _parse('''
void f(x) {
  var (y as Object) = x;
}
''');
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: CastPattern
    pattern: DeclaredVariablePattern
      name: y
    asToken: as
    type: NamedType
      name: Object
  rightParenthesis: )
''');
  }

  test_variable_final_inDeclarationContext() {
    _parse('''
void f(x) {
  var (final y) = x;
}
''', errors: [
      error(ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT, 19,
          5),
    ]);
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    keyword: final
    name: y
  rightParenthesis: )
''');
  }

  test_variable_final_untyped_insideIfCase() {
    _parse('''
void f(x) {
  if (x case final y) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: DeclaredVariablePattern
      keyword: final
      name: y
''');
  }

  test_variable_final_untyped_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case final y!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: y
  operator: !
''');
  }

  test_variable_final_untyped_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case final y?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: y
  operator: ?
''');
  }

  test_variable_namedAs() {
    _parse('''
void f(x) {
  switch (x) {
    case var as:
  }
}
''', errors: [error(ParserErrorCode.ILLEGAL_PATTERN_VARIABLE_NAME, 40, 2)]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: as
''');
  }

  test_variable_namedWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case var when:
  }
}
''', errors: [error(ParserErrorCode.ILLEGAL_PATTERN_VARIABLE_NAME, 40, 4)]);
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: when
''');
  }

  test_variable_type_record_empty_inDeclarationContext() {
    _parse('''
void f(x) {
  var (() y) = x;
}
''');
    var node = findNode.patternVariableDeclaration('var').pattern;
    assertParsedNodeText(node, '''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      rightParenthesis: )
    name: y
  rightParenthesis: )
''');
  }

  test_variable_type_record_empty_inMatchingContext() {
    _parse('''
void f(x) {
  switch (x) {
    case () y:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, '''
DeclaredVariablePattern
  type: RecordTypeAnnotation
    leftParenthesis: (
    rightParenthesis: )
  name: y
''');
  }

  test_variable_type_record_nonEmpty_inDeclarationContext() {
    _parse('''
void f(x) {
  var ((int, String) y) = x;
}
''');
    var node = findNode.patternVariableDeclaration('var').pattern;
    assertParsedNodeText(node, '''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    type: RecordTypeAnnotation
      leftParenthesis: (
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: String
      rightParenthesis: )
    name: y
  rightParenthesis: )
''');
  }

  test_variable_type_record_nonEmpty_inMatchingContext() {
    _parse('''
void f(x) {
  switch (x) {
    case (int, String) y:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, '''
DeclaredVariablePattern
  type: RecordTypeAnnotation
    leftParenthesis: (
    positionalFields
      RecordTypeAnnotationPositionalField
        type: NamedType
          name: int
      RecordTypeAnnotationPositionalField
        type: NamedType
          name: String
    rightParenthesis: )
  name: y
''');
  }

  test_variable_typed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case int y:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: int
  name: y
''');
  }

  test_variable_typed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case int y as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
    type: NamedType
      name: int
    name: y
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_variable_typed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case int y) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: DeclaredVariablePattern
      type: NamedType
        name: int
      name: y
''');
  }

  test_variable_typed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case int y!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: DeclaredVariablePattern
    type: NamedType
      name: int
    name: y
  operator: !
''');
  }

  test_variable_typed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case int y?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    type: NamedType
      name: int
    name: y
  operator: ?
''');
  }

  test_variable_typedNamedUnderscore_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _ y:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: _
  name: y
''');
  }

  test_variable_var_inDeclarationContext() {
    _parse('''
void f(x) {
  var (var y) = x;
}
''', errors: [
      error(ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT, 19,
          3),
    ]);
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
  rightParenthesis: )
''');
  }

  test_variable_var_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case var y:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
''');
  }

  test_variable_var_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case var y as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_variable_var_insideIfCase() {
    _parse('''
void f(x) {
  if (x case var y) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: DeclaredVariablePattern
      keyword: var
      name: y
''');
  }

  test_variable_var_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case var y!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
  operator: !
''');
  }

  test_variable_var_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case var y?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
  operator: ?
''');
  }

  test_varKeywordInTypedVariablePattern_declarationContext() {
    _parse('''
void f(int x) {
  var (var int y) = x;
}
''', errors: [
      error(ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT, 23,
          3),
    ]);
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    keyword: var
    type: NamedType
      name: int
    name: y
  rightParenthesis: )
''');
  }

  test_varKeywordInTypedVariablePattern_declarationContext_wildcard() {
    _parse('''
void f(x) {
  var (var int _) = x;
}
''', errors: [
      error(ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT, 19,
          3),
    ]);
    var node = findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: WildcardPattern
    keyword: var
    type: NamedType
      name: int
    name: _
  rightParenthesis: )
''');
  }

  test_varKeywordInTypedVariablePattern_matchingContext() {
    _parse('''
void f(x) {
  switch (x) {
    case var int y:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.VAR_AND_TYPE, 36, 3),
    ]);
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: var
    type: NamedType
      name: int
    name: y
''');
  }

  test_varKeywordInTypedVariablePattern_matchingContext_wildcard() {
    _parse('''
void f(x) {
  switch (x) {
    case var int _:
      break;
  }
}
''', errors: [
      error(ParserErrorCode.VAR_AND_TYPE, 36, 3),
    ]);
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    keyword: var
    type: NamedType
      name: int
    name: _
''');
  }

  test_wildcard_bare_beforeWhen() {
    _parse('''
void f(x) {
  switch (x) {
    case _ when true:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern;
    assertParsedNodeText(node, r'''
GuardedPattern
  pattern: WildcardPattern
    name: _
  whenClause: WhenClause
    whenKeyword: when
    expression: BooleanLiteral
      literal: true
''');
  }

  test_wildcard_bare_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  name: _
''');
  }

  test_wildcard_bare_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case _ as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: WildcardPattern
    name: _
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_wildcard_bare_insideIfCase() {
    _parse('''
void f(x) {
  if (x case _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
''');
  }

  test_wildcard_bare_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case _!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    name: _
  operator: !
''');
  }

  test_wildcard_bare_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case _?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    name: _
  operator: ?
''');
  }

  test_wildcard_final_typed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case final int _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  keyword: final
  type: NamedType
    name: int
  name: _
''');
  }

  test_wildcard_final_typed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case final int _ as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: WildcardPattern
    keyword: final
    type: NamedType
      name: int
    name: _
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_wildcard_final_typed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case final int _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      keyword: final
      type: NamedType
        name: int
      name: _
''');
  }

  test_wildcard_final_typed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case final int _!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    keyword: final
    type: NamedType
      name: int
    name: _
  operator: !
''');
  }

  test_wildcard_final_typed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case final int _?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    keyword: final
    type: NamedType
      name: int
    name: _
  operator: ?
''');
  }

  test_wildcard_final_untyped_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case final _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  keyword: final
  name: _
''');
  }

  test_wildcard_final_untyped_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case final _ as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: WildcardPattern
    keyword: final
    name: _
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_wildcard_final_untyped_insideIfCase() {
    _parse('''
void f(x) {
  if (x case final _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      keyword: final
      name: _
''');
  }

  test_wildcard_final_untyped_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case final _!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    keyword: final
    name: _
  operator: !
''');
  }

  test_wildcard_final_untyped_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case final _?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    keyword: final
    name: _
  operator: ?
''');
  }

  test_wildcard_inPatternAssignment_bareIdentifier() {
    _parse('''
void f() {
  [a, _] = y;
}
''');
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      WildcardPattern
        name: _
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_wildcard_inPatternAssignment_usingFinal() {
    _parse('''
void f() {
  [a, final _] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 23, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      WildcardPattern
        keyword: final
        name: _
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_wildcard_inPatternAssignment_usingFinalAndType() {
    _parse('''
void f() {
  [a, final int _] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 27, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      WildcardPattern
        keyword: final
        type: NamedType
          name: int
        name: _
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_wildcard_inPatternAssignment_usingType() {
    _parse('''
void f() {
  [a, int _] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 21, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      WildcardPattern
        type: NamedType
          name: int
        name: _
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_wildcard_inPatternAssignment_usingVar() {
    _parse('''
void f() {
  [a, var _] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 21, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      WildcardPattern
        keyword: var
        name: _
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_wildcard_inPatternAssignment_usingVarAndType() {
    _parse('''
void f() {
  [a, var int _] = y;
}
''', errors: [
      error(ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE, 25, 1),
    ]);
    var node = findNode.patternAssignment('=');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
      WildcardPattern
        keyword: var
        type: NamedType
          name: int
        name: _
    rightBracket: ]
  equals: =
  expression: SimpleIdentifier
    token: y
''');
  }

  test_wildcard_typed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case int _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  type: NamedType
    name: int
  name: _
''');
  }

  test_wildcard_typed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case int _ as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: WildcardPattern
    type: NamedType
      name: int
    name: _
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_wildcard_typed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case int _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      type: NamedType
        name: int
      name: _
''');
  }

  test_wildcard_typed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case int _!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    type: NamedType
      name: int
    name: _
  operator: !
''');
  }

  test_wildcard_typed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case int _?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    type: NamedType
      name: int
    name: _
  operator: ?
''');
  }

  test_wildcard_var_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case var _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  keyword: var
  name: _
''');
  }

  test_wildcard_var_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case var _ as Object:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: WildcardPattern
    keyword: var
    name: _
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_wildcard_var_insideIfCase() {
    _parse('''
void f(x) {
  if (x case var _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      keyword: var
      name: _
''');
  }

  test_wildcard_var_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case var _!:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    keyword: var
    name: _
  operator: !
''');
  }

  test_wildcard_var_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case var _?:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    keyword: var
    name: _
  operator: ?
''');
  }

  void _parse(String content, {List<ExpectedError>? errors}) {
    var parseResult = parseStringWithErrors(content);
    if (errors != null) {
      parseResult.assertErrors(errors);
    } else {
      parseResult.assertNoErrors();
    }
    findNode = parseResult.findNode;
  }
}
