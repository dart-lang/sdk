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
  void test_caseAfterDefault() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int a) {
  switch (a) {
    default:
      break;
    case 0:
//  ^^^^
// [diag.switchHasCaseAfterDefaultCase] The default case should be the last case in a switch statement.
      break;
  }
}
''');

    var node = parseResult.findNode.singleSwitchStatement;
    assertParsedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression2: ParsedUnqualifiedName
    name: a
  expression(v1): SimpleIdentifier
    token: a
  rightParenthesis: )
  leftBracket: {
  members
    SwitchDefault
      keyword: default
      colon: :
      statements2
        BreakStatement
          breakKeyword: break
          semicolon: ;
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression2: IntegerLiteral
            literal: 0
      colon: :
      statements2
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  void test_caseAfterDefault_pattern() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch (o) {
    default:
      break;
    case int x:
//  ^^^^
// [diag.switchHasCaseAfterDefaultCase] The default case should be the last case in a switch statement.
      x;
  }
}
''');

    var node = parseResult.findNode.singleSwitchStatement;
    assertParsedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression2: ParsedUnqualifiedName
    name: o
  expression(v1): SimpleIdentifier
    token: o
  rightParenthesis: )
  leftBracket: {
  members
    SwitchDefault
      keyword: default
      colon: :
      statements2
        BreakStatement
          breakKeyword: break
          semicolon: ;
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
          name: x
      colon: :
      statements2
        ExpressionStatement
          expression2: ParsedUnqualifiedName
            name: x
          expression(v1): SimpleIdentifier
            token: x
          semicolon: ;
  rightBracket: }
''');
  }

  void test_multipleDefaults() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int a) {
  switch (a) {
    default:
      break;
    default:
//  ^^^^^^^
// [diag.switchHasMultipleDefaultCases] The 'default' case can only be declared once.
      break;
  }
}
''');

    var node = parseResult.findNode.singleSwitchStatement;
    assertParsedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression2: ParsedUnqualifiedName
    name: a
  expression(v1): SimpleIdentifier
    token: a
  rightParenthesis: )
  leftBracket: {
  members
    SwitchDefault
      keyword: default
      colon: :
      statements2
        BreakStatement
          breakKeyword: break
          semicolon: ;
    SwitchDefault
      keyword: default
      colon: :
      statements2
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  void test_withPatternCase_whenDisabled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// %before-language-feature: patterns
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
  expression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: ParsedUnqualifiedName
      name: int
    expression(v1): SimpleIdentifier
      token: int
    rightParenthesis: )
  colon: :
''');
  }
}
