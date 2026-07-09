// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalOrPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LogicalOrPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case int _ || double _) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    name: _
    matchedValueType: dynamic
  operator: ||
  rightOperand: WildcardPattern
    type: NamedType
      name: double
      element: dart:core::@class::double
      type: double
    name: _
    matchedValueType: dynamic
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case int _ || double _:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    name: _
    matchedValueType: dynamic
  operator: ||
  rightOperand: WildcardPattern
    type: NamedType
      name: double
      element: dart:core::@class::double
      type: double
    name: _
    matchedValueType: dynamic
  matchedValueType: dynamic
''');
  }

  test_switchCase_topLevel3() async {
    // https://github.com/dart-lang/sdk/issues/60168
    var result = await resolveTestCodeWithDiagnostics(r'''
var _ = switch (0) {
//  ^
// [diag.unusedElement] The declaration '_' isn't referenced.
  var a || var a || var a => 0,
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//      ^^^^^^^^
// [diag.deadCode] Dead code.
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//               ^^^^^^^^
// [diag.deadCode] Dead code.
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
};
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalOrPattern
  leftOperand: LogicalOrPattern
    leftOperand: DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@27
        element: hasImplicitType isPublic
          type: int
      matchedValueType: int
    operator: ||
    rightOperand: DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@36
        element: hasImplicitType isPublic
          type: int
      matchedValueType: int
    matchedValueType: int
  operator: ||
  rightOperand: DeclaredVariablePattern
    keyword: var
    name: a
    declaredFragment: isPublic a@45
      element: hasImplicitType isPublic
        type: int
    matchedValueType: int
  matchedValueType: int
''');
  }
}
