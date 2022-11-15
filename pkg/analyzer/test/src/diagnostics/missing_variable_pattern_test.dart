// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingVariablePatternTest);
  });
}

@reflectiveTest
class MissingVariablePatternTest extends PatternsResolutionTest {
  test_ifCase_differentStatements_nested() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case final a) {
    if (x case final b) {}
  }
}
''');

    final node1 = findNode.caseClause('case final a').pattern;
    assertResolvedNodeText(node1, r'''
VariablePattern
  keyword: final
  name: a
  declaredElement: hasImplicitType isFinal a@35
    type: int
''');

    final node2 = findNode.caseClause('case final b').pattern;
    assertResolvedNodeText(node2, r'''
VariablePattern
  keyword: final
  name: b
  declaredElement: hasImplicitType isFinal b@61
    type: int
''');
  }

  test_ifCase_differentStatements_sibling() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case final a) {}
  if (x case final b) {}
}
''');

    final node1 = findNode.caseClause('case final a').pattern;
    assertResolvedNodeText(node1, r'''
VariablePattern
  keyword: final
  name: a
  declaredElement: hasImplicitType isFinal a@35
    type: int
''');

    final node2 = findNode.caseClause('case final b').pattern;
    assertResolvedNodeText(node2, r'''
VariablePattern
  keyword: final
  name: b
  declaredElement: hasImplicitType isFinal b@60
    type: int
''');
  }

  test_ifCase_logicalOr2_both_direct() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case final a | final a) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@35
      type: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: a@35
''');
  }

  test_ifCase_logicalOr2_both_nested_logicalAnd() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case 0 & final a | final a) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
    operator: &
    rightOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@39
        type: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: a@39
''');
  }

  test_ifCase_logicalOr2_left() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case final a | 2) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 39, 1),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@35
      type: int
  operator: |
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
      staticType: int
''');
  }

  test_ifCase_logicalOr2_right() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case 1 | final a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
      staticType: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@39
      type: int
''');
  }

  test_ifCase_logicalOr3_1() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case final a | 2 | 3) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 39, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 43, 1),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@35
        type: int
    operator: |
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
  operator: |
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
''');
  }

  test_ifCase_logicalOr3_12() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case final a | final a | 3) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 49, 1),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@35
        type: int
    operator: |
    rightOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: a@35
  operator: |
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
''');
  }

  test_ifCase_logicalOr3_123() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case final a | final a | final a) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@35
        type: int
    operator: |
    rightOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: a@35
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: a@35
''');
  }

  test_ifCase_logicalOr3_13() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case final a | 2 | final a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 39, 1),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@35
        type: int
    operator: |
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: a@35
''');
  }

  test_ifCase_logicalOr3_2() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case 1 | final a | 3) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 43, 1),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
    operator: |
    rightOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@39
        type: int
  operator: |
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
''');
  }

  test_ifCase_logicalOr3_23() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case 1 | final a | final a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
    operator: |
    rightOperand: VariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@39
        type: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: a@39
''');
  }

  test_ifCase_logicalOr3_3() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case 1 | 2 | final a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 5),
    ]);
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
    operator: |
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@43
      type: int
''');
  }

  test_switchStatement_case1_logicalOr2_both() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final a | final a:
      return;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@46
      type: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: a@46
''');
  }

  test_switchStatement_case1_logicalOr2_left() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final a | 2:
      return;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 50, 1),
    ]);
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@46
      type: int
  operator: |
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
      staticType: int
''');
  }

  test_switchStatement_case1_logicalOr2_right() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case 1 | final a:
      return;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 40, 1),
    ]);
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
      staticType: int
  operator: |
  rightOperand: VariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@50
      type: int
''');
  }

  test_switchStatement_case2_both() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case /*1*/ final a:
    case /*2*/ final a:
      return;
  }
}
''');

    final node1 = findNode.switchPatternCase('case /*1*/').pattern;
    assertResolvedNodeText(node1, r'''
VariablePattern
  keyword: final
  name: a
  declaredElement: hasImplicitType isFinal a@52
    type: int
''');

    final node2 = findNode.switchPatternCase('case /*2*/').pattern;
    assertResolvedNodeText(node2, r'''
VariablePattern
  keyword: final
  name: a
  declaredElement: a@52
''');
  }

  test_switchStatement_case2_left() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final a:
    case 2:
      return;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 58, 1),
    ]);
  }

  test_switchStatement_case2_right() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case 1:
    case final a:
      return;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 40, 1),
    ]);
  }

  test_switchStatement_differentCases_nested() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final a:
      switch (x) {
        case 2:
          return;
      }
      return;
  }
}
''');
  }

  test_switchStatement_differentCases_sibling() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final a:
      return;
    case 2:
      return;
  }
}
''');
  }
}
