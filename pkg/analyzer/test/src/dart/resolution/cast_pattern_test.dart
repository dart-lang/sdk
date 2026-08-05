// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class CastPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case var y as int) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    element: dart:core::@class::int
    type: int
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  const a = 0;
  switch (x) {
    case a as int:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    element: dart:core::@class::int
    type: int
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  var (a as int) = x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singlePatternVariableDeclaration;
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
        element: dart:core::@class::int
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
