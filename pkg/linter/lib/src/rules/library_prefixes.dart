// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../utils.dart';

const _desc =
    r'Use `lowercase_with_underscores` when specifying a library prefix.';

class LibraryPrefixes extends LintRule {
  LibraryPrefixes()
      : super(
          name: LintNames.library_prefixes,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.library_prefixes;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  final LintRule rule;

  _Visitor(this.rule, LinterContext context)
      : _wildCardVariablesEnabled =
            context.isEnabled(Feature.wildcard_variables);

  @override
  void visitImportDirective(ImportDirective node) {
    var prefix = node.prefix;
    if (prefix == null) return;

    var prefixString = prefix.toString();
    // With wildcards, `_` is allowed.
    if (_wildCardVariablesEnabled && prefixString == '_') return;

    if (!isValidLibraryPrefix(prefixString)) {
      rule.reportLint(prefix, arguments: [prefixString]);
    }
  }
}
