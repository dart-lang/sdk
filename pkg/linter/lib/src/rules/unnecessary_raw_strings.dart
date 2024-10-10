// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary raw string.';

class UnnecessaryRawStrings extends LintRule {
  UnnecessaryRawStrings()
      : super(
          name: LintNames.unnecessary_raw_strings,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_raw_strings;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSimpleStringLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isRaw && ![r'\', r'$'].any(node.literal.lexeme.contains)) {
      rule.reportLint(node);
    }
  }
}
