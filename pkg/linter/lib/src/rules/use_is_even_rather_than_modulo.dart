// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer intValue.isOdd/isEven instead of checking the result of % 2.';

class UseIsEvenRatherThanModulo extends LintRule {
  UseIsEvenRatherThanModulo()
    : super(name: LintNames.use_is_even_rather_than_modulo, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.use_is_even_rather_than_modulo;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    // This lint error only happens when the operator is equality.
    if (node.operator.type != TokenType.EQ_EQ) return;
    if (node.inConstantContext) return;

    var left = node.leftOperand;
    var leftType = left.staticType;
    var right = node.rightOperand;
    var rightType = right.staticType;
    // Both sides have to have static type of int
    if (!(right is IntegerLiteral &&
        (leftType?.isDartCoreInt ?? false) &&
        (rightType?.isDartCoreInt ?? false))) {
      return;
    }
    // The left side expression has to be modulo by 2 type.
    if (left is! BinaryExpression) return;
    if (left.operator.type != TokenType.PERCENT) return;

    var rightChild = left.rightOperand;

    if (rightChild is! IntegerLiteral) return;
    if (rightChild.value != 2) return;

    // Now we have `x % 2 == y`.
    var rightChildType = rightChild.staticType;
    if (rightChildType == null) return;
    if (!rightChildType.isDartCoreInt) return;

    var value = right.value;
    if (value == null) return;
    var parentAssertInitializer =
        node.thisOrAncestorOfType<AssertInitializer>();
    if (parentAssertInitializer != null) {
      var constructor = parentAssertInitializer.parent;
      // `isEven` is not allowed in a const constructor assert initializer.
      if (constructor is ConstructorDeclaration &&
          constructor.constKeyword != null) {
        return;
      }
    }

    rule.reportAtNode(node, arguments: [value == 0 ? 'isEven' : 'isOdd']);
  }
}
