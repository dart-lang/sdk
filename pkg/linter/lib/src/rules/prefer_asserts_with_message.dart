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

const _desc = r'Prefer asserts with message.';

class PreferAssertsWithMessage extends AnalysisRule {
  PreferAssertsWithMessage()
    : super(name: LintNames.prefer_asserts_with_message, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferAssertsWithMessage;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addAssertInitializer(this, visitor);
    registry.addAssertStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitAssertInitializer(AssertInitializer node) {
    if (node.message == null) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (node.message == null) {
      rule.reportAtNode(node);
    }
  }
}
