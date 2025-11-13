// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r"Don't use explicit `break`s when a break is implied.";

class UnnecessaryBreaks extends AnalysisRule {
  UnnecessaryBreaks()
    : super(name: LintNames.unnecessary_breaks, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryBreaks;

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
  final AnalysisRule rule;

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
