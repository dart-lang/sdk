// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Use a setter for operations that conceptually change a property.';

class UseSettersToChangeProperties extends LintRule {
  UseSettersToChangeProperties()
    : super(
        name: LintNames.use_setters_to_change_properties,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.useSettersToChangeProperties;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isSetter ||
        node.isGetter ||
        node.isOverride ||
        node.parameters?.parameters.length != 1 ||
        node.returnType?.type is! VoidType) {
      return;
    }

    void checkExpression(Expression expression) {
      if (expression is AssignmentExpression &&
          expression.operator.type == TokenType.EQ) {
        var leftOperand = expression.writeElement?.canonicalElement2;
        var rightOperand = expression.rightHandSide.canonicalElement;
        var parameterElement =
            node.declaredFragment?.element.formalParameters.first;
        if (rightOperand == parameterElement && leftOperand is FieldElement) {
          rule.reportAtToken(node.name);
        }
      }
    }

    var body = node.body;
    if (body is BlockFunctionBody) {
      if (body.block.statements.length == 1) {
        var statement = body.block.statements.first;
        if (statement is ExpressionStatement) {
          checkExpression(statement.expression);
        }
      }
    } else if (body is ExpressionFunctionBody) {
      checkExpression(body.expression);
    }
  }
}
