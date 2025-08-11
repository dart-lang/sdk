// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r"Don't cast a nullable value to a non nullable type.";

class CastNullableToNonNullable extends LintRule {
  CastNullableToNonNullable()
    : super(name: LintNames.cast_nullable_to_non_nullable, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.cast_nullable_to_non_nullable;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final RuleContext context;
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
      rule.reportAtNode(node);
    }
  }
}
