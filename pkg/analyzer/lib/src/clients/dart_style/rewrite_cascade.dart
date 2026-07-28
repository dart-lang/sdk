// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// Parenthesize the target of the [expressionStatement]'s expression (assumed
/// to [cascadeExpression]) before removing the cascade.
ExpressionStatement fixCascadeByParenthesizingTarget({
  required ExpressionStatement expressionStatement,
  required CascadeExpression cascadeExpression,
}) {
  cascadeExpression as CascadeExpressionImpl;
  assert(cascadeExpression.cascadeSections2.length == 1);

  var newTarget = ParenthesizedExpressionImpl(
    leftParenthesis: Token(TokenType.OPEN_PAREN, 0)
      ..previous = expressionStatement.beginToken.previous
      ..next = cascadeExpression.target2.beginToken,
    expression2: cascadeExpression.target2,
    rightParenthesis: Token(TokenType.CLOSE_PAREN, 0)
      ..previous = cascadeExpression.target2.endToken
      ..next = expressionStatement.semicolon,
  );

  return ExpressionStatementImpl(
    expression2: CascadeExpressionImpl(
      target2: newTarget,
      cascadeSections2: cascadeExpression.cascadeSections2,
    ),
    semicolon: expressionStatement.semicolon,
  );
}

/// Recursively insert [cascadeTarget] (the LHS of the cascade) into the
/// LHS of the assignment expression that used to be the cascade's RHS.
ExpressionImpl insertCascadeTargetIntoExpression({
  required Expression expression,
  required Expression cascadeTarget,
}) {
  expression as ExpressionImpl;
  cascadeTarget as ExpressionImpl;

  // Base case: We've recursed as deep as possible.
  if (expression == cascadeTarget) return cascadeTarget;

  // Otherwise, copy `expression` and recurse into its LHS.
  if (expression is AssignmentExpressionImpl) {
    return AssignmentExpressionImpl(
      leftHandSide2: insertCascadeTargetIntoExpression(
        expression: expression.leftHandSide2,
        cascadeTarget: cascadeTarget,
      ),
      operator: expression.operator,
      rightHandSide2: expression.rightHandSide2,
    );
  } else if (expression is IndexExpressionImpl) {
    var expressionTarget = expression.realTarget;
    var question = expression.question;

    // A null-aware cascade treats the `?` in `?..` as part of the token, but
    // for a non-cascade index, it is a separate `?` token.
    if (expression.period?.type == TokenType.QUESTION_PERIOD_PERIOD) {
      question = _synthesizeToken(TokenType.QUESTION, expression.period!);
    }

    return IndexExpressionImpl(
      target2: insertCascadeTargetIntoExpression(
        expression: expressionTarget,
        cascadeTarget: cascadeTarget,
      ),
      period: null,
      question: question,
      leftBracket: expression.leftBracket,
      index2: expression.index2,
      rightBracket: expression.rightBracket,
    );
  } else if (expression is MethodInvocationImpl) {
    var expressionTarget = expression.realTarget!;
    return MethodInvocationImpl(
      target2: insertCascadeTargetIntoExpression(
        expression: expressionTarget,
        cascadeTarget: cascadeTarget,
      ),
      // If we've reached the end, replace the `..` operator with `.`
      operator: expressionTarget == cascadeTarget
          ? _synthesizeToken(TokenType.PERIOD, expression.operator!)
          : expression.operator,
      methodName: expression.methodName,
      typeArguments: expression.typeArguments,
      argumentList: expression.argumentList,
    );
  } else if (expression is PropertyAccessImpl) {
    var expressionTarget = expression.realTarget;
    return PropertyAccessImpl(
      target2: insertCascadeTargetIntoExpression(
        expression: expressionTarget,
        cascadeTarget: cascadeTarget,
      ),
      // If we've reached the end, replace the `..` operator with `.`
      operator: expressionTarget == cascadeTarget
          ? _synthesizeToken(TokenType.PERIOD, expression.operator)
          : expression.operator,
      propertyName: expression.propertyName,
    );
  }
  throw UnimplementedError(
    'Unhandled ${expression.runtimeType}'
    '($expression)',
  );
}

/// Synthesize a token with [type] to replace the given [operator].
///
/// Offset, comments, and previous/next links are all preserved.
Token _synthesizeToken(TokenType type, Token operator) =>
    Token(type, operator.offset, operator.precedingComments)
      ..previous = operator.previous
      ..next = operator.next;
