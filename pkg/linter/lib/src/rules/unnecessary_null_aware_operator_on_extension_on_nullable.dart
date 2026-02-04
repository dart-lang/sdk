// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc =
    r'Unnecessary null aware operator on extension on a nullable type.';

class UnnecessaryNullAwareOperatorOnExtensionOnNullable extends AnalysisRule {
  UnnecessaryNullAwareOperatorOnExtensionOnNullable()
    : super(
        name:
            LintNames.unnecessary_null_aware_operator_on_extension_on_nullable,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      diag.unnecessaryNullAwareOperatorOnExtensionOnNullable;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addIndexExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitIndexExpression(IndexExpression node) {
    var question = node.question;
    if (question == null) return;
    if (node.isNullAware &&
        _isExtensionOnNullableType(
          node.inSetterContext()
              ? node
                    .thisOrAncestorOfType<AssignmentExpression>()
                    ?.writeElement
                    ?.enclosingElement
              : node.element?.enclosingElement,
        )) {
      rule.reportAtToken(question);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var operator = node.operator;
    if (operator == null) return;
    if (node.isNullAware &&
        _isExtensionOnNullableType(node.methodName.element?.enclosingElement)) {
      rule.reportAtToken(operator);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.isNullAware) {
      var realParent = node.thisOrAncestorMatching(
        (p) => p != node && p is! ParenthesizedExpression,
      );
      if (_isExtensionOnNullableType(
        realParent is AssignmentExpression
            ? realParent.writeElement?.enclosingElement
            : node.propertyName.element?.enclosingElement,
      )) {
        rule.reportAtToken(node.operator);
      }
    }
  }

  bool _isExtensionOnNullableType(Element? enclosingElement) =>
      enclosingElement is ExtensionElement &&
      context.typeSystem.isNullable(enclosingElement.extendedType);
}
