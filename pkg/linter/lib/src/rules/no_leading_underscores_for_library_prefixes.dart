// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid leading underscores for library prefixes.';

class NoLeadingUnderscoresForLibraryPrefixes extends LintRule {
  NoLeadingUnderscoresForLibraryPrefixes()
    : super(
        name: LintNames.no_leading_underscores_for_library_prefixes,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.no_leading_underscores_for_library_prefixes;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final LintRule rule;

  _Visitor(this.rule, RuleContext context)
    : _wildCardVariablesEnabled = context.isFeatureEnabled(
        Feature.wildcard_variables,
      );

  void checkIdentifier(SimpleIdentifier? id) {
    if (id == null) return;

    var name = id.name;

    if (_wildCardVariablesEnabled && name == '_') return;

    if (name.hasLeadingUnderscore) {
      rule.reportAtNode(id, arguments: [id.name]);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    checkIdentifier(node.prefix);
  }
}
