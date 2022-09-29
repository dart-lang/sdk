// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternResolutionTest);
  });
}

@reflectiveTest
class CastPatternResolutionTest extends PatternsResolutionTest {
  test_inside_extractorPattern_explicitName() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(f: 0 as int):
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
      pattern: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
  rightParenthesis: )
''');
  }

  test_inside_extractorPattern_implicitName() async {
    await assertNoErrorsInCode(r'''
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

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case var y as int) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: VariablePattern
    keyword: var
    name: y
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
''');
  }

  test_inside_listPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [0 as int]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    CastPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
  rightBracket: ]
''');
  }

  test_inside_logicalAnd_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ as double? & Object? _:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        question: ?
        type: int?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      question: ?
      type: double?
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
        staticElement: dart:core::@class::Object
        staticType: null
      question: ?
      type: Object?
    name: _
''');
  }

  test_inside_logicalAnd_right() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ & double? _ as Object?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      question: ?
      type: int?
    name: _
  operator: &
  rightOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        question: ?
        type: double?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: Object
        staticElement: dart:core::@class::Object
        staticType: null
      question: ?
      type: Object?
''');
  }

  test_inside_logicalOr_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ as double? | Object? _:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        question: ?
        type: int?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      question: ?
      type: double?
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
        staticElement: dart:core::@class::Object
        staticType: null
      question: ?
      type: Object?
    name: _
''');
  }

  test_inside_logicalOr_right() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ | double? _ as Object?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      question: ?
      type: int?
    name: _
  operator: |
  rightOperand: CastPattern
    pattern: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        question: ?
        type: double?
      name: _
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: Object
        staticElement: dart:core::@class::Object
        staticType: null
      question: ?
      type: Object?
''');
  }

  test_inside_mapPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {'a': 0 as int}:
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
      value: CastPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
  rightBracket: }
''');
  }

  test_inside_parenthesizedPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (0 as int):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: CastPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
    asToken: as
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
  rightParenthesis: )
''');
  }

  test_inside_recordPattern_namedExplicitly() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (n: 1 as int, 2):
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

  test_inside_recordPattern_namedImplicitly() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (: var n as int, 2):
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

  test_inside_recordPattern_unnamed() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (1 as int, 2):
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

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x, y) {
  switch (x) {
    case y as int:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
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
}
