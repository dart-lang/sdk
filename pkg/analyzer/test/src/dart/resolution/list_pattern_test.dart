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
  test_elements_constant() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [0]:
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
        literal: 0
  rightBracket: ]
''');
  }

  test_elements_empty() async {
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
