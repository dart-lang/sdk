// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r"Don't declare multiple variables on a single line.";

class AvoidMultipleDeclarationsPerLine extends LintRule {
  AvoidMultipleDeclarationsPerLine()
    : super(
        name: LintNames.avoid_multiple_declarations_per_line,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoid_multiple_declarations_per_line;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    var parent = node.parent;
    if (parent is ForPartsWithDeclarations && parent.variables == node) return;

    var variables = node.variables;
    if (variables.length > 1) {
      var secondVariable = variables[1];
      rule.reportAtToken(secondVariable.name);
    }
  }
}
