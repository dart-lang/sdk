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
}
