// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Tighten type of initializing formal.';

class TightenTypeOfInitializingFormals extends AnalysisRule {
  TightenTypeOfInitializingFormals()
    : super(
        name: LintNames.tighten_type_of_initializing_formals,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.tightenTypeOfInitializingFormals;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkConstructor(
      parameters: node.parameters.parameters,
      initializers: node.initializers,
    );
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    if (node.body?.initializers case var initializers?) {
      _checkConstructor(
        parameters: node.formalParameters.parameters,
        initializers: initializers,
      );
    }
  }

  void _check(Element? element, List<FormalParameter> parameters) {
    if ((element is FieldFormalParameterElement && !element.isDeclaring) ||
        element is SuperFormalParameterElement) {
      rule.reportAtNode(
        parameters.firstWhere((p) => p.declaredFragment?.element == element),
      );
    }
  }

  void _checkConstructor({
    required List<FormalParameter> parameters,
    required List<ConstructorInitializer> initializers,
  }) {
    for (var initializer in initializers) {
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
              _check(leftOperand.element, parameters);
            }
          }
        } else if (condition.leftOperand is NullLiteral) {
          var rightOperand = condition.rightOperand;
          if (rightOperand is Identifier) {
            var staticType = rightOperand.staticType;
            if (staticType != null &&
                context.typeSystem.isNullable(staticType)) {
              _check(rightOperand.element, parameters);
            }
          }
        }
      }
    }
  }
}
