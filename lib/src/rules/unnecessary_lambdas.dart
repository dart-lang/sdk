// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.unnecessary_lambdas;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r"Don't create a lambda when a tear-off will do.";

const _details = r'''

**DON’T** create a lambda when a tear-off will do.

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

Iterable<Element> _extractElementsOfSimpleIdentifiers(AstNode node) =>
    DartTypeUtilities
        .traverseNodesInDFS(node)
        .where((e) => e is SimpleIdentifier)
        .map((e) => (e as SimpleIdentifier).bestElement);

bool _hasRecursivelyQuestionPeriod(AstNode node) {
  if (node == null) {
    return false;
  }
  return (node is PropertyAccess &&
          (node.operator?.type == TokenType.QUESTION_PERIOD ||
              _hasRecursivelyQuestionPeriod(node.target))) ||
      (node is IndexExpression &&
              _hasRecursivelyQuestionPeriod(node.target)) ||
      (node is MethodInvocation &&
          (node.operator?.type == TokenType.QUESTION_PERIOD ||
              _hasRecursivelyQuestionPeriod(node.target)));
}

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
    if (node.element.name != '') {
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
    if (nodeToLint.parameters.parameters.length !=
        node.argumentList.arguments.length) {
      return;
    }
    if (node.argumentList.arguments.any((e) => e is! SimpleIdentifier)) {
      return;
    }
    final parameters =
        nodeToLint.parameters.parameters.map((e) => e.identifier.bestElement);
    final arguments = node.argumentList.arguments
        .map((e) => (e as SimpleIdentifier).bestElement);
    for (int i = 0; i < parameters.length; i++) {
      if (parameters.elementAt(i) != arguments.elementAt(i)) {
        return;
      }
    }
    Iterable<Element> restOfElements = [];
    if (node is FunctionExpressionInvocation) {
      restOfElements = _extractElementsOfSimpleIdentifiers(node.function);
    } else if (node is MethodInvocation && node.target != null) {
      if (_hasRecursivelyQuestionPeriod(node)) {
        return;
      }
      restOfElements = node.target is SimpleIdentifier
          ? [(node.target as SimpleIdentifier).bestElement]
          : _extractElementsOfSimpleIdentifiers(node.target);
    }
    if (restOfElements.any(parameters.contains)) {
      return;
    }
    rule.reportLint(nodeToLint);
  }
}
