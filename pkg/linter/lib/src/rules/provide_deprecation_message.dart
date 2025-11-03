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

const _desc = r'Provide a deprecation message, via `@Deprecated("message")`.';

class ProvideDeprecationMessage extends AnalysisRule {
  ProvideDeprecationMessage()
    : super(name: LintNames.provide_deprecation_message, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.provideDeprecationMessage;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addAnnotation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitAnnotation(Annotation node) {
    var elementAnnotation = node.elementAnnotation;
    if (elementAnnotation != null &&
        elementAnnotation.isDeprecated &&
        node.arguments == null) {
      rule.reportAtNode(node);
    }
  }
}
