// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/lint/linter.dart'; //ignore: implementation_imports

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use string in part of directives.';

class UseStringInPartOfDirectives extends LintRule {
  UseStringInPartOfDirectives()
      : super(
          name: LintNames.use_string_in_part_of_directives,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_string_in_part_of_directives;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
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
      rule.reportLint(node);
    }
  }
}

extension on LinterContext {
  bool get hasEnancedPartsFeatureEnabled =>
      this is LinterContextWithResolvedResults &&
      isEnabled(Feature.enhanced_parts);
}
