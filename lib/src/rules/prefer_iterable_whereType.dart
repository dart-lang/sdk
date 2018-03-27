// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Prefer to use whereType on iterable.';

const _details = r'''

**PREFER** `iterable.whereType<T>()` over `iterable.where((e) => e is T)`.

**BAD:**
```
iterable.where((e) => e is MyClass)
```

**GOOD:**
```
iterable.whereType<MyClass>()
```

''';

class PreferIterableWhereType extends LintRule {
  PreferIterableWhereType()
      : super(
            name: 'prefer_iterable_whereType',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'where') return;
    if (!DartTypeUtilities.implementsInterface(
        node.target.bestType, 'Iterable', 'dart.core')) {
      return;
    }

    final args = node.argumentList?.arguments;
    if (args == null || args.length != 1) return;

    final arg = args.first;
    if (arg is FunctionExpression) {
      if (arg.parameters.parameters.length != 1) return;

      final body = arg.body;
      Expression expression;
      if (body is BlockFunctionBody) {
        final statements = body.block.statements;
        if (statements.length != 1) return;
        final statement = body.block.statements.first;
        if (statement is ReturnStatement) {
          expression = statement.expression;
        }
      } else if (body is ExpressionFunctionBody) {
        expression = body.expression;
      }
      expression = expression?.unParenthesized;
      if (expression is IsExpression) {
        final target = expression.expression;
        if (target is SimpleIdentifier &&
            target.name == arg.parameters.parameters.first.identifier.name) {
          rule.reportLint(node.methodName);
        }
      }
    }
  }
}
