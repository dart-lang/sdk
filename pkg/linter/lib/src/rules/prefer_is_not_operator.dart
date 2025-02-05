// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer is! operator.';

class PreferIsNotOperator extends LintRule {
  PreferIsNotOperator()
      : super(
          name: LintNames.prefer_is_not_operator,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_is_not_operator;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addIsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitIsExpression(IsExpression node) {
    // Return if it is `is!` expression
    if (node.notOperator != null) {
      return;
    }

    var parent = node.parent;
    // Check whether is expression is inside parenthesis
    if (parent is ParenthesizedExpression) {
      var prefixExpression = parent.parent;
      // Check for NOT (!) operator
      if (prefixExpression is PrefixExpression &&
          prefixExpression.operator.type == TokenType.BANG) {
        rule.reportLint(prefixExpression);
      }
    }
  }
}
