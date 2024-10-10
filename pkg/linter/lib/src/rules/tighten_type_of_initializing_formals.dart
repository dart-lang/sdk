// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc = r'Tighten type of initializing formal.';

class TightenTypeOfInitializingFormals extends LintRule {
  TightenTypeOfInitializingFormals()
      : super(
          name: LintNames.tighten_type_of_initializing_formals,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.tighten_type_of_initializing_formals;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    for (var initializer in node.initializers) {
      if (initializer is! AssertInitializer) continue;

      var condition = initializer.condition;
      if (condition is! BinaryExpression) continue;

      if (condition.operator.type == TokenType.BANG_EQ) {
        if (condition.rightOperand is NullLiteral) {
          var leftOperand = condition.leftOperand;
          if (leftOperand is Identifier) {
            var staticType = leftOperand.staticType;
            if (staticType != null &&
                context.typeSystem.isNullable(staticType)) {
              _check(leftOperand.element, node);
            }
          }
        } else if (condition.leftOperand is NullLiteral) {
          var rightOperand = condition.rightOperand;
          if (rightOperand is Identifier) {
            var staticType = rightOperand.staticType;
            if (staticType != null &&
                context.typeSystem.isNullable(staticType)) {
              _check(rightOperand.element, node);
            }
          }
        }
      }
    }
  }

  void _check(Element2? element, ConstructorDeclaration node) {
    if (element is FieldFormalParameterElement2 ||
        element is SuperFormalParameterElement2) {
      rule.reportLint(node.parameters.parameters
          .firstWhere((p) => p.declaredFragment?.element == element));
    }
  }
}
