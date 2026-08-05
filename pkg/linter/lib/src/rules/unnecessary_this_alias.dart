// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc =
    r"Use 'this' directly instead of assigning it to a local variable.";

/// Unnecessary local variable initialized to `this`.
class UnnecessaryThisAlias extends AnalysisRule {
  new()
    : super(
        name: LintNames.unnecessary_this_alias,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryThisAlias;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.this_promotion)) return;
    var visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _ReferenceVisitor(final LocalVariableElement element)
    extends RecursiveAstVisitor<void> {
  bool hasPromotionUsage = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (hasPromotionUsage) return;
    if (node.element == element) {
      if (_isPromotionUsage(node)) {
        hasPromotionUsage = true;
      }
    }
    super.visitSimpleIdentifier(node);
  }

  bool _isPromotionUsage(SimpleIdentifier node) {
    var expr = _skipParenthesesUp(node);
    return switch (expr.parent) {
      IsExpression(:var expression) => expression == expr,
      AsExpression(:var expression) => expression == expr,
      PostfixExpression(:var operand, :var operator) =>
        operand == expr && operator.type == TokenType.BANG,
      BinaryExpression(:var leftOperand, :var rightOperand, :var operator) =>
        (operator.type == TokenType.EQ_EQ ||
                operator.type == TokenType.BANG_EQ) &&
            ((leftOperand == expr &&
                    rightOperand.unParenthesized is NullLiteral) ||
                (rightOperand == expr &&
                    leftOperand.unParenthesized is NullLiteral)),
      SwitchStatement(:var expression) => expression == expr,
      SwitchExpression(:var expression) => expression == expr,
      IfStatement(:var expression, :var caseClause) =>
        expression == expr && caseClause != null,
      _ => false,
    };
  }

  Expression _skipParenthesesUp(Expression node) {
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      node = parent;
      parent = parent.parent;
    }
    return node;
  }
}

class _Visitor(final AnalysisRule rule) extends SimpleAstVisitor<void> {
  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var initializer = node.initializer?.unParenthesized;
    if (initializer is! ThisExpression) return;

    var element = node.declaredFragment?.element;
    if (element is! LocalVariableElement) return;

    var parentList = node.parent;
    if (parentList is VariableDeclarationList && parentList.isLate) return;

    var variableType = element.type;
    var thisType = initializer.staticType;
    if (variableType != thisType) return;

    var functionBody = node.thisOrAncestorOfType<FunctionBody>();
    if (functionBody == null) return;

    if (functionBody.isPotentiallyMutatedInScope(element)) return;

    var visitor = _ReferenceVisitor(element);
    functionBody.accept(visitor);
    if (!visitor.hasPromotionUsage) return;

    rule.reportAtToken(node.name);
  }
}
