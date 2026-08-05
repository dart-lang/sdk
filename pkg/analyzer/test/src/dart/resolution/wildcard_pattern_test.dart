// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WildcardPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WildcardPatternResolutionTest extends PubPackageResolutionTest {
  test_assignmentContext_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  (_) = 0;
}
''');
    var node = result.findNode.singlePatternAssignment.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: WildcardPattern
    name: _
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_declarationContext_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (int _) = 0;
}
''');
    var node = result.findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: WildcardPattern
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    name: _
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_declarationContext_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (_) = 0;
}
''');
    var node = result.findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: WildcardPattern
    name: _
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_matchingContext_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case int _) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  type: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  name: _
  matchedValueType: dynamic
''');
  }

  test_matchingContext_typed_final() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case final int _) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  keyword: final
  type: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  name: _
  matchedValueType: dynamic
''');
  }

  test_matchingContext_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case _) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  name: _
  matchedValueType: dynamic
''');
  }

  test_matchingContext_untyped_final() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case final _) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  keyword: final
  name: _
  matchedValueType: dynamic
''');
  }
}
