// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Noop primitive operations.';

class NoopPrimitiveOperations extends LintRule {
  NoopPrimitiveOperations()
    : super(name: LintNames.noop_primitive_operations, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.noopPrimitiveOperations;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addAdjacentStrings(this, visitor);
    registry.addInterpolationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final RuleContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // We allow empty string literals at the beginning or end of a string:
    // https://github.com/dart-lang/sdk/issues/55541#issuecomment-2073437613
    for (var i = 1; i < node.strings.length - 1; i++) {
      var literal = node.strings[i];
      if (literal.stringValue?.isEmpty ?? false) {
        rule.reportAtNode(literal);
      }
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _checkToStringInvocation(node.expression);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var type = node.realTarget?.staticType;
    if (type == null) {
      // print(xxx.toString())
      if (node.methodName.element.isDartCorePrint &&
          node.argumentList.arguments.length == 1) {
        _checkToStringInvocation(node.argumentList.arguments.first);
      }
      return;
    }

    // string.toString()
    if (type.isDartCoreString &&
        node.methodName.name == 'toString' &&
        context.typeSystem.isNonNullable(type)) {
      rule.reportAtNode(node.methodName);
      return;
    }

    // int invariant methods
    if (type.isDartCoreInt &&
        [
          'toInt',
          'round',
          'ceil',
          'floor',
          'truncate',
        ].contains(node.methodName.name)) {
      rule.reportAtNode(node.methodName);
      return;
    }

    // double.toDouble()
    if (type.isDartCoreDouble && node.methodName.name == 'toDouble') {
      rule.reportAtNode(node.methodName);
      return;
    }
  }

  void _checkToStringInvocation(Expression expression) {
    if (expression is MethodInvocation &&
        expression.realTarget != null &&
        expression.realTarget is! SuperExpression &&
        expression.methodName.name == 'toString' &&
        expression.argumentList.arguments.isEmpty) {
      rule.reportAtNode(expression.methodName);
    }
  }
}
