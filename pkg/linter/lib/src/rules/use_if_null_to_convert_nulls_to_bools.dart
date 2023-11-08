// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Use if-null operators to convert nulls to bools.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#prefer-using--to-convert-null-to-a-boolean-value):

Use if-null operators to convert nulls to bools.

**BAD:**
```dart
if (nullableBool == true) {
}
if (nullableBool != false) {
}
```

**GOOD:**
```dart
if (nullableBool ?? false) {
}
if (nullableBool ?? true) {
}
```

''';

class UseIfNullToConvertNullsToBools extends LintRule {
  static const LintCode code = LintCode('use_if_null_to_convert_nulls_to_bools',
      "Use an if-null operator to convert a 'null' to a 'bool'.",
      correctionMessage: 'Try using an if-null operator.');

  UseIfNullToConvertNullsToBools()
      : super(
          name: 'use_if_null_to_convert_nulls_to_bools',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

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

  bool isNullableBool(DartType? type) =>
      type != null &&
      type.isDartCoreBool &&
      context.typeSystem.isNullable(type);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var type = node.leftOperand.staticType;
    var right = node.rightOperand;
    if (node.operator.type == TokenType.EQ_EQ &&
        isNullableBool(type) &&
        right is BooleanLiteral &&
        right.value) {
      rule.reportLint(node);
    }
    if (node.operator.type == TokenType.BANG_EQ &&
        isNullableBool(type) &&
        right is BooleanLiteral &&
        !right.value) {
      rule.reportLint(node);
    }
  }
}
