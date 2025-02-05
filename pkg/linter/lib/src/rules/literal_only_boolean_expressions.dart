// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Boolean expression composed only with literals.';

bool _onlyLiterals(Expression? rawExpression) {
  var expression = rawExpression?.unParenthesized;
  if (expression is Literal) {
    return true;
  }
  if (expression is PrefixExpression) {
    return _onlyLiterals(expression.operand);
  }
  if (expression is BinaryExpression) {
    if (expression.operator.type == TokenType.QUESTION_QUESTION) {
      return _onlyLiterals(expression.leftOperand);
    }
    return _onlyLiterals(expression.leftOperand) &&
        _onlyLiterals(expression.rightOperand);
  }
  return false;
}

class LiteralOnlyBooleanExpressions extends LintRule {
  LiteralOnlyBooleanExpressions()
      : super(
          name: LintNames.literal_only_boolean_expressions,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.literal_only_boolean_expressions;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addIfStatement(this, visitor);
    registry.addWhenClause(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForParts) {
      if (_onlyLiterals(loopParts.condition)) {
        rule.reportLint(node);
      }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (node.caseClause != null) return;
    if (_onlyLiterals(node.expression)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitWhenClause(WhenClause node) {
    if (_onlyLiterals(node.expression)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    var condition = node.condition;
    // Allow `while (true) { }`
    // See: https://github.com/dart-lang/linter/issues/453
    if (condition is BooleanLiteral && condition.value) {
      return;
    }

    if (_onlyLiterals(condition)) {
      rule.reportLint(node);
    }
  }
}
