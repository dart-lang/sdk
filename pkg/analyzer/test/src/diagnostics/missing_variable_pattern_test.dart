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
class MissingVariablePatternTest extends PubPackageResolutionTest {
  test_ifCase_differentStatements_nested() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case final a) {
    if (x case final b) {}
  }
}
''');

    final node1 = findNode.caseClause('case final a').guardedPattern;
    assertResolvedNodeText(node1, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@35
      type: int
''');

    final node2 = findNode.caseClause('case final b').guardedPattern;
    assertResolvedNodeText(node2, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
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

    final node1 = findNode.caseClause('case final a').guardedPattern;
    assertResolvedNodeText(node1, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@35
      type: int
''');

    final node2 = findNode.caseClause('case final b').guardedPattern;
    assertResolvedNodeText(node2, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: b
    declaredElement: hasImplicitType isFinal b@60
      type: int
''');
  }

  test_ifCase_logicalOr2_both_direct() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case final a || final a) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@35
      type: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@46
      type: int
''');
  }

  test_ifCase_logicalOr2_both_nested_logicalAnd() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case 0 && final a || final a) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
    operator: &&
    rightOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@40
        type: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@51
      type: int
''');
  }

  test_ifCase_logicalOr2_left() async {
    await assertErrorsInCode(r'''
void f(num x) {
  if (x case final int a || 2) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 44, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: a
    declaredElement: isFinal a@39
      type: int
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
      staticType: int
''');
  }

  test_ifCase_logicalOr2_right() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case 1 || final a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
      staticType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@40
      type: int
''');
  }

  test_ifCase_logicalOr3_1() async {
    await assertErrorsInCode(r'''
void f(num x) {
  if (x case final int a || 2 || 3) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 44, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 49, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: isFinal a@39
        type: int
    operator: ||
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
''');
  }

  test_ifCase_logicalOr3_12() async {
    await assertErrorsInCode(r'''
void f(num x) {
  if (x case final int a || final int a || 3) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 59, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: isFinal a@39
        type: int
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: isFinal a@54
        type: int
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
''');
  }

  test_ifCase_logicalOr3_123() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  if (x case final a || final a || final a) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@35
        type: int
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@46
        type: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@57
      type: int
''');
  }

  test_ifCase_logicalOr3_13() async {
    await assertErrorsInCode(r'''
void f(num x) {
  if (x case final int a || 2 || final int a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 44, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: isFinal a@39
        type: int
    operator: ||
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: a
    declaredElement: isFinal a@59
      type: int
''');
  }

  test_ifCase_logicalOr3_2() async {
    await assertErrorsInCode(r'''
void f(num x) {
  if (x case 1 || final int a || 3) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 49, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: isFinal a@44
        type: int
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
''');
  }

  test_ifCase_logicalOr3_23() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case 1 || final a || final a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredElement: hasImplicitType isFinal a@40
        type: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@51
      type: int
''');
  }

  test_ifCase_logicalOr3_3() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case 1 || 2 || final a) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 6),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
    operator: ||
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@45
      type: int
''');
  }

  test_switchStatement_case1_logicalOr2_both() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final a || final a:
      return;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@46
      type: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@57
      type: int
''');
  }

  test_switchStatement_case1_logicalOr2_left() async {
    await assertErrorsInCode(r'''
void f(num x) {
  switch (x) {
    case final int a || 2:
      return;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 55, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: a
    declaredElement: isFinal a@50
      type: int
  operator: ||
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
    case 1 || final a:
      return;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 40, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
      staticType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@51
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

    final node1 = findNode.switchPatternCase('case /*1*/').guardedPattern;
    assertResolvedNodeText(node1, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@52
      type: int
''');

    final node2 = findNode.switchPatternCase('case /*2*/').guardedPattern;
    assertResolvedNodeText(node2, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredElement: hasImplicitType isFinal a@76
      type: int
''');
  }

  test_switchStatement_case2_left() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final a:
    case 2:
      return;
  }
}
''');
  }

  test_switchStatement_case2_right() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case 1:
    case final a:
      return;
  }
}
''');
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
