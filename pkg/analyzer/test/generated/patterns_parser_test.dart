// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternsTest extends ParserDiagnosticsTest {
  test_assignedVariable_namedAs() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  dynamic as;
  (as) = x;
// ^^
// [diag.illegalPatternAssignmentVariableName] A variable assigned by a pattern assignment can't be named 'as'.
}
''');
    var node = parseResult.findNode.singlePatternAssignment.pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: AssignedVariablePattern
    name: as
  rightParenthesis: )
''');
  }

  test_assignedVariable_namedWhen() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  dynamic when;
  (when) = x;
// ^^^^
// [diag.illegalPatternAssignmentVariableName] A variable assigned by a pattern assignment can't be named 'when'.
}
''');
    var node = parseResult.findNode.singlePatternAssignment.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case A.
  }
//^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ':'.
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0 when true) 1];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0 when true) 1 else 2];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case 0 when true) {}
}
''');
    var node = parseResult.findNode.ifStatement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case 0 when true) {} else {}
}
''');
    var node = parseResult.findNode.ifStatement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 0 when true:
      break;
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0) 1];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0) 1 else 2];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case 0) {}
}
''');
    var node = parseResult.findNode.ifStatement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0 as int when true) 1];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0 as int when true) 1 else 2];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case 0 as int when true) {}
}
''');
    var node = parseResult.findNode.ifStatement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 0 as int when true:
      break;
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0 as int) 1];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[if (x case 0 as int) 1 else 2];
}
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case 0 as int) {}
}
''');
    var node = parseResult.findNode.ifStatement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 0 as int:
      break;
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int as num:
//       ^^^^^^^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case (y as int) as num:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case var y as int) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1 as int]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ as double? && Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ && double? _ as Object?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ as double? || Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ || double? _ as Object?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': 1 as int}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int!:
//       ^^^^^^^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as int? ?:
//       ^^^^^^^^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1 as int):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (n: 1 as int, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (: var n as int, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1 as int, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = abstract.as.get; // verify that this works
  switch (x) {
    case abstract.as.get:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b.c:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b.c as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case a.b.c) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b.c!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b.c?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = show.hide.when; // verify that this works
  switch (x) {
    case show.hide.when:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case as:
//       ^^
// [diag.illegalPatternIdentifierName] A pattern can't refer to an identifier named 'as'.
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: as
''');
  }

  test_constant_identifier_namedWhen() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case when:
//       ^^^^
// [diag.illegalPatternIdentifierName] A pattern can't refer to an identifier named 'when'.
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: when
''');
  }

  test_constant_identifier_prefixed_builtin() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = abstract.as; // verify that this works
  switch (x) {
    case abstract.as:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case a.b) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case a.b?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = show.hide; // verify that this works
  switch (x) {
    case show.hide:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _.b:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y when true:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = abstract; // verify that this works
  switch (x) {
    case abstract:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: abstract
''');
  }

  test_constant_identifier_unprefixed_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: y
''');
  }

  test_constant_identifier_unprefixed_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  if (x case y) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: !
''');
  }

  test_constant_identifier_unprefixed_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: ?
''');
  }

  test_constant_identifier_unprefixed_insideSwitchExpression() {
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
  y => 0
};
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: y
''');
  }

  test_constant_identifier_unprefixed_pseudoKeyword() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = show; // verify that this works
  switch (x) {
    case show:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: show
''');
  }

  test_constant_list_typed_empty_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[] as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const <int>[]) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[]!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[]?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[1]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[1] as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const <int>[1]) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[1]!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>[1]?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const []:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
  expression: ListLiteral
    leftBracket: [
    rightBracket: ]
''');
  }

  test_constant_list_untyped_empty_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const [] as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
    expression: ListLiteral
      leftBracket: [
      rightBracket: ]
  asToken: as
  type: NamedType
    name: Object
''');
  }

  test_constant_list_untyped_empty_insideIfCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const []) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
      expression: ListLiteral
        leftBracket: [
        rightBracket: ]
''');
  }

  test_constant_list_untyped_empty_insideNullAssert() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const []!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
    expression: ListLiteral
      leftBracket: [
      rightBracket: ]
  operator: !
''');
  }

  test_constant_list_untyped_empty_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const []?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
    expression: ListLiteral
      leftBracket: [
      rightBracket: ]
  operator: ?
