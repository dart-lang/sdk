// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r"Don't compare boolean expressions to boolean literals.";

class NoLiteralBoolComparisons extends AnalysisRule {
  NoLiteralBoolComparisons()
    : super(name: LintNames.no_literal_bool_comparisons, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.noLiteralBoolComparisons;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addBinaryExpression(this, visitor);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  bool isBool(DartType? type) =>
      type != null &&
      type.isDartCoreBool &&
      context.typeSystem.isNonNullable(type);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type
        case TokenType.EQ_EQ ||
            TokenType.BANG_EQ ||
            TokenType.BAR ||
            TokenType.BAR_BAR ||
            TokenType.AMPERSAND ||
            TokenType.AMPERSAND_AMPERSAND ||
            TokenType.CARET) {
      var left = node.leftOperand;
      var right = node.rightOperand;
      if (right is BooleanLiteral && isBool(left.staticType)) {
        rule.reportAtNode(right);
      } else if (left is BooleanLiteral && isBool(right.staticType)) {
        rule.reportAtNode(left);
      }
    }
  }
}
