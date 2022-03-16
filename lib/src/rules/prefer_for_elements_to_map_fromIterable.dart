// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Prefer 'for' elements when building maps from iterables.";

const _details = r'''
When building maps from iterables, it is preferable to use 'for' elements.

Using 'for' elements brings several benefits including:

- Performance
- Flexibility
- Readability
- Improved type inference
- Improved interaction with null safety


**BAD:**
```dart
Map<String, WidgetBuilder>.fromIterable(
  kAllGalleryDemos,
  key: (demo) => '${demo.routeName}',
  value: (demo) => demo.buildRoute,
);

```

**GOOD:**
```dart
return {
  for (var demo in kAllGalleryDemos)
    '${demo.routeName}': demo.buildRoute,
};
```

**GOOD:**
```dart
// Map<int, Student> is not required, type is inferred automatically.
final pizzaRecipients = {
  ...studentLeaders,
  for (var student in classG)
    if (student.isPassing) student.id: student,
};
```
''';

class PreferForElementsToMapFromIterable extends LintRule {
  PreferForElementsToMapFromIterable()
      : super(
            name: 'prefer_for_elements_to_map_fromIterable',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression creation) {
    var element = creation.constructorName.staticElement;
    if (element == null ||
        element.name != 'fromIterable' ||
        element.enclosingElement != context.typeProvider.mapElement) {
      return;
    }

    //
    // Ensure that the arguments have the right form.
    //
    var arguments = creation.argumentList.arguments;
    if (arguments.length != 3) {
      return;
    }

    var secondArg = arguments[1];
    var thirdArg = arguments[2];

    Expression? extractBody(FunctionExpression expression) {
      var body = expression.body;
      if (body is ExpressionFunctionBody) {
        return body.expression;
      } else if (body is BlockFunctionBody) {
        var statements = body.block.statements;
        if (statements.length == 1) {
          var statement = statements.first;
          if (statement is ReturnStatement) {
            return statement.expression;
          }
        }
      }
      return null;
    }

    FunctionExpression? extractClosure(String name, Expression argument) {
      if (argument is NamedExpression && argument.name.label.name == name) {
        var expression = argument.expression.unParenthesized;
        if (expression is FunctionExpression) {
          var parameters = expression.parameters?.parameters;
          if (parameters != null &&
              parameters.length == 1 &&
              parameters.first.isRequired) {
            if (extractBody(expression) != null) {
              return expression;
            }
          }
        }
      }
      return null;
    }

    var keyClosure =
        extractClosure('key', secondArg) ?? extractClosure('key', thirdArg);
    var valueClosure =
        extractClosure('value', thirdArg) ?? extractClosure('value', secondArg);
    if (keyClosure == null || valueClosure == null) {
      return;
    }

    rule.reportLint(creation);
  }
}
