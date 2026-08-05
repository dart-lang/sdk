// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SwitchStatementParserTest extends ParserDiagnosticsTest {
  void test_withPatternCase_whenDisabled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(Object value) {
  switch (value) {
    case (int a,) when a == 0:
//            ^
// [diag.expectedToken] Expected to find ')'.
  }
}
''');

    var node = parseResult.findNode.singleSwitchCase;
    assertParsedNodeText(node, r'''
SwitchCase
  keyword: case
  expression: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: int
    rightParenthesis: )
  colon: :
''');
  }
}
