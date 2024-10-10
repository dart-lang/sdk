// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Use `??` operators to convert `null`s to `bool`s.';

class UseIfNullToConvertNullsToBools extends LintRule {
  UseIfNullToConvertNullsToBools()
      : super(
          name: LintNames.use_if_null_to_convert_nulls_to_bools,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_if_null_to_convert_nulls_to_bools;

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
