// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use initializing formals when possible.';

const _details = r'''
**DO** use initializing formals when possible.

Using initializing formals when possible makes your code more terse.

**BAD:**
```dart
class Point {
  num x, y;
  Point(num x, num y) {
    this.x = x;
    this.y = y;
  }
}
```

**GOOD:**
```dart
class Point {
  num x, y;
  Point(this.x, this.y);
}
```

**BAD:**
```dart
class Point {
  num x, y;
  Point({num x, num y}) {
    this.x = x;
    this.y = y;
  }
}
```

**GOOD:**
```dart
class Point {
  num x, y;
  Point({this.x, this.y});
}
```

**NOTE:**
This rule will not generate a lint for named parameters unless the parameter
name and the field name are the same. The reason for this is that resolving
such a lint would require either renaming the field or renaming the parameter,
and both of those actions would potentially be a breaking change. For example,
the following will not generate a lint:

```dart
class Point {
  bool isEnabled;
  Point({bool enabled}) {
    this.isEnabled = enabled; // OK
  }
}
```

**NOTE:**
Also note that it is possible to enforce a type that is stricter than the
initialized field with an initializing formal parameter.  In the following
example the unnamed `Bid` constructor requires a non-null `int` despite
`amount` being declared nullable (`int?`).

```dart
class Bid {
 final int? amount;
 Bid(int this.amount);
 Bid.pass() : amount = null;
}
```
''';

Iterable<AssignmentExpression> _getAssignmentExpressionsInConstructorBody(
    ConstructorDeclaration node) {
  var body = node.body;
  if (body is! BlockFunctionBody) return [];
  var assignments = <AssignmentExpression>[];
  for (var statement in body.block.statements) {
    if (statement is ExpressionStatement) {
      var expression = statement.expression;
      if (expression is AssignmentExpression) {
        assignments.add(expression);
      }
    }
  }
  return assignments;
}

Iterable<ConstructorFieldInitializer>
    _getConstructorFieldInitializersInInitializers(
            ConstructorDeclaration node) =>
        node.initializers.whereType<ConstructorFieldInitializer>();

Element? _getLeftElement(AssignmentExpression assignment) =>
    assignment.writeElement?.canonicalElement;

Iterable<Element?> _getParameters(ConstructorDeclaration node) =>
    node.parameters.parameters.map((e) => e.declaredElement);

Element? _getRightElement(AssignmentExpression assignment) =>
    assignment.rightHandSide.canonicalElement;

class PreferInitializingFormals extends LintRule {
  static const LintCode code = LintCode('prefer_initializing_formals',
      'Use an initializing formal to assign a parameter to a field.',
      correctionMessage:
          "Try using an initialing formal ('this.{0}') to initialize the field.");

  PreferInitializingFormals()
      : super(
            name: 'prefer_initializing_formals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Skip factory constructors.
    // https://github.com/dart-lang/linter/issues/2441
    if (node.factoryKeyword != null) {
      return;
    }

    var parameters = _getParameters(node);
    var parametersUsedOnce = <Element?>{};
    var parametersUsedMoreThanOnce = <Element?>{};

    bool isAssignmentExpressionToLint(AssignmentExpression assignment) {
      var leftElement = _getLeftElement(assignment);
      var rightElement = _getRightElement(assignment);
      return leftElement != null &&
          rightElement != null &&
          leftElement.name == rightElement.name &&
          !leftElement.isPrivate &&
          leftElement is FieldElement &&
          !leftElement.isSynthetic &&
          leftElement.enclosingElement ==
              node.declaredElement?.enclosingElement &&
          parameters.contains(rightElement) &&
          (!parametersUsedMoreThanOnce.contains(rightElement) &&
                  !(rightElement as ParameterElement).isNamed ||
              leftElement.name == rightElement.name);
    }

    bool isConstructorFieldInitializerToLint(
        ConstructorFieldInitializer constructorFieldInitializer) {
      var expression = constructorFieldInitializer.expression;
      if (expression is SimpleIdentifier) {
        var fieldName = constructorFieldInitializer.fieldName;
        if (fieldName.name != expression.name) {
          return false;
        }
        var staticElement = expression.staticElement;
        return staticElement is ParameterElement &&
            !(constructorFieldInitializer.fieldName.staticElement?.isPrivate ??
                true) &&
            parameters.contains(staticElement) &&
            (!parametersUsedMoreThanOnce.contains(expression.staticElement) &&
                    !staticElement.isNamed ||
                (constructorFieldInitializer.fieldName.staticElement?.name ==
                    expression.staticElement?.name));
      }
      return false;
    }

    void processElement(Element? element) {
      if (!parametersUsedOnce.add(element)) {
        parametersUsedMoreThanOnce.add(element);
      }
    }

    var parameterElements = node.parameters.parameterElements;
    for (var parameter in parameterElements) {
      if (parameter?.isInitializingFormal ?? false) {
        processElement(parameter);
      }
    }

    var assignments = _getAssignmentExpressionsInConstructorBody(node);
    for (var assignment in assignments) {
      if (isAssignmentExpressionToLint(assignment)) {
        processElement(_getRightElement(assignment));
      }
    }

    var initializers = _getConstructorFieldInitializersInInitializers(node);
    for (var initializer in initializers) {
      if (isConstructorFieldInitializerToLint(initializer)) {
        processElement(
            (initializer.expression as SimpleIdentifier).staticElement);
      }
    }

    for (var assignment in assignments) {
      if (isAssignmentExpressionToLint(assignment)) {
        var rightElement = _getRightElement(assignment)!;
        rule.reportLint(assignment, arguments: [rightElement.displayName]);
      }
    }

    for (var initializer in initializers) {
      if (isConstructorFieldInitializerToLint(initializer)) {
        var name = initializer.fieldName.staticElement!.name!;
        rule.reportLint(initializer, arguments: [name]);
      }
    }
  }
}
