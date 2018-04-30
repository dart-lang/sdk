// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/util/dart_type_utilities.dart';
import 'package:meta/meta.dart';

_PredicateBuilder _hasConstructorFieldInitializers = (VariableDeclaration v) =>
    (AstNode n) =>
        n is ConstructorFieldInitializer &&
        n.fieldName.bestElement == v.name.bestElement;

_PredicateBuilder _hasFieldFormalParameter = (VariableDeclaration v) =>
    (AstNode n) =>
        n is FieldFormalParameter &&
        (n.identifier.bestElement as FieldFormalParameterElement).field ==
            v.name.bestElement;

_PredicateBuilder _hasReturn = (VariableDeclaration v) => (AstNode n) =>
    n is ReturnStatement &&
    n.expression is SimpleIdentifier &&
    (n.expression as SimpleIdentifier).bestElement == v.name.bestElement;

/// Builds a function that reports the variable node if the set of nodes
/// inside the [container] node is empty for all the predicates resulting
/// from building (predicates) with the provided [predicateBuilders] evaluated
/// in the variable.
_VisitVariableDeclaration _buildVariableReporter(
        AstNode container,
        Iterable<_PredicateBuilder> predicateBuilders,
        LintRule rule,
        Map<DartTypePredicate, String> predicates) =>
    (VariableDeclaration variable) {
      if (!predicates.keys.any((DartTypePredicate p) => p(
          resolutionMap.elementDeclaredByVariableDeclaration(variable).type))) {
        return;
      }

      Iterable<AstNode> containerNodes =
          DartTypeUtilities.traverseNodesInDFS(container);

      List<Iterable<AstNode>> validators = <Iterable<AstNode>>[];
      predicateBuilders.forEach((f) {
        validators.add(containerNodes.where(f(variable)));
      });

      validators
        ..add(_findVariableAssignments(containerNodes, variable))
        ..add(_findNodesInvokingMethodOnVariable(
            containerNodes, variable, predicates))
        ..add(_findMethodCallbackNodes(containerNodes, variable, predicates))
        // If any function is invoked with our variable, we suppress lints. This
        // is because it is not so uncommon to invoke the target method there. We
        // might not have access to the body of such function at analysis time, so
        // trying to infer if the close method is invoked there is not always
        // possible.
        // TODO: Should there be another lint more relaxed that omits this step?
        ..add(_findMethodInvocationsWithVariableAsArgument(
            containerNodes, variable));

      if (validators.every((i) => i.isEmpty)) {
        rule.reportLint(variable);
      }
    };

Iterable<AstNode> _findMethodCallbackNodes(Iterable<AstNode> containerNodes,
    VariableDeclaration variable, Map<DartTypePredicate, String> predicates) {
  Iterable<PrefixedIdentifier> prefixedIdentifiers = containerNodes
      .where((n) => n is PrefixedIdentifier)
      .cast<PrefixedIdentifier>();
  return prefixedIdentifiers.where((n) =>
      n.prefix.bestElement == variable.name.bestElement &&
      _hasMatch(
          predicates,
          resolutionMap.elementDeclaredByVariableDeclaration(variable).type,
          n.identifier.token.lexeme));
}

Iterable<AstNode> _findMethodInvocationsWithVariableAsArgument(
    Iterable<AstNode> containerNodes, VariableDeclaration variable) {
  Iterable<MethodInvocation> prefixedIdentifiers = containerNodes
      .where((n) => n is MethodInvocation)
      .cast<MethodInvocation>();
  return prefixedIdentifiers.where((n) => n.argumentList.arguments
      .where((e) => e is SimpleIdentifier)
      .map((e) => (e as SimpleIdentifier).bestElement)
      .contains(variable.name.bestElement));
}

Iterable<AstNode> _findNodesInvokingMethodOnVariable(
        Iterable<AstNode> classNodes,
        VariableDeclaration variable,
        Map<DartTypePredicate, String> predicates) =>
    classNodes.where((AstNode n) =>
        n is MethodInvocation &&
        ((_hasMatch(
                    predicates,
                    resolutionMap
                        .elementDeclaredByVariableDeclaration(variable)
                        .type,
                    n.methodName.name) &&
                (_isSimpleIdentifierElementEqualToVariable(
                        n.realTarget, variable) ||
                    (n.getAncestor((a) => a == variable) != null))) ||
            (_isInvocationThroughCascadeExpression(n, variable))));

Iterable<AstNode> _findVariableAssignments(
    Iterable<AstNode> containerNodes, VariableDeclaration variable) {
  if (variable.equals != null &&
      variable.initializer != null &&
      variable.initializer is SimpleIdentifier) {
    return [variable];
  }

  return containerNodes.where((n) =>
      n is AssignmentExpression &&
      (_isSimpleIdentifierElementEqualToVariable(n.leftHandSide, variable) ||
          // Assignment to VariableDeclaration as setter.
          (n.leftHandSide is PropertyAccess &&
              (n.leftHandSide as PropertyAccess).propertyName.token.lexeme ==
                  variable.name.token.lexeme))
      // Being assigned another reference.
      &&
      n.rightHandSide is SimpleIdentifier);
}

bool _hasMatch(Map<DartTypePredicate, String> predicates, DartType type,
        String methodName) =>
    predicates.keys.fold(
        false,
        (bool previous, DartTypePredicate p) =>
            previous || p(type) && predicates[p] == methodName);

bool _isInvocationThroughCascadeExpression(
    MethodInvocation invocation, VariableDeclaration variable) {
  if (invocation.realTarget is! SimpleIdentifier) {
    return false;
  }

  final identifier = invocation.realTarget;
  if (identifier is SimpleIdentifier) {
    final element = identifier.bestElement;
    if (element is PropertyAccessorElement) {
      return element.variable == variable.element;
    }
  }
  return false;
}

bool _isSimpleIdentifierElementEqualToVariable(
        AstNode n, VariableDeclaration variable) =>
    (n is SimpleIdentifier &&
        // Assignment to VariableDeclaration as variable.
        (n.bestElement == variable.name.bestElement ||
            (n.bestElement is PropertyAccessorElement &&
                (n.bestElement as PropertyAccessorElement).variable ==
                    variable.name.bestElement)));

typedef bool DartTypePredicate(DartType type);

typedef bool _Predicate(AstNode node);

typedef _Predicate _PredicateBuilder(VariableDeclaration v);

typedef void _VisitVariableDeclaration(VariableDeclaration node);

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
    CompilationUnit unit = getCompilationUnit(node);
    node.fields.variables.forEach(_buildVariableReporter(
        unit, _fieldPredicateBuilders, rule, predicates));
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    FunctionBody function = node.getAncestor((a) => a is FunctionBody);
    node.variables.variables.forEach(_buildVariableReporter(
        function, _variablePredicateBuilders, rule, predicates));
  }
}
