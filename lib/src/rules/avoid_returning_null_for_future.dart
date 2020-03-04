// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid returning null for Future.';

const _details = r'''

**AVOID** returning null for Future.

It is almost always wrong to return `null` for a `Future`.  Most of the time the
developer simply forgot to put an `async` keyword on the function.

''';

class AvoidReturningNullForFuture extends LintRule implements NodeLintRule {
  AvoidReturningNullForFuture()
      : super(
            name: 'avoid_returning_null_for_future',
            description: _desc,
            details: _details,
            group: Group.errors);

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
    if (expression.staticType?.isDartCoreNull != true) {
      return;
    }

    final parent = node.thisOrAncestorMatching(
        (e) => e is FunctionExpression || e is MethodDeclaration);
    if (parent == null) return;

    DartType returnType;
    bool isAsync;
    if (parent is FunctionExpression) {
      returnType = parent.declaredElement?.returnType;
      isAsync = parent.body?.isAsynchronous;
    } else if (parent is MethodDeclaration) {
      returnType = parent.declaredElement?.returnType;
      isAsync = parent.body?.isAsynchronous;
    } else {
      throw StateError('unexpected type');
    }
    if (returnType != null && returnType.isDartAsyncFuture && !isAsync) {
      rule.reportLint(expression);
    }
  }
}
