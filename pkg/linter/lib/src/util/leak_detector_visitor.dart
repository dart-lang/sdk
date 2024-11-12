// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';

import '../analyzer.dart';
import '../ast.dart';

/// Builds a function that reports a variable node if none of the [predicates]
/// return `true` for any node inside the [container] node.
_VisitVariableDeclaration _buildVariableReporter(
  AstNode container,
  LintRule rule,
  Map<DartTypePredicate, String> predicates, {
  required _VariableType variableType,
}) =>
    (VariableDeclaration variable) {
      if (variable.equals != null && variable.initializer is SimpleIdentifier) {
        return;
      }

      var variableElement = variable.declaredFragment?.element;
      if (variableElement == null) {
        return;
      }

      if (!predicates.keys
          .any((DartTypePredicate p) => p(variableElement.type))) {
        return;
      }

      var visitor = _ValidUseVisitor(
        variable,
        variableElement,
        predicates,
        variableType: variableType,
      );
      container.accept(visitor);

      if (visitor.containsValidUse) {
        return;
      }

      rule.reportLint(variable);
    };

/// Whether any of the [predicates] applies to [methodName] and holds true for
/// [type].
bool _hasMatch(Map<DartTypePredicate, String> predicates, DartType type,
        String methodName) =>
    predicates.keys.any((p) => predicates[p] == methodName && p(type));

bool _isElementEqualToVariable(
        Element2? propertyElement, VariableElement2? variableElement) =>
    propertyElement == variableElement ||
    propertyElement.matches(variableElement);

bool _isInvocationThroughCascadeExpression(
    MethodInvocation invocation, VariableElement2 variableElement) {
  if (invocation.realTarget is! SimpleIdentifier) {
    return false;
  }

  var identifier = invocation.realTarget;
  if (identifier is SimpleIdentifier) {
    return identifier.element.matches(variableElement);
  }
  return false;
}

bool _isPostfixExpressionOperandEqualToVariable(
    AstNode? n, VariableElement2 variableElement) {
  if (n is PostfixExpression) {
    var operand = n.operand;
    return operand is SimpleIdentifier &&
        _isElementEqualToVariable(operand.element, variableElement);
  }
  return false;
}

bool _isPropertyAccessThroughThis(
    Expression? n, VariableElement2 variableElement) {
  if (n is! PropertyAccess) {
    return false;
  }

  var target = n.realTarget;
  if (target is! ThisExpression) {
    return false;
  }

  var propertyElement = n.propertyName.element;
  return _isElementEqualToVariable(propertyElement, variableElement);
}

bool _isSimpleIdentifierElementEqualToVariable(
        AstNode? n, VariableElement2 variableElement) =>
    n is SimpleIdentifier &&
    _isElementEqualToVariable(n.element, variableElement);

typedef DartTypePredicate = bool Function(DartType type);

typedef _VisitVariableDeclaration = void Function(VariableDeclaration node);

abstract class LeakDetectorProcessors extends SimpleAstVisitor<void> {
  final LintRule rule;

  LeakDetectorProcessors(this.rule);

  @protected
  Map<DartTypePredicate, String> get predicates;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    var unit = getCompilationUnit(node);
    if (unit != null) {
      // When visiting a field declaration, we want to check tree under the
      // containing unit for ConstructorFieldInitializers and FieldFormalParameters.
      node.fields.variables.forEach(_buildVariableReporter(
        unit,
        rule,
        predicates,
        variableType: _VariableType.field,
      ));
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function != null) {
      // When visiting a variable declaration, we want to check tree under the
      // containing function for ReturnStatements. If an interesting variable
      // is returned, don't report it.
      node.variables.variables.forEach(_buildVariableReporter(
        function,
        rule,
        predicates,
        variableType: _VariableType.local,
      ));
    }
  }
}

/// A visitor that tracks _any_ valid use of [variable].
///
/// A valid use may calling a method or tearing off a method on [variable] as
/// per [predicates].
///
/// A valid use may also just be the variable "escaping" the scope, for example,
/// being returned by a function, or being passed as an argument to a function.
class _ValidUseVisitor extends RecursiveAstVisitor<void> {
  /// The variable under consideration.
  final VariableDeclaration variable;

  /// The element of the variable under consideration; stored here as a non-
  /// `null` value.
  final VariableElement2 variableElement;

  /// The predicates that determine whether a method call or method tear-off is
  /// a valid use.
  final Map<DartTypePredicate, String> predicates;

  /// The type of variable, which determines a few specifics about variable
  /// use.
  final _VariableType variableType;

  /// Whether the node tree, after being visited, was determined to contain a
  /// valid use.
  var containsValidUse = false;

  _ValidUseVisitor(
    this.variable,
    this.variableElement,
    this.predicates, {
    required this.variableType,
  });

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // Being assigned another reference.
    if (node.rightHandSide is SimpleIdentifier) {
      if (_isElementEqualToVariable(
          node.writeElement2, variable.declaredFragment?.element)) {
        containsValidUse = true;
        return;
      }
      // Assignment to VariableDeclaration as setter.
      var leftHandSide = node.leftHandSide;
      if (leftHandSide is PropertyAccess &&
          leftHandSide.propertyName.token.lexeme == variable.name.lexeme) {
        containsValidUse = true;
        return;
      }
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (node.fieldName.element == variableElement) {
      containsValidUse = true;
      return;
    }
    super.visitConstructorFieldInitializer(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (variableType == _VariableType.field) {
      var staticElement = node.declaredFragment?.element;
      if (staticElement is FieldFormalParameterElement2 &&
          staticElement.field2 == variableElement) {
        containsValidUse = true;
        return;
      }
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_hasMatch(predicates, variableElement.type, node.methodName.name) &&
        (_isSimpleIdentifierElementEqualToVariable(
                node.realTarget, variableElement) ||
            _isPostfixExpressionOperandEqualToVariable(
                node.realTarget, variableElement) ||
            _isPropertyAccessThroughThis(node.realTarget, variableElement) ||
            (node.thisOrAncestorMatching((a) => a == variable) != null))) {
      containsValidUse = true;
      return;
    }

    if (_isInvocationThroughCascadeExpression(node, variableElement)) {
      containsValidUse = true;
      return;
    }

    if (node.argumentList.arguments
        .whereType<SimpleIdentifier>()
        .map((e) => e.element)
        .contains(variableElement)) {
      // If any function is invoked with our variable, we suppress lints. This
      // is because it is not so uncommon to invoke the target method there. We
      // might not have access to the body of such function at analysis time, so
      // we cannot infer whether the target method is invoked.
      // TODO(alexeidiaz): Should there be another, stricter lint rule that
      // omits this step?
      containsValidUse = true;
      return;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.element == variableElement &&
        _hasMatch(
            predicates, variableElement.type, node.identifier.token.lexeme)) {
      containsValidUse = true;
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (variableType == _VariableType.local) {
      var expression = node.expression;
      if (expression is SimpleIdentifier &&
          expression.element == variableElement) {
        containsValidUse = true;
        return;
      }
    }
    super.visitReturnStatement(node);
  }
}

/// The type of variable being assessed.
enum _VariableType {
  field,
  local;
}

extension on Element2? {
  bool matches(VariableElement2? variable) => switch (this) {
        GetterElement(:var variable3) => variable3 == variable,
        SetterElement(:var variable3) => variable3 == variable,
        _ => false,
      };
}
