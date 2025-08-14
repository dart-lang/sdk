// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoBoolsRule extends AnalysisRule {
  static const LintCode code = LintCode('no_bools', 'No bools message');

  NoBoolsRule() : super(name: 'no_bools', description: 'No bools desc');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
      RuleVisitorRegistry registry, RuleContext context) {
    var visitor = _NoBoolsVisitor(this);
    registry.addBooleanLiteral(this, visitor);
  }
}

class NoDoublesRule extends AnalysisRule {
  static const LintCode code = LintCode('no_doubles', 'No doubles message');

  NoDoublesRule()
      : super(name: 'no_doubles', description: 'No doubles message');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
      RuleVisitorRegistry registry, RuleContext context) {
    var visitor = _NoDoublesVisitor(this);
    registry.addDoubleLiteral(this, visitor);
  }
}

class NoDoublesWarningRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_doubles_warning',
    'No doubles message',
    severity: DiagnosticSeverity.WARNING,
  );

  NoDoublesWarningRule()
      : super(name: 'no_doubles_warning', description: 'No doubles message');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
      RuleVisitorRegistry registry, RuleContext context) {
    var visitor = _NoDoublesVisitor(this);
    registry.addDoubleLiteral(this, visitor);
  }
}

class _NoBoolsVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoBoolsVisitor(this.rule);

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    rule.reportAtNode(node);
  }
}

class _NoDoublesVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoDoublesVisitor(this.rule);

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    rule.reportAtNode(node);
  }
}
