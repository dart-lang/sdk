// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Prefer `null`-aware method calls.';

class PreferNullAwareMethodCalls extends AnalysisRule {
  PreferNullAwareMethodCalls()
    : super(name: LintNames.prefer_null_aware_method_calls, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.preferNullAwareMethodCalls;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

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
        rule.reportAtNode(expression);
      }
    }
  }
}
