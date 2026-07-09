// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableDeclarationStatementParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class VariableDeclarationStatementParserTest extends ParserDiagnosticsTest {
  test_recovery_propertyAccess_beforeAwait_hasIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async {
  x.foo
  await y.bar();
//^^^^^
// [diag.asyncKeywordUsedAsIdentifier] The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.
// [diag.expectedToken] Expected to find ';'.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async {
  x.
  await y.foo();
//      ^
// [diag.expectedToken] Expected to find ';'.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x.foo
  bar();
//^^^
// [diag.expectedToken] Expected to find ';'.
}
''');

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
