// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r"Don't use explicit `break`s when a break is implied.";

class UnnecessaryBreaks extends LintRule {
  UnnecessaryBreaks()
    : super(name: LintNames.unnecessary_breaks, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.unnecessary_breaks;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.patterns)) return;

    var visitor = _Visitor(this);
    registry.addBreakStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitBreakStatement(BreakStatement node) {
    if (node.label != null) return;
    var parent = node.parent;
    if (parent is SwitchMember) {
      var statements = parent.statements;
      if (statements.length == 1) return;
      if (node == statements.last) {
        rule.reportAtNode(node);
      }
    }
  }
}
