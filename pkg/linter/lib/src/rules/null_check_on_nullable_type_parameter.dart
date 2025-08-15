// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import 'unnecessary_null_checks.dart';

const _desc =
    r"Don't use `null` check on a potentially nullable type parameter.";

class NullCheckOnNullableTypeParameter extends LintRule {
  NullCheckOnNullableTypeParameter()
    : super(
        name: LintNames.null_check_on_nullable_type_parameter,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.nullCheckOnNullableTypeParameter;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addPostfixExpression(this, visitor);
    registry.addNullAssertPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final RuleContext context;
  _Visitor(this.rule, this.context);

  bool isNullableTypeParameterType(DartType? type) =>
      type is TypeParameterType && context.typeSystem.isNullable(type);

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    if (isNullableTypeParameterType(node.matchedValueType)) {
      rule.reportAtToken(node.operator);
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    var expectedType = getExpectedType(node);
    var type = node.operand.staticType;
    if (isNullableTypeParameterType(type) &&
        expectedType != null &&
        context.typeSystem.isPotentiallyNullable(expectedType) &&
        context.typeSystem.promoteToNonNull(type!) ==
            context.typeSystem.promoteToNonNull(expectedType)) {
      rule.reportAtToken(node.operator);
    }
  }
}
