// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use initializing formals when possible.';

Iterable<AssignmentExpression> _getAssignmentExpressionsInConstructorBody(
  ConstructorDeclaration node,
) {
  var body = node.body;
  if (body is! BlockFunctionBody) return [];
  var assignments = <AssignmentExpression>[];
  for (var statement in body.block.statements) {
    if (statement is ExpressionStatement) {
      var expression = statement.expression;
      if (expression is AssignmentExpression) {
        assignments.add(expression);
      }
    }
  }
  return assignments;
}

Iterable<ConstructorFieldInitializer>
_getConstructorFieldInitializersInInitializers(ConstructorDeclaration node) =>
    node.initializers.whereType<ConstructorFieldInitializer>();

Element? _getLeftElement(AssignmentExpression assignment) =>
    assignment.writeElement?.canonicalElement2;

Iterable<FormalParameterElement?> _getParameters(ConstructorDeclaration node) =>
    node.parameters.parameters.map((e) => e.declaredFragment?.element);

Element? _getRightElement(AssignmentExpression assignment) =>
    assignment.rightHandSide.canonicalElement;

class PreferInitializingFormals extends LintRule {
  PreferInitializingFormals()
    : super(name: LintNames.prefer_initializing_formals, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.prefer_initializing_formals;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Skip factory constructors.
    // https://github.com/dart-lang/linter/issues/2441
    if (node.factoryKeyword != null) {
      return;
    }

    var parameters = _getParameters(node);
    var parametersUsedOnce = <Element?>{};
    var parametersUsedMoreThanOnce = <Element?>{};

    bool isAssignmentExpressionToLint(AssignmentExpression assignment) {
      var leftElement = _getLeftElement(assignment);
      var rightElement = _getRightElement(assignment);
      return leftElement != null &&
          rightElement != null &&
          leftElement.name == rightElement.name &&
          !leftElement.isPrivate &&
          leftElement is FieldElement &&
          !leftElement.isSynthetic &&
          leftElement.enclosingElement ==
              node.declaredFragment?.element.enclosingElement &&
          parameters.contains(rightElement) &&
          (!parametersUsedMoreThanOnce.contains(rightElement) &&
                  !(rightElement as FormalParameterElement).isNamed ||
              leftElement.name == rightElement.name);
    }

    bool isConstructorFieldInitializerToLint(
      ConstructorFieldInitializer constructorFieldInitializer,
    ) {
      var expression = constructorFieldInitializer.expression;
      if (expression is SimpleIdentifier) {
        var fieldName = constructorFieldInitializer.fieldName;
        if (fieldName.name != expression.name) {
          return false;
        }
        var staticElement = expression.element;
        return staticElement is FormalParameterElement &&
            !(constructorFieldInitializer.fieldName.element?.isPrivate ??
                true) &&
            parameters.contains(staticElement) &&
            (!parametersUsedMoreThanOnce.contains(expression.element) &&
                    !staticElement.isNamed ||
                (constructorFieldInitializer.fieldName.element?.name ==
                    expression.element?.name));
      }
      return false;
    }

    void processElement(Element? element) {
      if (!parametersUsedOnce.add(element)) {
        parametersUsedMoreThanOnce.add(element);
      }
    }

    for (var parameterFragment in node.parameters.parameterFragments) {
      if (parameterFragment == null) continue;

      var parameter = parameterFragment.element;
      if (parameter.isInitializingFormal) {
        processElement(parameter);
      }
    }

    var assignments = _getAssignmentExpressionsInConstructorBody(node);
    for (var assignment in assignments) {
      if (isAssignmentExpressionToLint(assignment)) {
        processElement(_getRightElement(assignment));
      }
    }

    var initializers = _getConstructorFieldInitializersInInitializers(node);
    for (var initializer in initializers) {
      if (isConstructorFieldInitializerToLint(initializer)) {
        processElement((initializer.expression as SimpleIdentifier).element);
      }
    }

    for (var assignment in assignments) {
      if (isAssignmentExpressionToLint(assignment)) {
        var rightElement = _getRightElement(assignment)!;
        rule.reportAtNode(assignment, arguments: [rightElement.displayName]);
      }
    }

    for (var initializer in initializers) {
      if (isConstructorFieldInitializerToLint(initializer)) {
        var name = initializer.fieldName.element!.name!;
        rule.reportAtNode(initializer, arguments: [name]);
      }
    }
  }
}
