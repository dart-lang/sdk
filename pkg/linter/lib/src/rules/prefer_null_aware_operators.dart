// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer using `null`-aware operators.';

class PreferNullAwareOperators extends LintRule {
  PreferNullAwareOperators()
      : super(
          name: LintNames.prefer_null_aware_operators,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_null_aware_operators;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    var condition = node.condition;
    if (condition is! BinaryExpression) {
      return;
    }

    // Ensure the condition is a null check.
    String conditionText;
    if (condition.leftOperand is NullLiteral) {
      conditionText = condition.rightOperand.toString();
    } else if (condition.rightOperand is NullLiteral) {
      conditionText = condition.leftOperand.toString();
    } else {
      return;
    }

    Expression? resultExpression;
    if (condition.operator.type == TokenType.EQ_EQ) {
      // Ensure the expression is `x == null ? null : y`.
      if (node.thenExpression is! NullLiteral) return;

      resultExpression = node.elseExpression;
    } else if (condition.operator.type == TokenType.BANG_EQ) {
      // Ensure the expression is `x != null ? y : null`.
      if (node.elseExpression is! NullLiteral) return;

      resultExpression = node.thenExpression;
    } else {
      return;
    }

    while (resultExpression != null) {
      resultExpression = switch (resultExpression) {
        PrefixedIdentifier() => resultExpression.prefix,
        MethodInvocation() => resultExpression.target,
        PostfixExpression()
            when resultExpression.operator.type == TokenType.BANG =>
          resultExpression.operand,
        PropertyAccess() => resultExpression.target,
        _ => null,
      };
      if (resultExpression.toString() == conditionText) {
        rule.reportLint(node);
        return;
      }
    }
  }
}
