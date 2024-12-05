// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndPatternResolutionTest);
  });
}

@reflectiveTest
class LogicalAndPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int _ && double _) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalAndPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      element: dart:core::<fragment>::@class::int
      element2: dart:core::<fragment>::@class::int#element
      type: int
    name: _
    matchedValueType: dynamic
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: double
      element: dart:core::<fragment>::@class::double
      element2: dart:core::<fragment>::@class::double#element
      type: double
    name: _
    matchedValueType: int
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int _ && double _:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalAndPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      element: dart:core::<fragment>::@class::int
      element2: dart:core::<fragment>::@class::int#element
      type: int
    name: _
    matchedValueType: dynamic
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: double
      element: dart:core::<fragment>::@class::double
      element2: dart:core::<fragment>::@class::double#element
      type: double
    name: _
    matchedValueType: int
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
void f() {
  var (a && b) = 0;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 23, 1),
    ]);
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: LogicalAndPattern
        leftOperand: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@18
            type: int
          matchedValueType: int
        operator: &&
        rightOperand: DeclaredVariablePattern
          name: b
          declaredElement: hasImplicitType b@23
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