''');
  }

  test_constant_list_untyped_nonEmpty_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const [1]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
  expression: ListLiteral
    leftBracket: [
    elements
      IntegerLiteral
        literal: 1
    rightBracket: ]
''');
  }

  test_constant_list_untyped_nonEmpty_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const [1] as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const [1]) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 1
        rightBracket: ]
''');
  }

  test_constant_list_untyped_nonEmpty_insideNullAssert() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const [1]!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const [1]?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2} as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const <int, int>{1: 2}) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2}!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int, int>{1: 2}?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1: 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1: 2} as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const {1: 2}) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1: 2}!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1: 2}?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const Foo(1):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const Foo(1) as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const Foo(1)) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const Foo(1)!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const Foo(1)?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const (1):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
  expression: ParenthesizedExpression
    leftParenthesis: (
    expression: IntegerLiteral
      literal: 1
    rightParenthesis: )
''');
  }

  test_constant_parenthesized_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const (1) as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const (1)) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
      expression: ParenthesizedExpression
        leftParenthesis: (
        expression: IntegerLiteral
          literal: 1
        rightParenthesis: )
''');
  }

  test_constant_parenthesized_insideNullAssert() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const (1)!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: IntegerLiteral
        literal: 1
      rightParenthesis: )
  operator: !
''');
  }

  test_constant_parenthesized_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const (1)?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
    expression: ParenthesizedExpression
      leftParenthesis: (
      expression: IntegerLiteral
        literal: 1
      rightParenthesis: )
  operator: ?
''');
  }

  test_constant_set_typed_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>{1}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>{1} as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const <int>{1}) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>{1}!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const <int>{1}?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1} as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case const {1}) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1}!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case const {1}?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, final d] = y;
//          ^
// [diag.patternAssignmentDeclaresVariable] Variable 'd' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, final int d] = y;
//              ^
// [diag.patternAssignmentDeclaresVariable] Variable 'd' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, int d] = y;
//        ^
// [diag.patternAssignmentDeclaresVariable] Variable 'd' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, var d] = y;
//        ^
// [diag.patternAssignmentDeclaresVariable] Variable 'd' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, var int d] = y;
//            ^
// [diag.patternAssignmentDeclaresVariable] Variable 'd' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    parseTestCodeWithDiagnostics('''
f() {
  try {
    true ?  : 2;
//          ^
// [diag.missingIdentifier] Expected an identifier.
  } catch (e) {}
}
''');
  }

  test_functionExpression_allowed_afterSwitchExpression() {
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {} + () => 0;
''');
    var node = parseResult.findNode.functionDeclaration('f');
    assertParsedNodeText(node, r'''
FunctionDeclaration
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x, y) => [if (x case _ when y + () => 0) 0];
''');
    var node = parseResult.findNode.ifElement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x, y) {
  if (x case _ when y + () => 0) {}
}
''');
    var node = parseResult.findNode.ifStatement('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { [== () => 0] => 0 };
''');
    var node = parseResult.findNode
        .switchExpressionCase('() => 0')
        .guardedPattern
        .pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { {'x': == () => 0} => 0 };
''');
    var node = parseResult.findNode
        .switchExpressionCase('() => 0')
        .guardedPattern
        .pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { Foo(bar: == () => 0) => 0 };
''');
    var node = parseResult.findNode
        .switchExpressionCase('() => 0')
        .guardedPattern
        .pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { const (() => 0) => 0 };
