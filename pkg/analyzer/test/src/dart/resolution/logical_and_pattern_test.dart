// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LogicalAndPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case int _ && double _) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalAndPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    name: _
    matchedValueType: dynamic
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: double
      element: dart:core::@class::double
      type: double
    name: _
    matchedValueType: int
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case int _ && double _:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalAndPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    name: _
    matchedValueType: dynamic
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: double
      element: dart:core::@class::double
      type: double
    name: _
    matchedValueType: int
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a && b) = 0;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: LogicalAndPattern
        leftOperand: DeclaredVariablePattern
          name: a
          declaredFragment: isPublic a@18
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        operator: &&
        rightOperand: DeclaredVariablePattern
          name: b
          declaredFragment: isPublic b@23
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: _
  semicolon: ;
''');
  }
}
