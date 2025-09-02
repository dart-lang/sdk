// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid empty statements in else clauses.';

class AvoidEmptyElse extends LintRule {
  AvoidEmptyElse()
    : super(name: LintNames.avoid_empty_else, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.avoidEmptyElse;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    var elseStatement = node.elseStatement;
    if (elseStatement is EmptyStatement &&
        !elseStatement.semicolon.isSynthetic) {
      rule.reportAtNode(elseStatement);
    }
  }
}
