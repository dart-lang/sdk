// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingVariablePatternTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingVariablePatternTest extends PubPackageResolutionTest {
  test_ifCase_differentStatements_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case final a) {
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    if (x case final b) {}
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  }
}
''');

    var node1 = result.findNode.caseClause('case final a').guardedPattern;
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

    var node2 = result.findNode.caseClause('case final b').guardedPattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case final a) {}
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  if (x case final b) {}
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');

    var node1 = result.findNode.caseClause('case final a').guardedPattern;
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

    var node2 = result.findNode.caseClause('case final b').guardedPattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case final a || final a) {}
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                   ^^^^^^^^^^
// [diag.deadCode] Dead code.
//                            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case 0 && final a || final a) {}
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case final int a || 2) {}
//                     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                          ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: int
      element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case 1 || final a) {}
//           ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case final int a || 2 || 3) {}
//                     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                          ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
//                               ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case final int a || final int a || 3) {}
//                     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                                    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                                         ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element: dart:core::@class::int
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case final a || final a || final a) {}
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                   ^^^^^^^^^^
// [diag.deadCode] Dead code.
//                            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                              ^^^^^^^^^^
// [diag.deadCode] Dead code.
//                                       ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case final int a || 2 || final int a) {}
//                     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                          ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
//                                         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: final
      type: NamedType
        name: int
        element: dart:core::@class::int
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
      element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case 1 || final int a || 3) {}
//           ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
//                          ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                               ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case 1 || final a || final a) {}
//           ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                        ^^^^^^^^^^
// [diag.deadCode] Dead code.
//                                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case 1 || 2 || final a) {}
//           ^^^^^^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
//                           ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case final a || final a:
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//               ^^^^^^^^^^
// [diag.deadCode] Dead code.
//                        ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      return;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  switch (x) {
    case final int a || 2:
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                      ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
      return;
    default:
      return;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: DeclaredVariablePattern
    keyword: final
    type: NamedType
      name: int
      element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case 1 || final a:
//       ^
// [diag.missingVariablePattern] Variable pattern 'a' is missing in this branch of the logical-or pattern.
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      return;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case /*1*/ final a:
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    case /*2*/ final a:
//  ^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      return;
  }
}
''');

    var node1 = result.findNode.switchPatternCase('case /*1*/').guardedPattern;
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

    var node2 = result.findNode.switchPatternCase('case /*2*/').guardedPattern;
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
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  switch (x) {
    case final double a:
//                    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    case 2:
      return;
    default:
      return;
  }
}
''');
  }

  test_switchStatement_case2_right() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case 1:
    case final a:
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      return;
  }
}
''');
  }

  test_switchStatement_differentCases_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case final a:
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
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
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  switch (x) {
    case final double a:
//                    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      return;
    case 2:
      return;
    default:
      return;
  }
}
''');
  }
}