''');
    var node = parseResult.findNode
        .switchExpressionCase('() => 0')
        .guardedPattern
        .pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { (== () => 0) => 0 };
''');
    var node = parseResult.findNode
        .switchExpressionCase('() => 0')
        .guardedPattern
        .pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { _ when switch(x) { _ when true => () => 0 } => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('() => 0');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { _ when switch(x) { _ => () => 0 } => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('() => 0');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f() => switch(() => 0) {};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x, y) {
  switch(x) {
    case _ when y + () => 0:
      break;
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('when');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { [_] when () => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('when');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { {'x': _} when () => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('when');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { Foo(bar: _) when () => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('when');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { (_) when () => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('when');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) { _ when switch(x) {} + () => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('when');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x, y) => switch(x) { _ when y + () => 0 };
''');
    var node = parseResult.findNode.switchExpressionCase('when');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case foo as when:
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case foo when as:
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case foo when !flag:
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case foo when when:
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x, bool Function() a) => switch(x) {
  _ when a() => 0
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(Object? x) {
  (switch (x) {
    const A() => 0,
    _ => 1,
  });
}''');
    var node = parseResult.findNode.switchExpression('switch');
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
          constKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <int>[a, b] = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  [] = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideAssignment_untyped_emptyWithWhitespace() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  [ ] = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideAssignment_untyped_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  [a, b] = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case <int>[1, 2]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideCase_untyped_emptyWithWhitespace() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [ ]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideCase_untyped_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1] as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var <int>[a, b] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var [] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideDeclaration_untyped_emptyWithWhitespace() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var [ ] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_list_insideDeclaration_untyped_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var [a, b] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1]!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1]?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [int() * 2]:
//              ^
// [diag.expectedToken] Expected to find ']'.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [int():
//             ^
// [diag.expectedToken] Expected to find ']'.
      break;
  }
}
''');
    var node = parseResult.findNode.switchStatement('switch').members.single;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [int() int()]:
//              ^^^
// [diag.expectedToken] Expected to find ','.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case true:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: BooleanLiteral
    literal: true
''');
  }

  test_literal_boolean_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case true as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case true) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
  operator: !
''');
  }

  test_literal_boolean_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case true?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
  operator: ?
''');
  }

  test_literal_double_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1.0:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: DoubleLiteral
    literal: 1.0
''');
  }

  test_literal_double_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1.0 as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case 1.0) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1.0!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
  operator: !
''');
  }

  test_literal_double_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1.0?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
  operator: ?
''');
  }

  test_literal_integer_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 1
''');
  }

  test_literal_integer_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1 as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case 1) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: !
''');
  }

  test_literal_integer_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: ?
''');
  }

  test_literal_null_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case null:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: NullLiteral
    literal: null
''');
  }

  test_literal_null_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case null as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case null) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case null!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: NullLiteral
      literal: null
  operator: !
''');
  }

  test_literal_null_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case null?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: NullLiteral
      literal: null
  operator: ?
''');
  }

  test_literal_string_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case "x":
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleStringLiteral
    literal: "x"
''');
  }

  test_literal_string_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case "x" as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case "x") {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case "x"!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: SimpleStringLiteral
      literal: "x"
  operator: !
''');
  }

  test_literal_string_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case "x"?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: SimpleStringLiteral
      literal: "x"
  operator: ?
''');
  }

  test_logicalAnd_insideIfCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case int? _ && double? _) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ && double? _ && Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ && double? _ || Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ || double? _ && Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case int? _ || double? _) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int? _ || double? _ || Object? _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  <String, int>{'a': a, 'b': b} = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  ({} = x);
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_map_insideAssignment_untyped_empty_beginningOfStatement() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  {} = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  ({'a': a, 'b': b} = x);
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  {'a': a, 'b': b} = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case <String, int>{'a': 1, 'b': 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_map_insideCase_untyped_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': 1, 'b': 2}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': 1} as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var <String, int>{'a': a, 'b': b} = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var {} = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_map_insideDeclaration_untyped_nonEmpty() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var {'a': a, 'b': b} = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': 1}!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': 1}?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'foo': int() * 2}:
//                     ^
// [diag.expectedToken] Expected to find '}'.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
const c = 0;

void f(Object o) {
  switch (o) {
    case {c}:
//         ^
// [diag.expectedToken] Expected to find ':'.
// [diag.missingIdentifier] Expected an identifier.
      break;
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case ({'foo': int()):
//                     ^
// [diag.expectedToken] Expected to find '}'.
      break;
  }
}
''');
    var node = parseResult.findNode.switchStatement('switch').members.single;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'foo': int() 'bar': int()}:
//                     ^^^^^
// [diag.expectedToken] Expected to find ','.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: !
''');
  }

  test_nullAssert_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y! as num:
