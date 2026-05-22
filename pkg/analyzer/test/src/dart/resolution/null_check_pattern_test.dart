// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullCheckPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullCheckPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  if (x case var y?) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredFragment: isPublic y@34
      element: hasImplicitType isPublic
        type: int
    matchedValueType: int
  operator: ?
  matchedValueType: int?
''');
  }

  test_switchCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  switch (x) {
    case var y?:
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredFragment: isPublic y@45
      element: hasImplicitType isPublic
        type: int
    matchedValueType: int
  operator: ?
  matchedValueType: int?
''');
  }

  test_variableDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  var (a?) = x;
//     ^^
// [diag.refutablePatternInIrrefutableContext] Refutable patterns can't be used in an irrefutable context.
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
    pattern: NullCheckPattern
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@24
          element: hasImplicitType isPublic
            type: int
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
}
