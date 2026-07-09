// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use a declaring parameter.';

class UseDeclaringParameters extends AnalysisRule {
  new()
    : super(
        name: LintNames.use_declaring_parameters,
        description: _desc,
        state: .stable(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.useDeclaringParameters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.primary_constructors)) return;
    var visitor = _Visitor(this);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  new(this.rule);

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    var body = node.body;
    for (var parameter in node.formalParameters.parameters) {
      if (parameter is FieldFormalParameter) {
        _checkFieldFormalParameter(parameter);
      } else if (parameter is! SuperFormalParameter &&
          parameter.constFinalOrVarKeyword == null) {
        if (body != null) {
          // If there is no body, then the parameter isn't used to initialize
          // a field, so it can't be a declaring parameter.
          _checkNonDeclaringParameter(parameter, body);
        }
      }
    }
  }

  /// Checks whether the given field formal [parameter] should be a declaring
  /// parameter.
  void _checkFieldFormalParameter(FieldFormalParameter parameter) {
    var parameterHasNoType = parameter.type == null;
    var parameterElement = parameter.declaredFragment?.element;
    if (parameterElement is FieldFormalParameterElement) {
      var field = parameterElement.field;
      if (field != null &&
          (parameterHasNoType || field.type == parameterElement.type)) {
        rule.reportAtToken(parameter.name);
      }
    }
  }

  /// Checks whether the given [parameter] should be a declaring parameter.
  ///
  /// Uses the [body] to find an assignment to a parameter.
  void _checkNonDeclaringParameter(
    FormalParameter parameter,
    PrimaryConstructorBody body,
  ) {
    var assignedField = _findAssignedField(parameter, body);
    if (assignedField == null) {
      // If the parameter isn't assigned to a field, then it can't be a
      // declaring parameter.
      return;
    }
    var name = parameter.name;
    if (name != null) {
      var parameterElement = parameter.declaredFragment?.element;
      if (parameterElement != null &&
          assignedField.type == parameterElement.type) {
        rule.reportAtToken(name);
      }
    }
  }

  /// Returns the field that is assigned to the given [parameter] in the given
  /// [body].
  ///
  /// Returns `null` if the [parameter] is not assigned to a field.
  FieldElement? _findAssignedField(
    FormalParameter parameter,
    PrimaryConstructorBody body,
  ) {
    var parameterElement = parameter.declaredFragment?.element;
    if (parameterElement == null) {
      // A parameter without an element can't be identified in an assignment.
      return null;
    }
    for (var initializer in body.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        if (initializer.expression case SimpleIdentifier expression) {
          if (expression.element == parameterElement) {
            if (initializer.fieldName.element case FieldElement fieldElement) {
              if (_namesMatch(parameterElement.name, fieldElement.name)) {
                return fieldElement;
              }
            }
          }
        }
      }
    }
    if (body.body case BlockFunctionBody block) {
      for (var statement in block.block.statements) {
        if (statement is ExpressionStatement) {
          if (statement.expression case AssignmentExpression assignment) {
            if (assignment.rightHandSide
                case SimpleIdentifier rightHandExpression) {
              var rightHandElement = rightHandExpression.element;
              if (rightHandElement == parameterElement) {
                if (assignment.writeElement case SetterElement setterElement) {
                  if (setterElement.variable case FieldElement fieldElement) {
                    if (_namesMatch(parameterElement.name, fieldElement.name)) {
                      return fieldElement;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  /// Returns `true` if the [parameterName] and [fieldName] are the same, modulo
  /// a leading underscore.
  bool _namesMatch(String? parameterName, String? fieldName) {
    if (parameterName == null || fieldName == null) {
      return false;
    } else if (parameterName == fieldName) {
      return true;
    } else if (parameterName.startsWith('_')) {
      return parameterName.substring(1) == fieldName;
    } else if (fieldName.startsWith('_')) {
      return parameterName == fieldName.substring(1);
    }
    return false;
  }
}
