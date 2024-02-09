// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';

/// Builds a function that reports a variable node if none of the predicates
/// which result from building [predicates] with [predicateBuilders] return
/// `true` for any node inside the [container] node.
_VisitVariableDeclaration _buildVariableReporter(
        AstNode container,
        Iterable<_PredicateBuilder> predicateBuilders,
        LintRule rule,
        Map<DartTypePredicate, String> predicates) =>
    (VariableDeclaration variable) {
      var variableElement = variable.declaredElement;
      if (variableElement == null) {
        return;
      }

      if (!predicates.keys
          .any((DartTypePredicate p) => p(variableElement.type))) {
        return;
      }

      // TODO(pq): migrate away from `traverseNodesInDFS` (https://github.com/dart-lang/linter/issues/3745)
      // ignore: deprecated_member_use_from_same_package
      var containerNodes = container.traverseNodesInDFS();

      for (var predicateBuilder in predicateBuilders) {
        if (containerNodes.any(predicateBuilder(variableElement))) {
          return;
        }
      }

      if (_hasVariableAssignments(containerNodes, variable)) {
        return;
      }

      if (_hasNodesInvokingMethodOnVariable(
          containerNodes, variable, predicates)) {
        return;
      }

      if (_hasMethodCallbackNodes(
          containerNodes, variableElement, predicates)) {
        return;
      }

      // If any function is invoked with our variable, we suppress lints. This
      // is because it is not so uncommon to invoke the target method there. We
      // might not have access to the body of such function at analysis time, so
      // trying to infer if the close method is invoked there is not always
      // possible.
      // TODO(alexeidiaz): Should there be another lint more relaxed that omits this step?
      if (_hasMethodInvocationsWithVariableAsArgument(
          containerNodes, variableElement)) {
        return;
      }

      rule.reportLint(variable);
    };

/// Returns a predicate that returns true for a node `n` if `n` is a
/// [ConstructorFieldInitializer] initializing [v].
_Predicate _hasConstructorFieldInitializers(VariableElement v) => (AstNode n) =>
    n is ConstructorFieldInitializer && n.fieldName.staticElement == v;

/// Returns a predicate that returns true for a node `n` if `n` is a
/// [FieldFormalParameter] initializing [v].
_Predicate _hasFieldFormalParameter(VariableElement v) => (AstNode n) {
      if (n is! FieldFormalParameter) {
        return false;
      }
      var staticElement = n.declaredElement;
      return staticElement is FieldFormalParameterElement &&
          staticElement.field == v;
    };

/// Whether any of the [predicates] holds true for [type] and [methodName].
bool _hasMatch(Map<DartTypePredicate, String> predicates, DartType type,
        String methodName) =>
    predicates.keys.any((p) => predicates[p] == methodName && p(type));

bool _hasMethodCallbackNodes(
    Iterable<AstNode> containerNodes,
    VariableElement variableElement,
    Map<DartTypePredicate, String> predicates) {
  var prefixedIdentifiers = containerNodes.whereType<PrefixedIdentifier>();
  return prefixedIdentifiers.any((n) =>
      n.prefix.staticElement == variableElement &&
      _hasMatch(predicates, variableElement.type, n.identifier.token.lexeme));
}

bool _hasMethodInvocationsWithVariableAsArgument(
    Iterable<AstNode> containerNodes, VariableElement variableElement) {
  var methodInvocations = containerNodes.whereType<MethodInvocation>();
  return methodInvocations.any((n) => n.argumentList.arguments
      .whereType<SimpleIdentifier>()
      .map((e) => e.staticElement)
      .contains(variableElement));
}

bool _hasNodesInvokingMethodOnVariable(
        Iterable<AstNode> classNodes,
        VariableDeclaration variable,
        Map<DartTypePredicate, String> predicates) =>
    classNodes.any((AstNode n) {
      var declaredElement = variable.declaredElement;
      return declaredElement != null &&
          n is MethodInvocation &&
          ((_hasMatch(predicates, declaredElement.type, n.methodName.name) &&
                  (_isSimpleIdentifierElementEqualToVariable(
                          n.realTarget, declaredElement) ||
                      _isPostfixExpressionOperandEqualToVariable(
                          n.realTarget, declaredElement) ||
                      _isPropertyAccessThroughThis(
                          n.realTarget, declaredElement) ||
                      (n.thisOrAncestorMatching((a) => a == variable) !=
                          null))) ||
              (_isInvocationThroughCascadeExpression(n, declaredElement)));
    });

