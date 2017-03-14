// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.use_initializing_formals_when_possible;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Use initializing formals when possible.';

const _details = r'''

**DO** use initializing formals when possible.

**BAD:**
```
class Point {
  num x, y;
  Point(num x, num y) {
    this.x = x;
    this.y = y;
  }
}
```

**GOOD:**
```
class Point {
  num x, y;
  Point(this.x, this.y);
}
```

''';

Iterable<AssignmentExpression> _getAssignmentExpressionsInConstructorBody(
    ConstructorDeclaration node) {
  final body = node.body;
  final statements =
      (body is BlockFunctionBody) ? body.block.statements : <Statement>[];
  return statements
      .where((e) => e is ExpressionStatement)
      .map((e) => (e as ExpressionStatement).expression)
      .where((e) => e is AssignmentExpression)
      .map((e) => e as AssignmentExpression);
}

Iterable<ConstructorFieldInitializer>
    _getConstructorFieldInitializersInInitializers(
        ConstructorDeclaration node) {
  return node.initializers
      .where((e) => e is ConstructorFieldInitializer)
      .map((e) => (e as ConstructorFieldInitializer));
}

Element _getLeftElement(AssignmentExpression assignment) {
  final leftPart = assignment.leftHandSide;
  return leftPart is SimpleIdentifier
      ? leftPart.bestElement
      : leftPart is PropertyAccess ? leftPart.propertyName.bestElement : null;
}

Iterable<Element> _getParameters(ConstructorDeclaration node) {
  return node.parameters.parameters.map((e) => e.identifier.bestElement);
}

Element _getRightElement(AssignmentExpression assignment) {
  final rightPart = assignment.rightHandSide;
  return rightPart is SimpleIdentifier ? rightPart.bestElement : null;
}

class UseInitializingFormalsWhenPossible extends LintRule {
  _Visitor _visitor;
  UseInitializingFormalsWhenPossible()
      : super(
            name: 'use_initializing_formals_when_possible',
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
  visitConstructorDeclaration(ConstructorDeclaration node) {
    final parameters = _getParameters(node);

    bool isAssignmentExpressionToLint(AssignmentExpression assignment) {
      final leftElement = _getLeftElement(assignment);
      final rightElement = _getRightElement(assignment);
      return (leftElement != null &&
          rightElement != null &&
          !leftElement.isPrivate &&
          leftElement is PropertyAccessorElement &&
          !leftElement.variable.isSynthetic &&
          parameters.contains(rightElement));
    }

    bool isConstructorFieldInitializerToLint(
        ConstructorFieldInitializer constructorFieldInitializer) {
      final expression = constructorFieldInitializer.expression;
      return !(constructorFieldInitializer.fieldName.bestElement?.isPrivate ??
              true) &&
          expression is SimpleIdentifier &&
          parameters.contains(expression.bestElement);
    }

    _getAssignmentExpressionsInConstructorBody(node)
        .where(isAssignmentExpressionToLint)
        .forEach(rule.reportLint);

    _getConstructorFieldInitializersInInitializers(node)
        .where(isConstructorFieldInitializerToLint)
        .forEach(rule.reportLint);
  }
}
