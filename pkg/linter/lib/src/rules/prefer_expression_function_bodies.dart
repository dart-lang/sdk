// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc =
    r'Use => for short members whose body is a single return statement.';

class PreferExpressionFunctionBodies extends AnalysisRule {
  PreferExpressionFunctionBodies()
    : super(
        name: LintNames.prefer_expression_function_bodies,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.preferExpressionFunctionBodies;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addBlockFunctionBody(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    var statements = node.block.statements;
    if (statements.length != 1) return;

    var uniqueStatement = node.block.statements.single;
    if (uniqueStatement is! ReturnStatement) return;
    if (uniqueStatement.expression == null) return;

    rule.reportAtNode(node);
  }
}
