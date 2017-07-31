// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

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

Element _getLeftElement(AssignmentExpression assignment) => DartTypeUtilities
    .getCanonicalElementFromIdentifier(assignment.leftHandSide);

Iterable<Element> _getParameters(ConstructorDeclaration node) {
  return node.parameters.parameters.map((e) => e.identifier.bestElement);
}

Element _getRightElement(AssignmentExpression assignment) => DartTypeUtilities
    .getCanonicalElementFromIdentifier(assignment.rightHandSide);

class PreferInitializingFormals extends LintRule {
  _Visitor _visitor;
  PreferInitializingFormals()
      : super(
            name: 'prefer_initializing_formals',
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
    final parametersUsedOnce = new Set<Element>();
    final parametersUsedMoreThanOnce = new Set<Element>();

    bool isAssignmentExpressionToLint(AssignmentExpression assignment) {
      final leftElement = _getLeftElement(assignment);
      final rightElement = _getRightElement(assignment);
      return leftElement != null &&
          rightElement != null &&
          !leftElement.isPrivate &&
          leftElement is FieldElement &&
          !leftElement.isSynthetic &&
          leftElement.enclosingElement == node.element.enclosingElement &&
          parameters.contains(rightElement) &&
          (!parametersUsedMoreThanOnce.contains(rightElement) ||
              leftElement.name == rightElement.name);
    }

    bool isConstructorFieldInitializerToLint(
        ConstructorFieldInitializer constructorFieldInitializer) {
      final expression = constructorFieldInitializer.expression;
      return !(constructorFieldInitializer.fieldName.bestElement?.isPrivate ??
              true) &&
          expression is SimpleIdentifier &&
          parameters.contains(expression.bestElement) &&
          (!parametersUsedMoreThanOnce.contains(expression.bestElement) ||
              constructorFieldInitializer.fieldName.bestElement?.name ==
                  expression.bestElement.name);
    }

    void processElement(Element element) {
      if (!parametersUsedOnce.add(element)) {
        parametersUsedMoreThanOnce.add(element);
      }
    }

    node.parameters.parameterElements
        .where((p) => p.isInitializingFormal)
        .forEach(processElement);

    _getAssignmentExpressionsInConstructorBody(node)
        .where(isAssignmentExpressionToLint)
        .map(_getRightElement)
        .forEach(processElement);

    _getConstructorFieldInitializersInInitializers(node)
        .where(isConstructorFieldInitializerToLint)
        .map((e) => (e.expression as SimpleIdentifier).bestElement)
        .forEach(processElement);

    _getAssignmentExpressionsInConstructorBody(node)
        .where(isAssignmentExpressionToLint)
        .forEach(rule.reportLint);

    _getConstructorFieldInitializersInInitializers(node)
        .where(isConstructorFieldInitializerToLint)
        .forEach(rule.reportLint);
  }
}
