// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Start the name of the method with to/_to or as/_as if applicable.';

const _details = r'''

From the [design guide](https://dart.dev/guides/language/effective-dart/design):

**PREFER** naming a method to___() if it copies the object's state to a new object.

**PREFER** naming a method as___() if it returns a different representation backed by the original object.

**BAD:**
```
class Bar {
  Foo myMethod() {
    return Foo.from(this);
  }
}
```

**GOOD:**
```
class Bar {
  Foo toFoo() {
    return Foo.from(this);
  }
}
```

**GOOD:**
```
class Bar {
  Foo asFoo() {
    return Foo.from(this);
  }
}
```

''';

bool _beginsWithAsOrTo(String name) {
  final regExp = RegExp(r'(to|as|_to|_as)[A-Z]', caseSensitive: true);
  return regExp.matchAsPrefix(name) != null;
}

bool _isVoid(TypeAnnotation returnType) =>
    returnType is TypeName && returnType.name.name == 'void';

class UseToAndAsIfApplicable extends LintRule implements NodeLintRule {
  UseToAndAsIfApplicable()
      : super(
            name: 'use_to_and_as_if_applicable',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isGetter &&
        node.parameters.parameters.isEmpty &&
        !_isVoid(node.returnType) &&
        !_beginsWithAsOrTo(node.name.name) &&
        !DartTypeUtilities.hasInheritedMethod(node) &&
        _checkBody(node.body)) {
      rule.reportLint(node.name);
    }
  }

  bool _checkBody(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _checkExpression(body.expression);
    } else if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.first;
      if (statement is ReturnStatement) {
        return _checkExpression(statement.expression);
      }
    }
    return false;
  }

  bool _checkExpression(Expression rawExpression) {
    final expression = rawExpression?.unParenthesized;
    return expression is InstanceCreationExpression &&
        expression.argumentList.arguments.length == 1 &&
        expression.argumentList.arguments.first is ThisExpression;
  }
}
