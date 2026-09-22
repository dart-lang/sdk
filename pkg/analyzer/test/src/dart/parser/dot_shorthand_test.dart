// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DotShorthandParserTest extends ParserDiagnosticsTest {
  void test_chain_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Object f() => const .new().value;
''');
    var node = parseResult.findNode.singleExpressionFunctionBody.expression2;
    assertParsedNodeText(node, r'''
ParsedDotShorthandExpression
  expression: ParsedNameAccess
    operand: DotShorthandConstructorInvocation
      constKeyword: const
      period: .
      constructorName: SimpleIdentifier
        token: new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
    operator: .
    name: value
V1: PropertyAccess
  target: DotShorthandConstructorInvocation
    constKeyword: const
    period: .
    constructorName: SimpleIdentifier
      token: new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: value
''');
  }

  void test_chain_index_nullAssert_method() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Object f() => .values[0]!.method<int>();
''');
    var node = parseResult.findNode.singleExpressionFunctionBody.expression2;
    assertParsedNodeText(node, r'''
ParsedDotShorthandExpression
  expression: ParsedValueArguments
    operand: ParsedTypeArguments
      operand: ParsedNameAccess
        operand: NullAssertionExpression
          operand: ReceiverIndexExpression
            receiver: DotShorthandPropertyAccess
              period: .
              propertyName: SimpleIdentifier
                token: values
            leftBracket: [
            index: IntegerLiteral
              literal: 0
            rightBracket: ]
          operator: !
        operator: .
        name: method
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
V1: MethodInvocation
  target: PostfixExpression
    operand: IndexExpression
      target: DotShorthandPropertyAccess
        period: .
        propertyName: SimpleIdentifier
          token: values
      leftBracket: [
      index: IntegerLiteral
        literal: 0
      rightBracket: ]
    operator: !
  operator: .
  methodName: SimpleIdentifier
    token: method
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_chain_typeArguments() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Object f() => .identity<int>.call(0);
''');
    var node = parseResult.findNode.singleExpressionFunctionBody.expression2;
    assertParsedNodeText(node, r'''
ParsedDotShorthandExpression
  expression: ParsedValueArguments
    operand: ParsedNameAccess
      operand: ParsedTypeArguments
        operand: DotShorthandPropertyAccess
          period: .
          propertyName: SimpleIdentifier
            token: identity
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
      operator: .
      name: call
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
      rightParenthesis: )
V1: MethodInvocation
  target: FunctionReference
    function: DotShorthandPropertyAccess
      period: .
      propertyName: SimpleIdentifier
        token: identity
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  operator: .
  methodName: SimpleIdentifier
    token: call
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
    rightParenthesis: )
''');
  }

  void test_invocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {}

void main() {
  C c = .new();
}
''');

    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
ParsedDotShorthandExpression
  expression: DotShorthandInvocation
    period: .
    memberName: SimpleIdentifier
      token: new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
V1: DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parenthesized() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Object f() => (.value).method();
''');
    var node = parseResult.findNode.singleExpressionFunctionBody.expression2;
    assertParsedNodeText(node, r'''
ParsedValueArguments
  operand: ParsedNameAccess
    operand: ParenthesizedExpression
      leftParenthesis: (
      expression2: ParsedDotShorthandExpression
        expression: DotShorthandPropertyAccess
          period: .
          propertyName: SimpleIdentifier
            token: value
      rightParenthesis: )
    operator: .
    name: method
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
V1: MethodInvocation
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: DotShorthandPropertyAccess
      period: .
      propertyName: SimpleIdentifier
        token: value
    rightParenthesis: )
  operator: .
  methodName: SimpleIdentifier
    token: method
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_propertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E { a }

void main() {
  E e = .a;
}
''');

    var node = parseResult.findNode.singleVariableDeclaration.initializer2!;
    assertParsedNodeText(node, r'''
ParsedDotShorthandExpression
  expression: DotShorthandPropertyAccess
    period: .
    propertyName: SimpleIdentifier
      token: a
V1: DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: a
''');
  }
}
