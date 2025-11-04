// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NeedsPackageRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'needs_package',
    'Needs Package at {0}',
    uniqueName: 'LintCode.needs_package',
  );

  NeedsPackageRule()
    : super(name: 'needs_package', description: 'This rule needs package info');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.isInLibDir) {
      var visitor = _NeedsPackageVisitor(this, context);
      registry.addIntegerLiteral(this, visitor);
    }
  }
}

class NoBoolsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_bools',
    'No bools message',
    uniqueName: 'LintCode.no_bools',
  );

  NoBoolsRule() : super(name: 'no_bools', description: 'No bools desc');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoBoolsVisitor(this);
    registry.addBooleanLiteral(this, visitor);
  }
}

class NoDoublesCustomSeverityRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_doubles_custom_severity',
    'No doubles message',
    severity: DiagnosticSeverity.WARNING,
    uniqueName: 'LintCode.no_doubles_custom_severity',
  );

  NoDoublesCustomSeverityRule()
    : super(
        name: 'no_doubles_custom_severity',
        description: 'No doubles message',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoDoublesVisitor(this);
    registry.addDoubleLiteral(this, visitor);
  }
}

class NoDoublesRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_doubles',
    'No doubles message',
    uniqueName: 'LintCode.no_doubles',
  );

  NoDoublesRule()
    : super(name: 'no_doubles', description: 'No doubles message');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoDoublesVisitor(this);
    registry.addDoubleLiteral(this, visitor);
  }
}

class NoReferencesToStringsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_references_to_strings',
    'No references to Strings',
    uniqueName: 'LintCode.no_references_to_strings',
  );

  NoReferencesToStringsRule()
    : super(
        name: 'no_references_to_strings',
        description: 'No references to Strings',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoReferencesToStringsVisitor(this, context);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _NeedsPackageVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _NeedsPackageVisitor(this.rule, this.context);

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    rule.reportAtNode(node, arguments: ['"${context.package!.root.path}"']);
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

class _NoReferencesToStringsVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _NoReferencesToStringsVisitor(this.rule, this.context);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticType?.isDartCoreString ?? false) {
      rule.reportAtNode(node);
    }
  }
}
