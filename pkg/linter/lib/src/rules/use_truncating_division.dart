// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
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

const _desc = r'Use truncating division.';

class UseTruncatingDivision extends AnalysisRule {
  UseTruncatingDivision()
    : super(name: LintNames.use_truncating_division, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.useTruncatingDivision;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type != TokenType.SLASH) return;

    // Return if the two operands are not each `int`.
    var leftType = node.leftOperand.staticType;
    if (leftType == null || !leftType.isDartCoreInt) return;

    var rightType = node.rightOperand.staticType;
    if (rightType == null || !rightType.isDartCoreInt) return;

    // Return if the '/' operator is not defined in core, or if we don't know
    // its static type.
    var methodElement = node.element;
    if (methodElement == null) return;

    var libraryElement = methodElement.library;
    if (!libraryElement.isDartCore) return;

    var parent = node.parent;
    if (parent is! ParenthesizedExpression) return;

    var outermostParentheses =
        parent.thisOrAncestorMatching(
              (e) => e.parent is! ParenthesizedExpression,
            )!
            as ParenthesizedExpression;
    var grandParent = outermostParentheses.parent;
    if (grandParent is MethodInvocation &&
        grandParent.methodName.name == 'toInt' &&
        grandParent.argumentList.arguments.isEmpty) {
      rule.reportAtNode(grandParent);
    }
  }
}
