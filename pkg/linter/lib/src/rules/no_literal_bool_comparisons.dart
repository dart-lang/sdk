// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r"Don't compare booleans to boolean literals.";

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#dont-use-true-or-false-in-equality-operations):

**DON'T** use `true` or `false` in equality operations.

This lint applies only if the expression is of a non-nullable `bool` type.

**BAD:**
```dart
if (someBool == true) {
}
while (someBool == false) {
}
```

**GOOD:**
```dart
if (someBool) {
}
while (!someBool) {
}
```
''';

class NoLiteralBoolComparisons extends LintRule {
  NoLiteralBoolComparisons()
      : super(
          name: 'no_literal_bool_comparisons',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.non_nullable)) return;

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
