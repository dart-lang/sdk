// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid returning null for void.';

const _details = r'''

**AVOID** returning null for void.

In a large variety of languages `void` as return type is used to indicate that
a function doesn't return anything. Dart allows returning `null` in functions
with `void` return type but it also allow using `return;` without specifying any
value. To have a consistent way you should not return `null` and only use an
empty return.

**BAD:**
```
void f1() {
  return null;
}
Future<void> f2() async {
  return null;
}
```

**GOOD:**
```
void f1() {
  return;
}
Future<void> f2() async {
  return;
}
```

''';

class AvoidReturningNullForVoid extends LintRule implements NodeLintRule {
  AvoidReturningNullForVoid()
      : super(
            name: 'avoid_returning_null_for_void',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addExpressionFunctionBody(this, visitor);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _visit(node, node.expression);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      _visit(node, node.expression);
    }
  }

  void _visit(AstNode node, Expression expression) {
    if (expression is! NullLiteral) {
      return;
    }

    final parent = node.thisOrAncestorMatching(
        (e) => e is FunctionExpression || e is MethodDeclaration);
    if (parent == null) return;

    DartType type;
    bool isAsync;
    if (parent is FunctionExpression) {
      type = parent.declaredElement?.returnType;
      isAsync = parent.body?.isAsynchronous;
    } else if (parent is MethodDeclaration) {
      type = parent.declaredElement?.returnType;
      isAsync = parent.body?.isAsynchronous;
    } else {
      throw StateError('unexpected type');
    }
    if (isAsync == null || type == null) return;

    if (!isAsync && type.isVoid) {
      rule.reportLint(node);
    } else if (isAsync &&
        type.isDartAsyncFuture &&
        (type as InterfaceType).typeArguments.first.isVoid) {
      rule.reportLint(node);
    }
  }
}
