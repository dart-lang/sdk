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
  statements2
    ExpressionStatement
      expression2: ParsedNameAccess
        operand: ParsedUnqualifiedName
          name: x
        operator: .
        name: foo
      expression(v1): PrefixedIdentifier
        prefix: SimpleIdentifier
          token: x
        period: .
        identifier: SimpleIdentifier
          token: foo
      semicolon: ; <synthetic>
    ExpressionStatement
      expression2: ParsedValueArguments
        operand: ParsedNameAccess
          operand: ParsedUnqualifiedName
            name: y
          operator: .
          name: bar
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
      expression(v1): MethodInvocation
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
  leftBracket: { @15
  statements2
    ExpressionStatement
      expression2: ParsedNameAccess
        operand: ParsedUnqualifiedName
          name: x @19
        operator: . @20
        name: <empty> @24 <synthetic>
      expression(v1): PrefixedIdentifier
        prefix: SimpleIdentifier
          token: x @19
        period: . @20
        identifier: SimpleIdentifier
          token: <empty> @24 <synthetic>
      semicolon: ; @24 <synthetic>
    ExpressionStatement
      expression2: AwaitExpression
        awaitKeyword: await @24
        expression2: ParsedValueArguments
          operand: ParsedNameAccess
            operand: ParsedUnqualifiedName
              name: y @30
            operator: . @31
            name: foo @32
          argumentList: ArgumentList
            leftParenthesis: ( @35
            rightParenthesis: ) @36
        expression(v1): MethodInvocation
          target: SimpleIdentifier
            token: y @30
          operator: . @31
          methodName: SimpleIdentifier
            token: foo @32
          argumentList: ArgumentList
            leftParenthesis: ( @35
            rightParenthesis: ) @36
      semicolon: ; @37
  rightBracket: } @39
''', withOffsets: true);
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
  statements2
    ExpressionStatement
      expression2: ParsedNameAccess
        operand: ParsedUnqualifiedName
          name: x
        operator: .
        name: foo
      expression(v1): PrefixedIdentifier
        prefix: SimpleIdentifier
          token: x
        period: .
        identifier: SimpleIdentifier
          token: foo
      semicolon: ; <synthetic>
    ExpressionStatement
      expression2: RecordLiteral
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ;
  rightBracket: }
''');
  }
}
