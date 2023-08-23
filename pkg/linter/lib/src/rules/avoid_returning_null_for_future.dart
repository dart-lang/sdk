// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
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

class AvoidReturningNullForFuture extends LintRule {
  static const LintCode code = LintCode('avoid_returning_null_for_future',
      "Don't return 'null' when the return type is 'Future'.",
      correctionMessage:
          "Try making the function 'async', or returning 'Future.value(null)'.");

  AvoidReturningNullForFuture()
      : super(
            name: 'avoid_returning_null_for_future',
            description: _desc,
            details: _details,
            state: State.deprecated(since: dart2_12),
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    // In a Null Safety library, this lint is covered by other formal static
    // analysis.
    if (!context.isEnabled(Feature.non_nullable)) {
      var visitor = _Visitor(this);
      registry.addExpressionFunctionBody(this, visitor);
      registry.addReturnStatement(this, visitor);
    }
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
    var expression = node.expression;
    if (expression != null) {
      _visit(node, expression);
    }
  }

  void _visit(AstNode node, Expression expression) {
    if (expression.staticType?.isDartCoreNull != true) {
      return;
    }

    var parent = node.thisOrAncestorMatching(
        (e) => e is FunctionExpression || e is MethodDeclaration);
    if (parent == null) return;

    DartType? returnType;
    bool isAsync;
    if (parent is FunctionExpression) {
      returnType = parent.declaredElement?.returnType;
      isAsync = parent.body.isAsynchronous;
    } else if (parent is MethodDeclaration) {
      returnType = parent.declaredElement?.returnType;
      isAsync = parent.body.isAsynchronous;
    } else {
      throw StateError('unexpected type');
    }
    if (returnType != null && returnType.isDartAsyncFuture && !isAsync) {
      rule.reportLint(expression);
    }
  }
}