//       ^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case var y!) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1!]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1! && 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1 && 2!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1! || 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1 || 2!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': 1!}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!!:
//       ^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y!?:
//       ^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1!):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (n: 1!, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (: var n!, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1!, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: ?
''');
  }

  test_nullCheck_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y? as num:
//       ^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case var y?) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [1?]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1? && 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1 && 2?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1? || 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1 || 2?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': 1?}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y?!:
//       ^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  const y = 1;
  switch (x) {
    case y? ?:
//       ^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1?):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (n: 1?, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (: var n?, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1?, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case dynamic():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var async() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var await() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var hide() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var of() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var on() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var show() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var sync() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var yield() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: yield
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_object_prefixed_withTypeArgs_insideAssignment() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  async.Future<int>() = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>() as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.switchPatternCase(
      "async.Future<int>() as Object",
    );
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var async.Future<int>() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>()!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>()?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _.Future():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var _.Future() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _.Future<int>():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case dynamic(foo: int() * 2):
//                          ^
// [diag.expectedToken] Expected to find ')'.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case dynamic(foo: int():
//                         ^
// [diag.expectedToken] Expected to find ')'.
      break;
  }
}
''');
    var node = parseResult.findNode.switchStatement('switch').members.single;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case dynamic(foo: int() bar: int()):
//                          ^^^
// [diag.expectedToken] Expected to find ','.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
class C<T> {}
void f(x) {
  switch (x) {
    case C<int>():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
class C<T> {}
void f(x) {
  var C<int>() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var _() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _<int>():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var _<int>() = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  (a) = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: AssignedVariablePattern
    name: a
  rightParenthesis: )
''');
  }

  test_parenthesized_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  switch (x) {
    case (1):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1) as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  var (a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    name: a
  rightParenthesis: )
''');
  }

  test_parenthesized_insideNullAssert() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1)!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1)?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => [for (var (a, b) in x) 0];
''');
    var node = parseResult.findNode.forElement('for');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => [for (@annotation var (a, b) in x) 0];
''');
    var node = parseResult.findNode.forElement('for');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  for (var (a, b) in x) {}
}
''');
    var node = parseResult.findNode.forStatement('for');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  for (@annotation var (a, b) in x) {}
}
''');
    var node = parseResult.findNode.forStatement('for');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => [for (var (a, b) = x; ;) 0];
''');
    var node = parseResult.findNode.forElement('for');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  for (var (a, b) = x; ;) {}
}
''');
    var node = parseResult.findNode.forStatement('for');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => [for ((a, b) = x; ;) 0];
''');
    var node = parseResult.findNode.forElement('for');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  for ((a, b) = x; ;) {}
}
''');
    var node = parseResult.findNode.forStatement('for');
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
    parseTestCodeWithDiagnostics('''
void main() {
  final b = (final g, final ) = 55;
//                 ^
// [diag.patternAssignmentDeclaresVariable] Variable 'g' can't be declared in a pattern assignment.
//                          ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.patternAssignmentDeclaresVariable] Variable '(unnamed)' can't be declared in a pattern assignment.
}
''');
    // No assertion on the parsed node text; all we are concerned with is that
    // the parser doesn't crash.
  }

  test_patternAssignment_inAssignmentExpression_rhs() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  v2 = (v1) = 2;
}
''');
    var node = parseResult.findNode.assignment('v2 =');
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: v2
  operator: =
  rightHandSide: PatternAssignment
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: AssignedVariablePattern
        name: v1
      rightParenthesis: )
    equals: =
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_patternAssignment_inCascadeAssignment_rhs_beforeNextCascadeSection() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  a..b = (v1) = c..m();
}
''');
    var node = parseResult.findNode.singleCascadeExpression;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
  cascadeSections
    AssignmentExpression
      leftHandSide: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: b
      operator: =
      rightHandSide: PatternAssignment
        pattern: ParenthesizedPattern
          leftParenthesis: (
          pattern: AssignedVariablePattern
            name: v1
          rightParenthesis: )
        equals: =
        expression: SimpleIdentifier
          token: c
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: m
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
''');
  }

  test_patternAssignment_inConditionalExpression_then() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  v2 ? (v1) = 2 : 3;
}
''');
    var node = parseResult.findNode.singleConditionalExpression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: v2
  question: ?
  thenExpression: PatternAssignment
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: AssignedVariablePattern
        name: v1
      rightParenthesis: )
    equals: =
    expression: IntegerLiteral
      literal: 2
  colon: :
  elseExpression: IntegerLiteral
    literal: 3
