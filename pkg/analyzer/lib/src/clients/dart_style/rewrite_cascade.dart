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
      sections: cascadeExpression.sections,
    ),
    semicolon: expressionStatement.semicolon,
  );
}

/// Recursively insert [cascadeTarget] (the LHS of the cascade) into the
/// LHS of the assignment expression that used to be the cascade's RHS.
ExpressionImpl insertCascadeTargetIntoExpression({
  required Expression expression,
  required Expression cascadeTarget,
  Token? cascadeOperator,
}) {
  expression as ExpressionImpl;
  cascadeTarget as ExpressionImpl;
  cascadeOperator ??= _cascadeOperator(expression);

  // Base case: We've recursed as deep as possible.
  if (expression == cascadeTarget) return cascadeTarget;

  // Otherwise, copy `expression` and recurse into its LHS.
  if (expression is AssignmentExpressionImpl) {
    return AssignmentExpressionImpl(
      leftHandSide2: insertCascadeTargetIntoExpression(
        expression: expression.leftHandSide2,
        cascadeTarget: cascadeTarget,
        cascadeOperator: cascadeOperator,
      ),
      operator: expression.operator,
      rightHandSide2: expression.rightHandSide2,
    );
  } else if (expression is CascadeIndexExpressionImpl) {
    return IndexExpression2Impl(
      receiver: cascadeTarget,
      question: cascadeOperator?.type == TokenType.QUESTION_PERIOD_PERIOD
          ? _synthesizeToken(TokenType.QUESTION, cascadeOperator!)
          : null,
      leftBracket: expression.leftBracket,
      index: expression.index,
      rightBracket: expression.rightBracket,
    );
  } else if (expression is CascadePropertyExtractionImpl) {
    return PropertyExtractionImpl(
      receiver: cascadeTarget,
      operator: _synthesizeToken(
        cascadeOperator?.type == TokenType.QUESTION_PERIOD_PERIOD
            ? TokenType.QUESTION_PERIOD
            : TokenType.PERIOD,
        cascadeOperator!,
      ),
      propertyName: expression.propertyName,
    );
  } else if (expression is PropertyExtractionImpl) {
    return PropertyExtractionImpl(
      receiver: insertCascadeTargetIntoExpression(
        expression: expression.receiver,
        cascadeTarget: cascadeTarget,
      ),
      operator: expression.operator,
      propertyName: expression.propertyName,
    );
  } else if (expression is IndexExpression2Impl) {
    return IndexExpression2Impl(
      receiver: insertCascadeTargetIntoExpression(
        expression: expression.receiver,
        cascadeTarget: cascadeTarget,
      ),
      question: expression.question,
      leftBracket: expression.leftBracket,
      index: expression.index,
      rightBracket: expression.rightBracket,
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
    var expressionTarget = expression.realTarget2!;
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
  } else if (expression is DirectAssignmentImpl) {
    var target = expression.target;
    if (target is CascadeIndexAssignmentTargetImpl) {
      return DirectAssignmentImpl(
        target: IndexAssignmentTargetImpl(
          receiver: cascadeTarget,
          question: cascadeOperator?.type == TokenType.QUESTION_PERIOD_PERIOD
              ? _synthesizeToken(TokenType.QUESTION, cascadeOperator!)
              : null,
          leftBracket: target.leftBracket,
          index: target.index,
          rightBracket: target.rightBracket,
        ),
        operator: expression.operator,
        value: expression.value,
      );
    }
    if (target is CascadePropertyAssignmentTargetImpl) {
      return DirectAssignmentImpl(
        target: PropertyAssignmentTargetImpl(
          receiver: cascadeTarget,
          operator: _synthesizeToken(
            cascadeOperator?.type == TokenType.QUESTION_PERIOD_PERIOD
                ? TokenType.QUESTION_PERIOD
                : TokenType.PERIOD,
            cascadeOperator!,
          ),
          propertyName: target.propertyName,
        ),
        operator: expression.operator,
        value: expression.value,
      );
    }
    if (target is IndexAssignmentTargetImpl) {
      return DirectAssignmentImpl(
        target: IndexAssignmentTargetImpl(
          receiver: insertCascadeTargetIntoExpression(
            expression: target.receiver,
            cascadeTarget: cascadeTarget,
          ),
          question: target.question,
          leftBracket: target.leftBracket,
          index: target.index,
          rightBracket: target.rightBracket,
        ),
        operator: expression.operator,
        value: expression.value,
      );
    }
    if (target is! PropertyAssignmentTargetImpl) {
      throw UnimplementedError(
        'Unhandled ${target.runtimeType} in $expression',
      );
    }
    return DirectAssignmentImpl(
      target: PropertyAssignmentTargetImpl(
        receiver: insertCascadeTargetIntoExpression(
          expression: target.receiver,
          cascadeTarget: cascadeTarget,
        ),
        operator: target.operator,
        propertyName: target.propertyName,
      ),
      operator: expression.operator,
      value: expression.value,
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

Token? _cascadeOperator(AstNodeImpl node) {
  for (
    AstNodeImpl? ancestor = node;
    ancestor != null;
    ancestor = ancestor.parentInPrimaryView
  ) {
    if (ancestor is CascadeSectionImpl) return ancestor.operator;
    var operator = switch (ancestor) {
      IndexExpression(:var period) => period,
      MethodInvocation(:var operator) => operator,
      PropertyAccess(:var operator) => operator,
      _ => null,
    };
    if (operator?.type
        case TokenType.PERIOD_PERIOD || TokenType.QUESTION_PERIOD_PERIOD) {
      return operator;
    }
  }
  return null;
}

/// Synthesize a token with [type] to replace the given [operator].
///
/// Offset, comments, and previous/next links are all preserved.
Token _synthesizeToken(TokenType type, Token operator) =>
    Token(type, operator.offset, operator.precedingComments)
      ..previous = operator.previous
      ..next = operator.next;