/// Returns a predicate that returns true for a node `n` if `n` is a
/// [ReturnStatement] initializing [v].
_Predicate _hasReturn(VariableElement v) => (AstNode n) {
      if (n is! ReturnStatement) {
        return false;
      }
      var expression = n.expression;
      return expression is SimpleIdentifier && expression.staticElement == v;
    };

bool _hasVariableAssignments(
    Iterable<AstNode> containerNodes, VariableDeclaration variable) {
  if (variable.equals != null && variable.initializer is SimpleIdentifier) {
    return true;
  }

  return containerNodes.any((n) =>
      n is AssignmentExpression &&
      (_isElementEqualToVariable(n.writeElement, variable.declaredElement) ||
          // Assignment to VariableDeclaration as setter.
          (n.leftHandSide is PropertyAccess &&
              (n.leftHandSide as PropertyAccess).propertyName.token.lexeme ==
                  variable.name.lexeme))
      // Being assigned another reference.
      &&
      n.rightHandSide is SimpleIdentifier);
}

bool _isElementEqualToVariable(
        Element? propertyElement, VariableElement? variableElement) =>
    propertyElement == variableElement ||
    propertyElement is PropertyAccessorElement &&
        propertyElement.variable == variableElement;

bool _isInvocationThroughCascadeExpression(
    MethodInvocation invocation, VariableElement variableElement) {
  if (invocation.realTarget is! SimpleIdentifier) {
    return false;
  }

  var identifier = invocation.realTarget;
  if (identifier is SimpleIdentifier) {
    var element = identifier.staticElement;
    if (element is PropertyAccessorElement) {
      return element.variable == variableElement;
    }
  }
  return false;
}

bool _isPostfixExpressionOperandEqualToVariable(
    AstNode? n, VariableElement variableElement) {
  if (n is PostfixExpression) {
    var operand = n.operand;
    return operand is SimpleIdentifier &&
        _isElementEqualToVariable(operand.staticElement, variableElement);
  }
  return false;
}

bool _isPropertyAccessThroughThis(
    Expression? n, VariableElement variableElement) {
  if (n is! PropertyAccess) {
    return false;
  }

  var target = n.realTarget;
  if (target is! ThisExpression) {
    return false;
  }

  var propertyElement = n.propertyName.staticElement;
  return _isElementEqualToVariable(propertyElement, variableElement);
}

bool _isSimpleIdentifierElementEqualToVariable(
        AstNode? n, VariableElement variableElement) =>
    n is SimpleIdentifier &&
    _isElementEqualToVariable(n.staticElement, variableElement);

typedef DartTypePredicate = bool Function(DartType type);

typedef _Predicate = bool Function(AstNode node);

typedef _PredicateBuilder = _Predicate Function(VariableElement v);

typedef _VisitVariableDeclaration = void Function(VariableDeclaration node);

abstract class LeakDetectorProcessors extends SimpleAstVisitor<void> {
  static final _variablePredicateBuilders = <_PredicateBuilder>[_hasReturn];
  static final _fieldPredicateBuilders = <_PredicateBuilder>[
    _hasConstructorFieldInitializers,
    _hasFieldFormalParameter
  ];

  final LintRule rule;

  LeakDetectorProcessors(this.rule);

  @protected
  Map<DartTypePredicate, String> get predicates;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    var unit = getCompilationUnit(node);
    if (unit != null) {
      node.fields.variables.forEach(_buildVariableReporter(
          unit, _fieldPredicateBuilders, rule, predicates));
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function != null) {
      node.variables.variables.forEach(_buildVariableReporter(
          function, _variablePredicateBuilders, rule, predicates));
    }
  }
}
