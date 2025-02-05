// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer `null`-aware method calls.';

class PreferNullAwareMethodCalls extends LintRule {
  PreferNullAwareMethodCalls()
      : super(
          name: LintNames.prefer_null_aware_method_calls,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_null_aware_method_calls;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    var condition = node.condition;
    if (condition is BinaryExpression &&
        condition.operator.type == TokenType.BANG_EQ &&
        condition.rightOperand is NullLiteral &&
        node.elseExpression is NullLiteral) {
      _check(node.thenExpression, condition);
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    var condition = node.expression;
    if (condition is BinaryExpression &&
        condition.operator.type == TokenType.BANG_EQ &&
        condition.rightOperand is NullLiteral &&
        node.elseKeyword == null) {
      var then = node.thenStatement;
      if (then is Block) {
        if (then.statements.length != 1) {
          return;
        }
        then = then.statements.first;
      }
      if (then is ExpressionStatement) {
        _check(then.expression, condition);
      }
    }
  }

  void _check(Expression expression, BinaryExpression condition) {
    if (expression is FunctionExpressionInvocation) {
      var target = expression.function;
      if (target is PostfixExpression &&
          target.operator.type == TokenType.BANG &&
          target.operand.toSource() == condition.leftOperand.toSource()) {
        rule.reportLint(expression);
      }
    }
  }
}
