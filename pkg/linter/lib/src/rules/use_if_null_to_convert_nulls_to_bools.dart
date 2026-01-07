// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use `??` operators to convert `null`s to `bool`s.';

class UseIfNullToConvertNullsToBools extends AnalysisRule {
  UseIfNullToConvertNullsToBools()
    : super(
        name: LintNames.use_if_null_to_convert_nulls_to_bools,
        description: _desc,
        state: RuleState.deprecated(since: Version(3, 11, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.useIfNullToConvertNullsToBools;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

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
      rule.reportAtNode(node);
    }
    if (node.operator.type == TokenType.BANG_EQ &&
        isNullableBool(type) &&
        right is BooleanLiteral &&
        !right.value) {
      rule.reportAtNode(node);
    }
  }
}
