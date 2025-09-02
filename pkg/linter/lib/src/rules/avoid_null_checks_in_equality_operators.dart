// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't check for `null` in custom `==` operators.";

bool _isComparingEquality(TokenType tokenType) =>
    tokenType == TokenType.BANG_EQ || tokenType == TokenType.EQ_EQ;

bool _isComparingParameterWithNull(BinaryExpression node, Element? parameter) =>
    _isComparingEquality(node.operator.type) &&
    ((node.leftOperand.isNullLiteral &&
            _isParameter(node.rightOperand, parameter)) ||
        (node.rightOperand.isNullLiteral &&
            _isParameter(node.leftOperand, parameter)));

bool _isParameter(Expression expression, Element? parameter) =>
    expression.canonicalElement == parameter;

bool _isParameterWithQuestionQuestion(
  BinaryExpression node,
  Element? parameter,
) =>
    node.operator.type == TokenType.QUESTION_QUESTION &&
    _isParameter(node.leftOperand, parameter);

class AvoidNullChecksInEqualityOperators extends LintRule {
  AvoidNullChecksInEqualityOperators()
    : super(
        name: LintNames.avoid_null_checks_in_equality_operators,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidNullChecksInEqualityOperators;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  final Element? parameter;
  final LintRule rule;

  _BodyVisitor(this.parameter, this.rule);

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (_isParameterWithQuestionQuestion(node, parameter) ||
        _isComparingParameterWithNull(node, parameter)) {
      rule.reportAtNode(node);
    }
    super.visitBinaryExpression(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.operator?.type == TokenType.QUESTION_PERIOD &&
        node.target.canonicalElement == parameter) {
      rule.reportAtNode(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (node.operator.type == TokenType.QUESTION_PERIOD &&
        node.target.canonicalElement == parameter) {
      rule.reportAtNode(node);
    }
    super.visitPropertyAccess(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var parameters = node.parameters?.parameters;
    if (parameters == null) {
      return;
    }

    if (node.name.type != TokenType.EQ_EQ || parameters.length != 1) {
      return;
    }

    var parameter = parameters.first.declaredFragment?.element;

    // Analyzer will produce UNNECESSARY_NULL_COMPARISON_FALSE|TRUE
    // See: https://github.com/dart-lang/linter/issues/2864
    if (parameter is FormalParameterElement &&
        parameter.type.nullabilitySuffix != NullabilitySuffix.question) {
      return;
    }

    node.body.accept(_BodyVisitor(parameter, rule));
  }
}
