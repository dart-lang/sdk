// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r"Don't cast a nullable value to a non nullable type.";

class CastNullableToNonNullable extends LintRule {
  CastNullableToNonNullable()
      : super(
          name: LintNames.cast_nullable_to_non_nullable,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.cast_nullable_to_non_nullable;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitAsExpression(AsExpression node) {
    var expressionType = node.expression.staticType;
    var type = node.type.type;
    if (expressionType is! DynamicType &&
        expressionType is! InvalidType &&
        expressionType != null &&
        context.typeSystem.isNullable(expressionType) &&
        type != null &&
        context.typeSystem.isNonNullable(type)) {
      rule.reportLint(node);
    }
  }
}
