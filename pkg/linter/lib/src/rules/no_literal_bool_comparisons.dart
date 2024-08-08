// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r"Don't compare boolean expressions to boolean literals.";

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#dont-use-true-or-false-in-equality-operations):

**DON'T** use `true` or `false` in equality operations.

This lint applies only if the expression is of a non-nullable `bool` type.

**BAD:**
```dart
if (someBool == true) {
  print('true!');
}
while (someBool == false) {
  print('still false!');
}
```

**GOOD:**
```dart
if (someBool) {
  print('true!');
}
while (!someBool) {
  print('still false!');
}
```
''';

class NoLiteralBoolComparisons extends LintRule {
  NoLiteralBoolComparisons()
      : super(
          name: 'no_literal_bool_comparisons',
          description: _desc,
          details: _details,
          categories: {LintRuleCategory.effectiveDart, LintRuleCategory.style},
        );

  @override
  LintCode get lintCode => LinterLintCode.no_literal_bool_comparisons;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  bool isBool(DartType? type) =>
      type != null &&
      type.isDartCoreBool &&
      context.typeSystem.isNonNullable(type);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.EQ_EQ ||
        node.operator.type == TokenType.BANG_EQ) {
      var left = node.leftOperand;
      var right = node.rightOperand;
      if (right is BooleanLiteral && isBool(left.staticType)) {
        rule.reportLint(right);
      } else if (left is BooleanLiteral && isBool(right.staticType)) {
        rule.reportLint(left);
      }
    }
  }
}
