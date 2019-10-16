// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Use initializing formals when possible.';

const _details = r'''

**DO** use initializing formals when possible.

Using initializing formals when possible makes your code more terse.

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

**BAD:**
```
class Point {
  num x, y;
  Point({num x, num y}) {
    this.x = x;
    this.y = y;
  }
}
```

**GOOD:**
```
class Point {
  num x, y;
  Point({this.x, this.y});
}
```

**NOTE**
This rule will not generate a lint for named parameters unless the parameter
name and the field name are the same. The reason for this is that resolving
such a lint would require either renaming the field or renaming the parameter,
and both of those actions would potentially be a breaking change. For example,
the following will not generate a lint:

```
class Point {
  bool isEnabled;
  Point({bool enabled}) {
    this.isEnabled = enable; // OK
  }
}
```

''';

Iterable<AssignmentExpression> _getAssignmentExpressionsInConstructorBody(
    ConstructorDeclaration node) {
  final body = node.body;
  final statements =
      (body is BlockFunctionBody) ? body.block.statements : <Statement>[];
  return statements
      .whereType<ExpressionStatement>()
      .map((e) => e.expression)
      .whereType<AssignmentExpression>();
}

Iterable<ConstructorFieldInitializer>
    _getConstructorFieldInitializersInInitializers(
            ConstructorDeclaration node) =>
        node.initializers.whereType<ConstructorFieldInitializer>();

Element _getLeftElement(AssignmentExpression assignment) =>
    DartTypeUtilities.getCanonicalElementFromIdentifier(
        assignment.leftHandSide);

Iterable<Element> _getParameters(ConstructorDeclaration node) =>
    node.parameters.parameters.map((e) => e.identifier.staticElement);

Element _getRightElement(AssignmentExpression assignment) =>
    DartTypeUtilities.getCanonicalElementFromIdentifier(
        assignment.rightHandSide);

class PreferInitializingFormals extends LintRule implements NodeLintRule {
  PreferInitializingFormals()
      : super(
            name: 'prefer_initializing_formals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final parameters = _getParameters(node);
    final parametersUsedOnce = <Element>{};
    final parametersUsedMoreThanOnce = <Element>{};

    bool isAssignmentExpressionToLint(AssignmentExpression assignment) {
      final leftElement = _getLeftElement(assignment);
      final rightElement = _getRightElement(assignment);
      return leftElement != null &&
          rightElement != null &&
          !leftElement.isPrivate &&
          leftElement is FieldElement &&
          !leftElement.isSynthetic &&
          leftElement.enclosingElement ==
              node.declaredElement.enclosingElement &&
          parameters.contains(rightElement) &&
          (!parametersUsedMoreThanOnce.contains(rightElement) &&
                  !(rightElement as ParameterElement).isNamed ||
              leftElement.name == rightElement.name);
    }

    bool isConstructorFieldInitializerToLint(
        ConstructorFieldInitializer constructorFieldInitializer) {
      final expression = constructorFieldInitializer.expression;
      return !(constructorFieldInitializer.fieldName.staticElement?.isPrivate ??
              true) &&
          expression is SimpleIdentifier &&
          parameters.contains(expression.staticElement) &&
          (!parametersUsedMoreThanOnce.contains(expression.staticElement) &&
                  !(expression.staticElement as ParameterElement).isNamed ||
              (constructorFieldInitializer.fieldName.staticElement?.name ==
                  expression.staticElement.name));
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
        .map((e) => (e.expression as SimpleIdentifier).staticElement)
        .forEach(processElement);

    _getAssignmentExpressionsInConstructorBody(node)
        .where(isAssignmentExpressionToLint)
        .forEach(rule.reportLint);

    _getConstructorFieldInitializersInInitializers(node)
        .where(isConstructorFieldInitializerToLint)
        .forEach(rule.reportLint);
  }
}
