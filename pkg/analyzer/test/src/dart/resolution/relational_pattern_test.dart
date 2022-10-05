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

  test_greaterThan() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case > 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: IntegerLiteral
    literal: 0
''');
  }

  test_greaterThanOrEqualTo() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case >= 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: IntegerLiteral
    literal: 0
''');
  }

  test_ifCase() async {
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

  test_lessThan() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case < 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: IntegerLiteral
    literal: 0
''');
  }

  test_lessThanOrEqualTo() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case <= 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: IntegerLiteral
    literal: 0
''');
  }

  test_notEqual() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case != 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
RelationalPattern
  operator: !=
  operand: IntegerLiteral
    literal: 0
''');
  }

  test_switchCase() async {
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
}
