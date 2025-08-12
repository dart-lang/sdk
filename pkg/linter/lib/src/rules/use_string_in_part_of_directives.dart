// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Use string in part of directives.';

class UseStringInPartOfDirectives extends LintRule {
  UseStringInPartOfDirectives()
    : super(
        name: LintNames.use_string_in_part_of_directives,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.use_string_in_part_of_directives;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.hasEnancedPartsFeatureEnabled) {
      var visitor = _Visitor(this);
      registry.addPartOfDirective(this, visitor);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitPartOfDirective(PartOfDirective node) {
    if (node.libraryName != null) {
      rule.reportAtNode(node);
    }
  }
}

extension on RuleContext {
  bool get hasEnancedPartsFeatureEnabled =>
      isFeatureEnabled(Feature.enhanced_parts);
}
