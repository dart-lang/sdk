// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapPatternResolutionTest);
  });
}

@reflectiveTest
class MapPatternResolutionTest extends PatternsResolutionTest {
  test_empty() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {}:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_empty_withWhitespace() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case { }:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
''');
  }

  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {'a': 0} as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
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
            literal: 0
    rightBracket: }
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
    case {'a': 0}!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
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
            literal: 0
    rightBracket: }
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {'a': 0}?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
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
            literal: 0
    rightBracket: }
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {'a': 1, 'b': 2}:
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

  test_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case <String, int>{'a': 1, 'b': 2}:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
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
}
