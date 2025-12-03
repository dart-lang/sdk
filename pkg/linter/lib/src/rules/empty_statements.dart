// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
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

const _desc = r'Avoid empty statements.';

class EmptyStatements extends AnalysisRule {
  EmptyStatements()
    : super(name: LintNames.empty_statements, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.emptyStatements;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addEmptyStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  bool definesSemantics(EmptyStatement node) {
    var parent = node.parent;
    if (parent is! SwitchPatternCase) return false;

    var statements = parent.statements;
    if (statements.last != node) return false;

    for (var statement in statements) {
      if (statement is! EmptyStatement) return false;
    }

    return true;
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    if (definesSemantics(node)) return;
    rule.reportAtNode(node);
  }
}