''');
  }

  test_patternAssignment_withCascadeExpression_rhs() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  (v1) = a..m();
}
''');
    var node = parseResult.findNode.singlePatternAssignment;
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: v1
    rightParenthesis: )
  equals: =
  expression: CascadeExpression
    target: SimpleIdentifier
      token: a
    cascadeSections
      MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: m
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
''');
  }

  test_patternAssignment_withPatternAssignment_rhs_parenthesized() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  (v2) = ((v1)) = 3;
}
''');
    var node = parseResult.findNode.patternAssignment('(v2) =');
    assertParsedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: v2
    rightParenthesis: )
  equals: =
  expression: PatternAssignment
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: ParenthesizedPattern
        leftParenthesis: (
        pattern: AssignedVariablePattern
          name: v1
        rightParenthesis: )
      rightParenthesis: )
    equals: =
    expression: IntegerLiteral
      literal: 3
''');
  }

  test_patternVariableDeclaration_inClass() {
    // If a pattern variable declaration appears outside a function or method,
    // the parser recovers by replacing the pattern with a synthetic identifier,
    // so that it parses as an ordinary field or top level variable declaration.
    var parseResult = parseTestCodeWithDiagnostics('''
class C {
  var (a, b) = (0, 1);
//    ^^^^^^
// [diag.patternVariableDeclarationOutsideFunctionOrMethod] A pattern variable declaration may not appear outside a function or method.
}
''');
    var node = parseResult.findNode.classDeclaration('class');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
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
    var parseResult = parseTestCodeWithDiagnostics('''
var (a, b) = (0, 1);
//  ^^^^^^
// [diag.patternVariableDeclarationOutsideFunctionOrMethod] A pattern variable declaration may not appear outside a function or method.
''');
    var node = parseResult.findNode.unit;
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
    parseTestCodeWithDiagnostics('''
f(x) {
  const (_) = x;
//^^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
//        ^
// [diag.recordLiteralOnePositionalNoTrailingComma] A record literal with exactly one positional field requires a trailing comma.
}
''');
  }

  test_patternVariableDeclarationStatement_disallowsLate() {
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  late var (_) = x;
//^^^^
// [diag.latePatternVariableDeclaration] A pattern variable declaration may not use the `late` keyword.
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  final C(f: a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  final [a] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  final {'a': a} = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  final (a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  final (a,) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  var C(f: a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  var [a] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  var {'a': a} = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  var (a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  var (a,) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  final C(f: a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  final [a] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  final {'a': a} = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  final (a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  final (a,) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  var C(f: a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  var [a] = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  var {'a': a} = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  var (a) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) {
  @annotation
  var (a,) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclarationStatement('= x');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case Enum.value when !flag:
  }
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  () = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_record_insideAssignment_oneField() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  (a,) = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  (a, b) = x;
}
''');
    var node = parseResult.findNode.patternAssignment('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_record_insideCase_oneField() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1,):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1, 2) as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var () = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_record_insideDeclaration_oneField() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var (a,) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var (a, b) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1, 2)!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (1, 2)?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (_,) as (Object,):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (_,) when true:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (_,)? as (Object,):
//       ^^^^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (_,)? when true:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) y && _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) y as (Object,):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) y:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,) y, _]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) y!:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) y || _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) y?:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => switch (x) { (int,) y => 0 };
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {0: (int,) y}:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,) y]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case ((int,) y):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) y when true:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? y && _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? y as (Object,):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? y:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,)? y, _]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? y!:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? y || _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? y?:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => switch (x) { (int,)? y => 0 };
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {0: (int,)? y}:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,)? y]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case ((int,)? y):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? y when true:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) _ && _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) _ as (Object,):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,) _, _]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) _!:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) _ || _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) _?:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => switch (x) { (int,) _ => 0 };
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {0: (int,) _}:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,) _]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case ((int,) _):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,) _ when true:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? _ && _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? _ as (Object,):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,)? _, _]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? _!:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? _ || _:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? _?:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) => switch (x) { (int,)? _ => 0 };
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {0: (int,)? _}:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [(int,)? _]:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case ((int,)? _):
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int,)? _ when true:
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case == 1 | 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case > 1 | 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case == 1 > 0:
//            ^
// [diag.expectedToken] Expected to find ':'.
// [diag.missingIdentifier] Expected an identifier.
//              ^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ':'.
      break;
  }
}
''');
    // We don't care what the parsed AST is, just that there are errors.
  }

  test_relational_containingRelationalExpression_relational() {
    // The patterns grammar doesn't allow a relational expression inside a
    // relational pattern (even though technically it would be unambiguous).
    // TODO(paulberry): try to improve parser error recovery in this scenario.
    parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case > 1 > 0:
//           ^
// [diag.expectedToken] Expected to find ':'.
// [diag.missingIdentifier] Expected an identifier.
//             ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ':'.
      break;
  }
}
''');
    // We don't care what the parsed AST is, just that there are errors.
  }

  test_relational_insideCase_equal() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case == 1 << 1:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case > 1 << 1:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case >= 1 << 1:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case < 1 << 1:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case <= 1 << 1:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case != 1 << 1:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case == 1) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [== 1]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case == 1 && 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1 && == 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case == 1 || 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case 1 || == 2:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {'a': == 1}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case == 1?:
