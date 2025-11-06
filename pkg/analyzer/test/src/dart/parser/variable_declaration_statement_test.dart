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
void f() async {
  x.foo
  await y.bar();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.asyncKeywordUsedAsIdentifier, 27, 5),
      error(ParserErrorCode.expectedToken, 27, 5),
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
        target: SimpleIdentifier
          token: y
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
void f() async {
  x.
  await y.foo();
}
''');
    parseResult.assertErrors([error(ParserErrorCode.expectedToken, 30, 1)]);

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
            token: y
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
void f() {
  x.foo
  bar();
}
''');
    parseResult.assertErrors([error(ParserErrorCode.expectedToken, 21, 3)]);

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
      expression: RecordLiteral
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }
}
