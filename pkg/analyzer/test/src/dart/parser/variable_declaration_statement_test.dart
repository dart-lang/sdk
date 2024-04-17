// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableDeclarationStatementParserTest);
  });
}

@reflectiveTest
class VariableDeclarationStatementParserTest extends ParserDiagnosticsTest {
  test_recovery_propertyAccess_beforeAwait_hasIdentifier() {
    var parseResult = parseStringWithErrors(r'''
void f(x) async {
  x.foo
  await x.bar();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 28, 5),
      error(ParserErrorCode.EXPECTED_TOKEN, 28, 5),
    ]);

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: x
        period: .
        identifier: SimpleIdentifier
          token: foo
      semicolon: ; <synthetic>
    ExpressionStatement
      expression: AwaitExpression
        awaitKeyword: await
        expression: MethodInvocation
          target: SimpleIdentifier
            token: x
          operator: .
          methodName: SimpleIdentifier
            token: bar
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_recovery_propertyAccess_beforeAwait_noIdentifier() {
    var parseResult = parseStringWithErrors(r'''
void f(x) async {
  x.
  await x.foo();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 31, 1),
    ]);

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: x
        period: .
        identifier: SimpleIdentifier
          token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExpressionStatement
      expression: AwaitExpression
        awaitKeyword: await
        expression: MethodInvocation
          target: SimpleIdentifier
            token: x
          operator: .
          methodName: SimpleIdentifier
            token: foo
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }

  test_recovery_propertyAccess_beforeIdentifier_hasIdentifier() {
    var parseResult = parseStringWithErrors(r'''
void f(x) {
  x.foo
  bar();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 22, 3),
    ]);

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: x
        period: .
        identifier: SimpleIdentifier
          token: foo
      semicolon: ; <synthetic>
    ExpressionStatement
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: bar
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }
}
