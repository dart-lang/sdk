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
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case final a) {
    if (x case final b) {}
  }
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 35, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 61, 1),
      ],
    );

    var node1 = findNode.caseClause('case final a').guardedPattern;
    assertResolvedNodeText(node1, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@35
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
''');

    var node2 = findNode.caseClause('case final b').guardedPattern;
    assertResolvedNodeText(node2, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: b
    declaredFragment: isFinal isPublic b@61
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
''');
  }

  test_ifCase_differentStatements_sibling() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case final a) {}
  if (x case final b) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 35, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 60, 1),
      ],
    );

    var node1 = findNode.caseClause('case final a').guardedPattern;
    assertResolvedNodeText(node1, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@35
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
''');

    var node2 = findNode.caseClause('case final b').guardedPattern;
    assertResolvedNodeText(node2, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: b
    declaredFragment: isFinal isPublic b@60
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
''');
  }

  test_ifCase_logicalOr2_both_direct() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case final a || final a) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 35, 1),
        error(WarningCode.DEAD_CODE, 37, 10),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 46, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@35
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@46
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_ifCase_logicalOr2_both_nested_logicalAnd() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case 0 && final a || final a) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 40, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 51, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalAndPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: int
    operator: &&
    rightOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredFragment: isFinal isPublic a@40
        element: hasImplicitType isFinal isPublic
          type: int
      matchedValueType: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@51
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_ifCase_logicalOr2_left() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  if (x case final int a || 2) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 39, 1),
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 44, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    name: a
    declaredFragment: isFinal isPublic a@39
      element: isFinal isPublic
        type: int
    matchedValueType: num
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
      staticType: int
    matchedValueType: num
  matchedValueType: num
''');
  }

  test_ifCase_logicalOr2_right() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case 1 || final a) {}
}
''',
      [
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
      staticType: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@40
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_ifCase_logicalOr3_1() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  if (x case final int a || 2 || 3) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 39, 1),
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 44, 1),
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 49, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isFinal isPublic a@39
        element: isFinal isPublic
          type: int
      matchedValueType: num
    operator: ||
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
      matchedValueType: num
    matchedValueType: num
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
    matchedValueType: num
  matchedValueType: num
''');
  }

  test_ifCase_logicalOr3_12() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  if (x case final int a || final int a || 3) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 39, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 54, 1),
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 59, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isFinal isPublic a@39
        element: isFinal isPublic
          type: int
      matchedValueType: num
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isFinal isPublic a@54
        element: isFinal isPublic
          type: int
      matchedValueType: num
    matchedValueType: num
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
    matchedValueType: num
  matchedValueType: num
''');
  }

  test_ifCase_logicalOr3_123() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case final a || final a || final a) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 35, 1),
        error(WarningCode.DEAD_CODE, 37, 10),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 46, 1),
        error(WarningCode.DEAD_CODE, 48, 10),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 57, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredFragment: isFinal isPublic a@35
        element: hasImplicitType isFinal isPublic
          type: int
      matchedValueType: int
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredFragment: isFinal isPublic a@46
        element: hasImplicitType isFinal isPublic
          type: int
      matchedValueType: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@57
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_ifCase_logicalOr3_13() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  if (x case final int a || 2 || final int a) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 39, 1),
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 44, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 59, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isFinal isPublic a@39
        element: isFinal isPublic
          type: int
      matchedValueType: num
    operator: ||
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
      matchedValueType: num
    matchedValueType: num
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    name: a
    declaredFragment: isFinal isPublic a@59
      element: isFinal isPublic
        type: int
    matchedValueType: num
  matchedValueType: num
''');
  }

  test_ifCase_logicalOr3_2() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  if (x case 1 || final int a || 3) {}
}
''',
      [
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 44, 1),
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 49, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
      matchedValueType: num
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isFinal isPublic a@44
        element: isFinal isPublic
          type: int
      matchedValueType: num
    matchedValueType: num
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 3
      staticType: int
    matchedValueType: num
  matchedValueType: num
''');
  }

  test_ifCase_logicalOr3_23() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case 1 || final a || final a) {}
}
''',
      [
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 40, 1),
        error(WarningCode.DEAD_CODE, 42, 10),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 51, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
      matchedValueType: int
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: final
      name: a
      declaredFragment: isFinal isPublic a@40
        element: hasImplicitType isFinal isPublic
          type: int
      matchedValueType: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@51
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_ifCase_logicalOr3_3() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case 1 || 2 || final a) {}
}
''',
      [
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 29, 6),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 45, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 1
        staticType: int
      matchedValueType: int
    operator: ||
    rightOperand: ConstantPattern
      expression: IntegerLiteral
        literal: 2
        staticType: int
      matchedValueType: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@45
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_switchStatement_case1_logicalOr2_both() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case final a || final a:
      return;
  }
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 46, 1),
        error(WarningCode.DEAD_CODE, 48, 10),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 57, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@46
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@57
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_switchStatement_case1_logicalOr2_left() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  switch (x) {
    case final int a || 2:
      return;
    default:
      return;
  }
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 50, 1),
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 55, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    name: a
    declaredFragment: isFinal isPublic a@50
      element: isFinal isPublic
        type: int
    matchedValueType: num
  operator: ||
  rightOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 2
      staticType: int
    matchedValueType: num
  matchedValueType: num
''');
  }

  test_switchStatement_case1_logicalOr2_right() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case 1 || final a:
      return;
  }
}
''',
      [
        error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 40, 1),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 51, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: ConstantPattern
    expression: IntegerLiteral
      literal: 1
      staticType: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@51
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }

  test_switchStatement_case2_both() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case /*1*/ final a:
    case /*2*/ final a:
      return;
  }
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 52, 1),
        error(WarningCode.DEAD_CODE, 59, 4),
        error(WarningCode.UNREACHABLE_SWITCH_CASE, 59, 4),
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 76, 1),
      ],
    );

    var node1 = findNode.switchPatternCase('case /*1*/').guardedPattern;
    assertResolvedNodeText(node1, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@52
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
''');

    var node2 = findNode.switchPatternCase('case /*2*/').guardedPattern;
    assertResolvedNodeText(node2, r'''
GuardedPattern
  pattern: DeclaredVariablePattern
    keyword: final
    name: a
    declaredFragment: isFinal isPublic a@76
      element: hasImplicitType isFinal isPublic
        type: int
    matchedValueType: int
''');
  }

  test_switchStatement_case2_left() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  switch (x) {
    case final double a:
    case 2:
      return;
    default:
      return;
  }
}
''',
      [error(WarningCode.UNUSED_LOCAL_VARIABLE, 53, 1)],
    );
  }

  test_switchStatement_case2_right() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case 1:
    case final a:
      return;
  }
}
''',
      [error(WarningCode.UNUSED_LOCAL_VARIABLE, 58, 1)],
    );
  }

  test_switchStatement_differentCases_nested() async {
    await assertErrorsInCode(
      r'''
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
''',
      [error(WarningCode.UNUSED_LOCAL_VARIABLE, 46, 1)],
    );
  }

  test_switchStatement_differentCases_sibling() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  switch (x) {
    case final double a:
      return;
    case 2:
      return;
    default:
      return;
  }
}
''',
      [error(WarningCode.UNUSED_LOCAL_VARIABLE, 53, 1)],
    );
  }
}
