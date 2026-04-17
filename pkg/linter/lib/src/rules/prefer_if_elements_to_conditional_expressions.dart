// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Prefer if elements to conditional expressions where possible.';

class PreferIfElementsToConditionalExpressions extends AnalysisRule {
  PreferIfElementsToConditionalExpressions()
    : super(
        name: LintNames.prefer_if_elements_to_conditional_expressions,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      diag.preferIfElementsToConditionalExpressions;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    AstNode errorNode = node;
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      errorNode = parent;
      parent = parent.parent;
    }
    if (_shouldReport(errorNode, parent)) {
      rule.reportAtNode(errorNode);
    }
  }

  bool _shouldReport(AstNode node, AstNode? parent) {
    if (parent is ListLiteral) return true;
    if (parent is SetOrMapLiteral && parent.isSet) return true;
    if (parent is IfElement &&
        (node == parent.thenElement || node == parent.elseElement)) {
      return true;
    }
    if (parent is ForElement && node == parent.body) return true;
    return false;
  }
}
