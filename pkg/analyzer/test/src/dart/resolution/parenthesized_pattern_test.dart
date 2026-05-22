// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParenthesizedPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ParenthesizedPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case (0)) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 0
      staticType: int
    matchedValueType: dynamic
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case (0):
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 0
      staticType: int
    matchedValueType: dynamic
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }
}
