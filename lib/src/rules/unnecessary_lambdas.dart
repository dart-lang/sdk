// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

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
            (node.isNullAware ||
                _containsNullAwareInvocationInChain(node.target))) ||
        (node is MethodInvocation &&
            (node.isNullAware ||
                _containsNullAwareInvocationInChain(node.target))) ||
        (node is IndexExpression &&
            _containsNullAwareInvocationInChain(node.target)));

Iterable<Element> _extractElementsOfSimpleIdentifiers(AstNode node) =>
    DartTypeUtilities.traverseNodesInDFS(node)
        .whereType<SimpleIdentifier>()
        .map((e) => e.staticElement);

class UnnecessaryLambdas extends LintRule implements NodeLintRule {
  UnnecessaryLambdas()
      : super(
            name: 'unnecessary_lambdas',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFunctionExpression(this, visitor);
  }
}

class _FinalExpressionChecker {
  final Set<ParameterElement> parameters;

  _FinalExpressionChecker(this.parameters);

  bool isFinalElement(Element element) {
    if (element is PropertyAccessorElement) {
      return element.isSynthetic && element.variable.isFinal;
    } else if (element is VariableElement) {
      return element.isFinal;
    }
    return true;
  }

  bool isFinalNode(Expression node) {
    if (node == null) {
      return true;
    }

    if (node is FunctionExpression) {
      var referencedElements = _extractElementsOfSimpleIdentifiers(node);
      return !referencedElements.any(parameters.contains);
    }

    if (node is ParenthesizedExpression) {
      return isFinalNode(node.expression);
    }

    if (node is PrefixedIdentifier) {
      return isFinalNode(node.prefix) && isFinalNode(node.identifier);
    }

    if (node is PropertyAccess) {
      return isFinalNode(node.target) && isFinalNode(node.propertyName);
    }

    if (node is SimpleIdentifier) {
      var element = node.staticElement;
      if (parameters.contains(element)) {
        return false;
      }
      return isFinalElement(element);
    }

    return false;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.declaredElement.name != '' || node.body.keyword != null) {
      return;
    }
    final body = node.body;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.single;
      if (statement is ExpressionStatement &&
          statement.expression is InvocationExpression) {
        _visitInvocationExpression(
            statement.expression as InvocationExpression, node);
      } else if (statement is ReturnStatement &&
          statement.expression is InvocationExpression) {
        _visitInvocationExpression(
            statement.expression as InvocationExpression, node);
      }
    } else if (body is ExpressionFunctionBody) {
      if (body.expression is InvocationExpression) {
        _visitInvocationExpression(
            body.expression as InvocationExpression, node);
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
        nodeToLint.parameters.parameters.map((e) => e.declaredElement).toSet();

    if (node is FunctionExpressionInvocation) {
      var checker = _FinalExpressionChecker(parameters);
      if (checker.isFinalNode(node.function)) {
        rule.reportLint(nodeToLint);
      }
    } else if (node is MethodInvocation) {
      var checker = _FinalExpressionChecker(parameters);
      if (!_containsNullAwareInvocationInChain(node) &&
          checker.isFinalNode(node.target) &&
          checker.isFinalElement(node.methodName.staticElement) &&
          node.typeArguments == null) {
        rule.reportLint(nodeToLint);
      }
    }
  }
}
