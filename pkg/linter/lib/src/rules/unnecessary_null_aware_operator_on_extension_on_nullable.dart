// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc =
    r'Unnecessary null aware operator on extension on a nullable type.';

class UnnecessaryNullAwareOperatorOnExtensionOnNullable extends LintRule {
  UnnecessaryNullAwareOperatorOnExtensionOnNullable()
      : super(
          name: LintNames
              .unnecessary_null_aware_operator_on_extension_on_nullable,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.unnecessary_null_aware_operator_on_extension_on_nullable;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addIndexExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isNullAware &&
        _isExtensionOnNullableType(node.inSetterContext()
            ? node
                .thisOrAncestorOfType<AssignmentExpression>()
                ?.writeElement2
                ?.enclosingElement2
            : node.element?.enclosingElement2)) {
      rule.reportLintForToken(node.question);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.isNullAware &&
        _isExtensionOnNullableType(
            node.methodName.element?.enclosingElement2)) {
      rule.reportLintForToken(node.operator);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.isNullAware) {
      var realParent = node.thisOrAncestorMatching(
          (p) => p != node && p is! ParenthesizedExpression);
      if (_isExtensionOnNullableType(realParent is AssignmentExpression
          ? realParent.writeElement2?.enclosingElement2
          : node.propertyName.element?.enclosingElement2)) {
        rule.reportLintForToken(node.operator);
      }
    }
  }

  bool _isExtensionOnNullableType(Element2? enclosingElement) =>
      enclosingElement is ExtensionElement2 &&
      context.typeSystem.isNullable(enclosingElement.extendedType);
}
