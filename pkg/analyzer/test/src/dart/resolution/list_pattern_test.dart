// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListPatternResolutionTest);
  });
}

@reflectiveTest
class ListPatternResolutionTest extends PatternsResolutionTest {
  test_empty() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_empty_withWhitespace() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [ ]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
''');
  }

  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [0] as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ListPattern
    leftBracket: [
    elements
      ConstantPattern
        expression: IntegerLiteral
          literal: 0
    rightBracket: ]
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case [0]) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertParsedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
  rightBracket: ]
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [0]!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ListPattern
    leftBracket: [
    elements
      ConstantPattern
        expression: IntegerLiteral
          literal: 0
    rightBracket: ]
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [0]?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ListPattern
    leftBracket: [
    elements
      ConstantPattern
        expression: IntegerLiteral
          literal: 0
    rightBracket: ]
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [1, 2]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
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

  test_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case <int>[1, 2]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
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
}
