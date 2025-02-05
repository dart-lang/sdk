// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't use constant patterns with type literals.";

class TypeLiteralInConstantPattern extends LintRule {
  TypeLiteralInConstantPattern()
      : super(
          name: LintNames.type_literal_in_constant_pattern,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.type_literal_in_constant_pattern;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstantPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  visitConstantPattern(ConstantPattern node) {
    // `const (MyType)` is fine.
    if (node.constKeyword != null) {
      return;
    }

    var expressionType = node.expression.staticType;
    if (expressionType != null && expressionType.isDartCoreType) {
      rule.reportLint(node);
    }
  }
}
