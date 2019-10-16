// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary await keyword in return.';

const _details = r'''

Avoid returning an awaited expression when the expression type is assignable to
the function's return type.


**BAD:**
```
Future<int> future;
Future<int> f1() async => await future;
Future<int> f2() async {
  return await future;
}
```

**GOOD:**
```
Future<int> future;
Future<int> f1() => future;
Future<int> f2() {
  return future;
}
```

''';

class UnnecessaryAwaitInReturn extends LintRule implements NodeLintRule {
  UnnecessaryAwaitInReturn()
      : super(
            name: 'unnecessary_await_in_return',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context.typeSystem);
    registry.addExpressionFunctionBody(this, visitor);
    registry.addReturnStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystem typeSystem;

  _Visitor(this.rule, this.typeSystem);

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _visit(node, node.expression.unParenthesized);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      _visit(node, node.expression.unParenthesized);
    }
  }

  void _visit(AstNode node, Expression expression) {
    if (expression is! AwaitExpression) return;

    final type = (expression as AwaitExpression).expression.staticType;
    if (type?.isDartAsyncFuture != true) {
      return;
    }

    final parent = node.thisOrAncestorMatching((e) =>
        e is FunctionExpression ||
        e is MethodDeclaration ||
        e is Block && e.parent is TryStatement);
    if (parent == null) return;

    DartType returnType;
    if (parent is FunctionExpression) {
      returnType = parent.declaredElement?.returnType;
    } else if (parent is MethodDeclaration) {
      returnType = parent.declaredElement?.returnType;
    } else if (parent is Block) {
      // removing await in try block changes the behaviour
      return;
    } else {
      throw StateError('unexpected type');
    }
    if (returnType != null &&
        returnType.isDartAsyncFuture &&
        typeSystem.isSubtypeOf(type, returnType)) {
      rule.reportLintForToken((expression as AwaitExpression).awaitKeyword);
    }
  }
}
