// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
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
import '../utils.dart';

const _desc =
    r'Use `lowercase_with_underscores` when specifying a library prefix.';

class LibraryPrefixes extends AnalysisRule {
  LibraryPrefixes()
    : super(name: LintNames.library_prefixes, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.libraryPrefixes;

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

  final AnalysisRule rule;

  _Visitor(this.rule, RuleContext context)
    : _wildCardVariablesEnabled = context.isFeatureEnabled(
        Feature.wildcard_variables,
      );

  @override
  void visitImportDirective(ImportDirective node) {
    var prefix = node.prefix;
    if (prefix == null) return;

    var prefixString = prefix.toString();
    // With wildcards, `_` is allowed.
    if (_wildCardVariablesEnabled && prefixString == '_') return;

    if (!isValidLibraryPrefix(prefixString)) {
      rule.reportAtNode(prefix, arguments: [prefixString]);
    }
  }
}
