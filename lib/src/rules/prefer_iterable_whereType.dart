// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Prefer to use whereType on iterable.';

const _details = r'''
**PREFER** `iterable.whereType<T>()` over `iterable.where((e) => e is T)`.

**BAD:**
```dart
iterable.where((e) => e is MyClass);
```

**GOOD:**
```dart
iterable.whereType<MyClass>();
```

''';

class PreferIterableWhereType extends LintRule {
  static const LintCode code = LintCode('prefer_iterable_whereType',
      "Use 'whereType' to select elements of a given type.",
      correctionMessage: "Try rewriting the expression to use 'whereType'.");

  PreferIterableWhereType()
      : super(
            name: 'prefer_iterable_whereType',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'where') return;
    var target = node.realTarget;
    if (target == null ||
        !target.staticType.implementsInterface('Iterable', 'dart.core')) {
      return;
    }

    var args = node.argumentList.arguments;
    if (args.length != 1) return;

    var arg = args.first;
    if (arg is FunctionExpression) {
      if (arg.parameters?.parameters.length != 1) return;

      var body = arg.body;
      Expression? expression;
      if (body is BlockFunctionBody) {
        var statements = body.block.statements;
        if (statements.length != 1) return;
        var statement = body.block.statements.first;
        if (statement is ReturnStatement) {
          expression = statement.expression;
        }
      } else if (body is ExpressionFunctionBody) {
        expression = body.expression;
      }
      expression = expression?.unParenthesized;
      if (expression is IsExpression && expression.notOperator == null) {
        var target = expression.expression;
        if (target is SimpleIdentifier &&
            target.name == arg.parameters?.parameters.first.name?.lexeme) {
          rule.reportLint(node.methodName);
        }
      }
    }
  }
}