//       ^^^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case > 1?:
//       ^^^
// [diag.invalidInsideUnaryPattern] This pattern cannot appear inside a unary pattern (cast pattern, null check pattern, or null assert pattern) without parentheses.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
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
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (== 1):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (n: == 1, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (== 1, 2):
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    parseTestCodeWithDiagnostics('''
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [...]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {...}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case [...var y]:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case {...var y}:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    parseTestCodeWithDiagnostics('''
main() {
  int var = 0;
//^^^
// [diag.expectedToken] Expected to find ';'.
//        ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken][column 15][length 1] Expected to find '}'.
''');
  }

  test_switchExpression_empty() {
    // Even though an empty switch expression is illegal (because it's not
    // exhaustive), it should be accepted by the parser to enable analyzer code
    // completions.
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {
  _ when true => 0
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {
  _ => 0
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {
  _ => 0,
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {
  int() => 0 : 1
//           ^
// [diag.expectedToken] Expected to find '}'.
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => [switch(x) {
  int() => 0 : 1
//           ^
// [diag.expectedToken] Expected to find '}'.
}, 0];
''');
    var node = parseResult.findNode.listLiteral('[');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {
  int() => 0 : (1, 2)
//           ^
// [diag.expectedToken] Expected to find '}'.
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
  case 1 => 'one',
//^^^^
// [diag.unexpectedToken] Unexpected text 'case'.
  case 2 => 'two'
//^^^^
// [diag.unexpectedToken] Unexpected text 'case'.
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
  1: 'one',
// ^
// [diag.expectedToken] Expected to find '=>'.
  2: 'two'
// ^
// [diag.expectedToken] Expected to find '=>'.
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
  1 => 'one',
  default => 'other'
//^^^^^^^
// [diag.defaultInSwitchExpression] A switch expression may not use the `default` keyword.
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
  _ when () => true => 1,
//                  ^^
// [diag.expectedToken] Expected to find ','.
  _ => 2
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
  _ when () => true => 1;
//                  ^^
// [diag.expectedToken] Expected to find ','.
  _ => 2
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {
  int() => 0
  double() => 1
//^^^^^^
// [diag.expectedToken] Expected to find ','.
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
  1 => 'one';
//          ^
// [diag.expectedToken] Expected to find ','.
  2 => 'two'
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    parseTestCodeWithDiagnostics('''
f(x) => switch (x) {
    1 => 2
    > 1 => 1
//      ^^
// [diag.expectedToken] Expected to find '}'.
    < 1 => 0
};
''');
    // No assertion on the parsed node text; all we are concerned with is that
    // the parser doesn't crash.
  }

  test_switchExpression_twoPatterns() {
    var parseResult = parseTestCodeWithDiagnostics('''
f(x) => switch(x) {
  int _ => 0,
  _ => 1
};
''');
    var node = parseResult.findNode.switchExpression('switch');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(Object? x) {
  switch (x) {
    case [if]:
//        ^^
// [diag.missingIdentifier] Expected an identifier.
  };
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(Object? x) {
  switch (x) {
    case {0: if}:
//           ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ','.
// [diag.expectedToken] Expected to find ':'.
  };
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(Object? x) {
  switch (x) {
    case (if):
//        ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
  };
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(Object? x) {
  switch (x) {
    case (_, if):
//           ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
  };
}
''');
    var node = parseResult.findNode.switchPatternCase('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(Object? x) => switch (x) {if};
//                               ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '=>'.
// [diag.expectedToken] Expected to find '}'.
''');
    var node = parseResult.findNode.switchExpression('if');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(condition, when, otherwise) => condition as bool ? when : otherwise;
''');
    var node = parseResult.findNode
        .functionDeclaration('=>')
        .functionExpression
        .body;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _ as int? when x == null:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var (y as Object) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var (final y) = x;
//     ^^^^^
// [diag.variablePatternKeywordInDeclarationContext] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case final y) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final y!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: y
  operator: !
''');
  }

  test_variable_final_untyped_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final y?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: y
  operator: ?
''');
  }

  test_variable_namedAs() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var as:
//           ^^
// [diag.illegalPatternVariableName] The variable declared by a variable pattern can't be named 'as'.
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: as
''');
  }

  test_variable_namedWhen() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var when:
//           ^^^^
// [diag.illegalPatternVariableName] The variable declared by a variable pattern can't be named 'when'.
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: when
''');
  }

  test_variable_type_record_empty_inDeclarationContext() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var (() y) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('var').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case () y:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, '''
DeclaredVariablePattern
  type: RecordTypeAnnotation
    leftParenthesis: (
    rightParenthesis: )
  name: y
''');
  }

  test_variable_type_record_nonEmpty_inDeclarationContext() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var ((int, String) y) = x;
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('var').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case (int, String) y:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int y:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: int
  name: y
''');
  }

  test_variable_typed_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int y as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case int y) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int y!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int y?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _ y:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: _
  name: y
