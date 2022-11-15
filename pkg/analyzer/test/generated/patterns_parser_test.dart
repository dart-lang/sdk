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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
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
  pattern: CastPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: int
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
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
  condition: SimpleIdentifier
    token: x
  caseClause: CaseClause
    caseKeyword: case
    pattern: CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
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
  pattern: CastPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
''');
  }

  test_cast_insideExtractor_explicitlyNamed() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: C
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: f
        colon: :
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
  rightParenthesis: )
''');
  }

  test_cast_insideExtractor_implicitlyNamed() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: C
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: CastPattern
        pattern: VariablePattern
          keyword: var
          name: f
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
  rightParenthesis: )
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
  pattern: CastPattern
    pattern: VariablePattern
      keyword: var
      name: y
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
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
        name: SimpleIdentifier
          token: int
  rightBracket: ]
''');
  }

  test_cast_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ as double? & Object? _:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: double
      question: ?
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
      question: ?
    name: _
''');
  }

  test_cast_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ & double? _ as Object?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
      question: ?
    name: _
  operator: &
  rightOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: Object
      question: ?
''');
  }

  test_cast_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ as double? | Object? _:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: double
      question: ?
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
      question: ?
    name: _
''');
  }

  test_cast_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ | double? _ as Object?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
      question: ?
    name: _
  operator: |
  rightOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  entries
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
          name: SimpleIdentifier
            token: int
  rightBracket: }
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: CastPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: n
        colon: :
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
    RecordPatternField
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: CastPattern
        pattern: VariablePattern
          keyword: var
          name: n
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
    RecordPatternField
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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

  test_constant_identifier_prefixed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case a.b:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
      period: .
      identifier: SimpleIdentifier
        token: b
  operator: ?
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: ?
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
      leftBracket: [
      rightBracket: ]
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: ListLiteral
      leftBracket: [
      rightBracket: ]
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
    leftBracket: {
    elements
      SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
      leftBracket: {
      elements
        SetOrMapLiteral
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
      leftBracket: {
      elements
        SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
      leftBracket: {
      elements
        SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
      leftBracket: {
      elements
        SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    leftBracket: {
    elements
      SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        SetOrMapLiteral
          key: IntegerLiteral
            literal: 1
          separator: :
          value: IntegerLiteral
            literal: 2
      rightBracket: }
      isMap: false
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      leftBracket: {
      elements
        SetOrMapLiteral
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
      leftBracket: {
      elements
        IntegerLiteral
          literal: 1
      rightBracket: }
      isMap: false
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    const: const
    expression: SetOrMapLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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

  test_extractor_prefixed_withTypeArgs_insideCase() {
    _parse('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>():
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: async
      period: .
      identifier: SimpleIdentifier
        token: Future
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_extractor_prefixed_withTypeArgs_insideCast() {
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
  pattern: CastPattern
    pattern: ExtractorPattern
      type: NamedType
        name: PrefixedIdentifier
          prefix: SimpleIdentifier
            token: async
          period: .
          identifier: SimpleIdentifier
            token: Future
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: SimpleIdentifier
                token: int
          rightBracket: >
      leftParenthesis: (
      rightParenthesis: )
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: Object
  colon: :
  statements
    BreakStatement
      breakKeyword: break
      semicolon: ;
''');
  }

  test_extractor_prefixed_withTypeArgs_insideNullAssert() {
    _parse('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>()!:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: async
        period: .
        identifier: SimpleIdentifier
          token: Future
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: !
''');
  }

  test_extractor_prefixed_withTypeArgs_insideNullCheck() {
    _parse('''
import 'dart:async' as async;

void f(x) {
  switch (x) {
    case async.Future<int>()?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: async
        period: .
        identifier: SimpleIdentifier
          token: Future
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: ?
''');
  }

  test_extractor_prefixedNamedUnderscore_withoutTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _.Future():
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: _
      period: .
      identifier: SimpleIdentifier
        token: Future
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_extractor_prefixedNamedUnderscore_withTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _.Future<int>():
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: _
      period: .
      identifier: SimpleIdentifier
        token: Future
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_extractor_unprefixed_withoutTypeArgs_insideCast() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
''');
  }

  test_extractor_unprefixed_withoutTypeArgs_insideNullAssert() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  operator: !
''');
  }

  test_extractor_unprefixed_withoutTypeArgs_insideNullCheck() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  operator: ?
''');
  }

  test_extractor_unprefixed_withTypeArgs_insideCase() {
    _parse('''
class C<T> {}
void f(x) {
  switch (x) {
    case C<int>():
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_extractor_unprefixed_withTypeArgs_insideNullAssert() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 1
    rightParenthesis: )
  operator: !
''');
  }

  test_extractor_unprefixedNamedUnderscore_withoutTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _():
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: _
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_extractor_unprefixedNamedUnderscore_withTypeArgs_insideCase() {
    // We need to make sure the `_` isn't misinterpreted as a wildcard pattern
    _parse('''
void f(x) {
  switch (x) {
    case _<int>():
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: _
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ListPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ListPattern
    leftBracket: [
    elements
      ConstantPattern
        expression: IntegerLiteral
          literal: 1
    rightBracket: ]
  operator: ?
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: NullLiteral
      literal: null
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleStringLiteral
      literal: "x"
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleStringLiteral
      literal: "x"
  operator: ?
''');
  }

  test_logicalAnd_insideIfCase() {
    _parse('''
void f(x) {
  if (x case int? _ & double? _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  pattern: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
        question: ?
      name: _
    operator: &
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
''');
  }

  test_logicalAnd_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ & double? _ & Object? _:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
        question: ?
      name: _
    operator: &
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
      question: ?
    name: _
''');
  }

  test_logicalAnd_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ & double? _ | Object? _:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
        question: ?
      name: _
    operator: &
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
      question: ?
    name: _
''');
  }

  test_logicalAnd_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ | double? _ & Object? _:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
      question: ?
    name: _
  operator: |
  rightOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
    operator: &
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: Object
        question: ?
      name: _
''');
  }

  test_logicalOr_insideIfCase() {
    _parse('''
void f(x) {
  if (x case int? _ | double? _) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  pattern: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
        question: ?
      name: _
    operator: |
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
''');
  }

  test_logicalOr_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int? _ | double? _ | Object? _:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
        question: ?
      name: _
    operator: |
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
        question: ?
      name: _
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
      question: ?
    name: _
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: String
      NamedType
        name: SimpleIdentifier
          token: int
    rightBracket: >
  leftBracket: {
  entries
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  entries
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: MapPattern
    leftBracket: {
    entries
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: MapPattern
    leftBracket: {
    entries
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: MapPattern
    leftBracket: {
    entries
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: !
''');
  }

  test_nullAssert_insideExtractor_explicitlyNamed() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
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
            literal: 1
        operator: !
  rightParenthesis: )
''');
  }

  test_nullAssert_insideExtractor_implicitlyNamed() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
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
  pattern: PostfixPattern
    operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    PostfixPattern
      operand: ConstantPattern
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
    case 1! & 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullAssert_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 & 2!:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullAssert_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1! | 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullAssert_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 | 2!:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullAssert_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1!}:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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
            literal: 1
        operator: !
  rightBracket: }
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: PostfixPattern
    operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullAssert_insideRecord_implicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (: var n!, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullAssert_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (1!, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleIdentifier
      token: y
  operator: ?
''');
  }

  test_nullCheck_insideExtractor_explicitlyNamed() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
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
            literal: 1
        operator: ?
  rightParenthesis: )
''');
  }

  test_nullCheck_insideExtractor_implicitlyNamed() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
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
  pattern: PostfixPattern
    operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    PostfixPattern
      operand: ConstantPattern
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
    case 1? & 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullCheck_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 & 2?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullCheck_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1? | 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullCheck_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 | 2?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullCheck_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': 1?}:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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
            literal: 1
        operator: ?
  rightBracket: }
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: PostfixPattern
    operand: ConstantPattern
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
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullCheck_insideRecord_implicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (: var n?, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_nullCheck_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (1?, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_parenthesized_insideCase() {
    _parse('''
f(x) {
  switch (x) {
    case (1):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    name: SimpleIdentifier
      token: Object
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ParenthesizedPattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ParenthesizedPattern
    leftParenthesis: (
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 1
    rightParenthesis: )
  operator: ?
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
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
    var node = findNode.switchPatternCase('case').pattern;
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

  test_record_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case (1, 2) as Object:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_record_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case (1, 2)!:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_record_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case (1, 2)?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_relational_insideCase_equal() {
    _parse('''
void f(x) {
  switch (x) {
    case == 1 << 1:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
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

  test_relational_insideExtractor_explicitlyNamed() {
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
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
          literal: 1
  rightParenthesis: )
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
    var node = findNode.switchPatternCase('case').pattern;
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
    case == 1 & 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_relational_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 & == 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_relational_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case == 1 | 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_relational_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 | == 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_relational_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': == 1}:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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
          literal: 1
  rightBracket: }
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
    var node = findNode.switchPatternCase('case').pattern;
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: n
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

  test_relational_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (== 1, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
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

  test_variable_final_typed_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case final int y:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
  keyword: final
  type: NamedType
    name: SimpleIdentifier
      token: int
  name: y
''');
  }

  test_variable_final_typed_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case final int y as Object:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
''');
  }

  test_variable_final_typed_insideIfCase() {
    _parse('''
void f(x) {
  if (x case final int y) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  pattern: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: y
''');
  }

  test_variable_final_typed_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case final int y!:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: y
  operator: !
''');
  }

  test_variable_final_typed_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case final int y?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: y
  operator: ?
''');
  }

  test_variable_final_untyped_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case final y:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
  keyword: final
  name: y
''');
  }

  test_variable_final_untyped_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case final y as Object:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: final
    name: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: final
    name: y
  operator: ?
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: y
  operator: ?
''');
  }

  test_variable_typedNamedAs_insideCase() {
    _parse('''
void f(x) {
  switch (x) {
    case int as:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: int
  name: as
''');
  }

  test_variable_typedNamedAs_insideCast() {
    _parse('''
void f(x) {
  switch (x) {
    case int as as Object:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
''');
  }

  test_variable_typedNamedAs_insideExtractor_explicitlyNamed() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(f: int as):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: C
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: f
        colon: :
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
        name: as
  rightParenthesis: )
''');
  }

  test_variable_typedNamedAs_insideExtractor_implicitlyNamed() {
    _parse('''
class C {
  int? f;
}
void f(x) {
  switch (x) {
    case C(: int as):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: C
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
        name: as
  rightParenthesis: )
''');
  }

  test_variable_typedNamedAs_insideIfCase() {
    _parse('''
void f(x) {
  if (x case int as) {}
}
''');
    var node = findNode.caseClause('case');
    assertParsedNodeText(node, r'''
CaseClause
  caseKeyword: case
  pattern: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
''');
  }

  test_variable_typedNamedAs_insideList() {
    _parse('''
void f(x) {
  switch (x) {
    case [int as]:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
      name: as
  rightBracket: ]
''');
  }

  test_variable_typedNamedAs_insideLogicalAnd_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int as & 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
  operator: &
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_variable_typedNamedAs_insideLogicalAnd_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 & int as:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
''');
  }

  test_variable_typedNamedAs_insideLogicalOr_lhs() {
    _parse('''
void f(x) {
  switch (x) {
    case int as | 2:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
  operator: |
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
''');
  }

  test_variable_typedNamedAs_insideLogicalOr_rhs() {
    _parse('''
void f(x) {
  switch (x) {
    case 1 | int as:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
''');
  }

  test_variable_typedNamedAs_insideMap() {
    _parse('''
void f(x) {
  switch (x) {
    case {'a': int as}:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  entries
    MapPatternEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
        name: as
  rightBracket: }
''');
  }

  test_variable_typedNamedAs_insideNullAssert() {
    _parse('''
void f(x) {
  switch (x) {
    case int as!:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
  operator: !
''');
  }

  test_variable_typedNamedAs_insideNullCheck() {
    _parse('''
void f(x) {
  switch (x) {
    case int as?:
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
  operator: ?
''');
  }

  test_variable_typedNamedAs_insideParenthesized() {
    _parse('''
void f(x) {
  switch (x) {
    case (int as):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: as
  rightParenthesis: )
''');
  }

  test_variable_typedNamedAs_insideRecord_explicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (n: int as, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: n
        colon: :
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
        name: as
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_variable_typedNamedAs_insideRecord_implicitlyNamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (: int as, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
        name: as
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
''');
  }

  test_variable_typedNamedAs_insideRecord_unnamed() {
    _parse('''
void f(x) {
  switch (x) {
    case (int as, 2):
      break;
  }
}
''');
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
        name: as
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 2
  rightParenthesis: )
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: _
  name: y
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: var
    name: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: var
    name: y
  operator: ?
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    name: _
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
  keyword: final
  type: NamedType
    name: SimpleIdentifier
      token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: _
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: final
    name: _
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    keyword: final
    name: _
  operator: ?
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
    name: _
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: var
    name: _
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
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
  pattern: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
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
    var node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: VariablePattern
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
