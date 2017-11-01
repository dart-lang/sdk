// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r"Don't create a lambda when a tear-off will do.";

const _details = r'''

**DON'T** create a lambda when a tear-off will do.

**BAD:**
```
names.forEach((name) {
  print(name);
});
```

**GOOD:**
```
names.forEach(print);
```

''';

bool _containsNullAwareInvocationInChain(AstNode node) =>
    node != null &&
    ((node is PropertyAccess &&
            (node.operator?.type == TokenType.QUESTION_PERIOD ||
                _containsNullAwareInvocationInChain(node.target))) ||
        (node is MethodInvocation &&
            (node.operator?.type == TokenType.QUESTION_PERIOD ||
                _containsNullAwareInvocationInChain(node.target))) ||
        (node is IndexExpression &&
            _containsNullAwareInvocationInChain(node.target)));

Iterable<Element> _extractElementsOfSimpleIdentifiers(AstNode node) =>
    DartTypeUtilities
        .traverseNodesInDFS(node)
        .where((e) => e is SimpleIdentifier)
        .map((e) => (e as SimpleIdentifier).bestElement);

bool _isInvocationExpression(AstNode node) => node is InvocationExpression;

bool _isNonFinalElement(Element element) =>
    (element is PropertyAccessorElement &&
        (!element.isSynthetic || !element.variable.isFinal)) ||
    (element is VariableElement && !element.isFinal);

bool _isNonFinalField(AstNode node) =>
    (node is PropertyAccess &&
        _isNonFinalElement(node.propertyName.bestElement)) ||
    (node is MethodInvocation &&
        (_isNonFinalElement(node.methodName.bestElement))) ||
    (node is SimpleIdentifier && _isNonFinalElement(node.bestElement));

class UnnecessaryLambdas extends LintRule {
  _Visitor _visitor;

  UnnecessaryLambdas()
      : super(
            name: 'unnecessary_lambdas',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.element.name != '' || node.body.keyword != null) {
      return;
    }
    final body = node.body;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.single;
      if (statement is ExpressionStatement &&
          statement.expression is InvocationExpression) {
        _visitInvocationExpression(statement.expression, node);
      } else if (statement is ReturnStatement &&
          statement.expression is InvocationExpression) {
        _visitInvocationExpression(statement.expression, node);
      }
    } else if (body is ExpressionFunctionBody) {
      if (body.expression is InvocationExpression) {
        _visitInvocationExpression(body.expression, node);
      }
    }
  }

  void _visitInvocationExpression(
      InvocationExpression node, FunctionExpression nodeToLint) {
    if (!DartTypeUtilities.matchesArgumentsWithParameters(
        node.argumentList.arguments, nodeToLint.parameters.parameters)) {
      return;
    }
    final parameters =
        nodeToLint.parameters.parameters.map((e) => e.identifier.bestElement);

    Iterable<Element> restOfElements = [];
    if (node is FunctionExpressionInvocation) {
      restOfElements = _extractElementsOfSimpleIdentifiers(node.function);
    } else if (node is MethodInvocation) {
      var nodesInTarget = <AstNode>[];
      if (node.target != null) {
        nodesInTarget = DartTypeUtilities.traverseNodesInDFS(node.target);
        restOfElements = node.target is SimpleIdentifier
            ? [(node.target as SimpleIdentifier).bestElement]
            : _extractElementsOfSimpleIdentifiers(node.target);
      }
      if (_isNonFinalField(node) ||
          _isNonFinalField(node.target) ||
          _isInvocationExpression(node.target) ||
          _containsNullAwareInvocationInChain(node) ||
          nodesInTarget.any(_isNonFinalField) ||
          nodesInTarget.any(_isInvocationExpression)) {
        return;
      }
    }
    if (restOfElements.any(parameters.contains)) {
      return;
    }
    rule.reportLint(nodeToLint);
  }
}