''');
  }

  test_variable_var_inDeclarationContext() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var (var y) = x;
//     ^^^
// [diag.variablePatternKeywordInDeclarationContext] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var y:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
''');
  }

  test_variable_var_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var y as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case var y) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var y!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
  operator: !
''');
  }

  test_variable_var_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var y?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
  operator: ?
''');
  }

  test_varKeywordInTypedVariablePattern_declarationContext() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(int x) {
  var (var int y) = x;
//     ^^^
// [diag.variablePatternKeywordInDeclarationContext] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  var (var int _) = x;
//     ^^^
// [diag.variablePatternKeywordInDeclarationContext] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
}
''');
    var node = parseResult.findNode.patternVariableDeclaration('= x').pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var int y:
//       ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var int _:
//       ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _ when true:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  name: _
''');
  }

  test_wildcard_bare_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _ as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case _) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
''');
  }

  test_wildcard_bare_insideNullAssert() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    name: _
  operator: !
''');
  }

  test_wildcard_bare_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case _?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    name: _
  operator: ?
''');
  }

  test_wildcard_final_typed_insideCase() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final int _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  keyword: final
  type: NamedType
    name: int
  name: _
''');
  }

  test_wildcard_final_typed_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final int _ as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case final int _) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final int _!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final int _?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  keyword: final
  name: _
''');
  }

  test_wildcard_final_untyped_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final _ as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case final _) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final _!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    keyword: final
    name: _
  operator: !
''');
  }

  test_wildcard_final_untyped_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case final _?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    keyword: final
    name: _
  operator: ?
''');
  }

  test_wildcard_inPatternAssignment_bareIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, _] = y;
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, final _] = y;
//          ^
// [diag.patternAssignmentDeclaresVariable] Variable '_' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, final int _] = y;
//              ^
// [diag.patternAssignmentDeclaresVariable] Variable '_' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, int _] = y;
//        ^
// [diag.patternAssignmentDeclaresVariable] Variable '_' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, var _] = y;
//        ^
// [diag.patternAssignmentDeclaresVariable] Variable '_' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  [a, var int _] = y;
//            ^
// [diag.patternAssignmentDeclaresVariable] Variable '_' can't be declared in a pattern assignment.
}
''');
    var node = parseResult.findNode.patternAssignment('=');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  type: NamedType
    name: int
  name: _
''');
  }

  test_wildcard_typed_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int _ as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case int _) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int _!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case int _?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var _:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
WildcardPattern
  keyword: var
  name: _
''');
  }

  test_wildcard_var_insideCast() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var _ as Object:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  if (x case var _) {}
}
''');
    var node = parseResult.findNode.caseClause('case');
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
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var _!:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullAssertPattern
  pattern: WildcardPattern
    keyword: var
    name: _
  operator: !
''');
  }

  test_wildcard_var_insideNullCheck() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f(x) {
  switch (x) {
    case var _?:
      break;
  }
}
''');
    var node = parseResult.findNode.singleGuardedPattern.pattern;
    assertParsedNodeText(node, r'''
NullCheckPattern
  pattern: WildcardPattern
    keyword: var
    name: _
  operator: ?
''');
  }
}
