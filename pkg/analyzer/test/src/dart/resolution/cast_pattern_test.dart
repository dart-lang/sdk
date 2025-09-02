// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternResolutionTest);
  });
}

@reflectiveTest
class CastPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  if (x case var y as int) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 29, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredFragment: isPublic y@29
      element: hasImplicitType isPublic
        type: int
    matchedValueType: int
  asToken: as
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  switch (x) {
    case a as int:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: a
      element: a@20
      staticType: int
    matchedValueType: int
  asToken: as
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  var (a as int) = x;
}
''',
      [error(WarningCode.unusedLocalVariable, 19, 1)],
    );
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: CastPattern
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@19
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      asToken: as
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      matchedValueType: dynamic
    rightParenthesis: )
    matchedValueType: dynamic
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  patternTypeSchema: _
''');
  }
}
