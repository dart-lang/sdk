// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RefutablePatternInIrrefutableContextTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RefutablePatternInIrrefutableContextTest
    extends PubPackageResolutionTest {
  test_declaration_constantPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (0) = 0;
//     ^
// [diag.refutablePatternInIrrefutableContext] Refutable patterns can't be used in an irrefutable context.
}
''');

    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
''');
  }

  test_declaration_logicalOrPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (_ || _) = 0;
//     ^^^^^^
// [diag.refutablePatternInIrrefutableContext] Refutable patterns can't be used in an irrefutable context.
//       ^^^^
// [diag.deadCode] Dead code.
}
''');

    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: LogicalOrPattern
      leftOperand: WildcardPattern
        name: _
        matchedValueType: int
      operator: ||
      rightOperand: WildcardPattern
        name: _
        matchedValueType: int
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
''');
  }

  test_declaration_nullCheckPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  var (_?) = x;
//     ^^
// [diag.refutablePatternInIrrefutableContext] Refutable patterns can't be used in an irrefutable context.
}
''');

    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: NullCheckPattern
      pattern: WildcardPattern
        name: _
        matchedValueType: int
      operator: ?
      matchedValueType: int?
    rightParenthesis: )
    matchedValueType: int?
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int?
  patternTypeSchema: _
''');
  }

  test_declaration_relationalPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (> 0) = 0;
//     ^^^
// [diag.refutablePatternInIrrefutableContext] Refutable patterns can't be used in an irrefutable context.
}
''');

    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: RelationalPattern
      operator: >
      operand: IntegerLiteral
        literal: 0
        staticType: int
      element: dart:core::@class::num::@method::>
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
''');
  }
}
