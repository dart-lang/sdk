// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util.leak_detector_visitor;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

typedef bool DartTypePredicate(DartType type);
typedef void _VisitVariableDeclaration(VariableDeclaration node);
typedef bool _Predicate(AstNode node);
typedef _Predicate _PredicateBuilder(VariableDeclaration v);

abstract class LeakDetectorVisitor extends SimpleAstVisitor {
  static List<_PredicateBuilder> _variablePredicateBuilders = [_hasReturn];
  static List<_PredicateBuilder> _fieldPredicateBuilders = [
    _hasConstructorFieldInitializers,
    _hasFieldFormalParameter
  ];

  final LintRule rule;

  LeakDetectorVisitor(this.rule);

  String get methodName;

  DartTypePredicate get predicate;

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    FunctionBody function = node.getAncestor((a) => a is FunctionBody);
    node.variables.variables.forEach(_buildVariableReporter(
        methodName, function, _variablePredicateBuilders, predicate, rule));
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    ClassDeclaration classDecl = node.getAncestor((a) => a is ClassDeclaration);
    node.fields.variables.forEach(_buildVariableReporter(
        methodName, classDecl, _fieldPredicateBuilders, predicate, rule));
  }
}

_PredicateBuilder _hasReturn = (VariableDeclaration v) => (AstNode n) =>
    n is ReturnStatement &&
    n.expression is SimpleIdentifier &&
    (n.expression as SimpleIdentifier).token.lexeme == v.name.token.lexeme;

_PredicateBuilder _hasConstructorFieldInitializers = (VariableDeclaration v) =>
    (AstNode n) =>
        n is ConstructorFieldInitializer &&
        n.fieldName.name == v.name.token.lexeme;

_PredicateBuilder _hasFieldFormalParameter = (VariableDeclaration v) =>
    (AstNode n) =>
        n is FieldFormalParameter && n.identifier.name == v.name.token.lexeme;

/// Builds a function that reports the variable node if the set of nodes
/// inside the [container] node is empty for all the predicates resulting
/// from building (predicates) with the provided [predicateBuilders] evaluated
/// in the variable.
_VisitVariableDeclaration _buildVariableReporter(
        String methodName,
        AstNode container,
        Iterable<_PredicateBuilder> predicateBuilders,
        DartTypePredicate predicate,
        LintRule rule) =>
    (VariableDeclaration variable) {
      if (!predicate(variable.element.type)) {
        return;
      }

      List<AstNode> containerNodes =
          DartTypeUtilities.traverseNodesInDFS(container);

      List<Iterable<AstNode>> validators = <Iterable<AstNode>>[];
      predicateBuilders.forEach((f) {
        validators.add(containerNodes.where(f(variable)));
      });

      validators.add(_findVariableAssignments(containerNodes, variable));
      validators.add(_findNodesInvokingMethodOnVariable(
          containerNodes, variable, methodName));
      validators
          .add(_findMethodCallbackNodes(containerNodes, variable, methodName));
      // If any function is invoked with our variable, we supress lints. This is
      // because it is not so uncommon to invoke the target method there. We
      // might not have access to the body of such function at analysis time, so
      // trying to infer if the close method is invoked there is not always possible.
      // TODO: Should there be another lint more relaxed that omits this step?
      validators.add(_findMethodInvocationsWithVariableAsArgument(
          containerNodes, variable));

      // Read this as: validators.forAll((i) => i.isEmpty).
      if (!validators.any((i) => !i.isEmpty)) {
        rule.reportLint(variable);
      }
    };

Iterable<AstNode> _findVariableAssignments(
        Iterable<AstNode> containerNodes, VariableDeclaration variable) =>
    containerNodes.where((n) {
      return n is AssignmentExpression &&
          ((n.leftHandSide is SimpleIdentifier &&
                  // Assignment to VariableDeclaration as variable.
                  (n.leftHandSide as SimpleIdentifier).token.lexeme ==
                      variable.name.token.lexeme) ||
              // Assignment to VariableDeclaration as setter.
              (n.leftHandSide is PropertyAccess &&
                  (n.leftHandSide as PropertyAccess)
                          .propertyName
                          .token
                          .lexeme ==
                      variable.name.token.lexeme))
          // Being assigned another reference.
          &&
          n.rightHandSide is SimpleIdentifier;
    });

Iterable<AstNode> _findMethodInvocationsWithVariableAsArgument(
    Iterable<AstNode> containerNodes, VariableDeclaration variable) {
  Iterable<MethodInvocation> prefixedIdentifiers =
      containerNodes.where((n) => n is MethodInvocation);
  return prefixedIdentifiers.where((n) => n.argumentList.arguments
      .map((e) => e is SimpleIdentifier ? e.name : '')
      .contains(variable.name.token.lexeme));
}

Iterable<AstNode> _findMethodCallbackNodes(Iterable<AstNode> containerNodes,
    VariableDeclaration variable, String methodName) {
  Iterable<PrefixedIdentifier> prefixedIdentifiers =
      containerNodes.where((n) => n is PrefixedIdentifier);
  return prefixedIdentifiers.where((n) =>
      n.prefix.token.lexeme == variable.name.token.lexeme &&
      n.identifier.token.lexeme == methodName);
}

Iterable<AstNode> _findNodesInvokingMethodOnVariable(
        Iterable<AstNode> classNodes,
        VariableDeclaration variable,
        String methodName) =>
    classNodes.where((n) =>
        n is MethodInvocation &&
        n.methodName.name == methodName &&
        ((n.target is SimpleIdentifier &&
                (n.target as SimpleIdentifier).name == variable.name.name) ||
            (n.getAncestor((a) => a == variable) != null)));
