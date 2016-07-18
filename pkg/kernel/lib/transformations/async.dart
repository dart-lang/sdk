// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.async;

import '../checks.dart' as checks;
import '../kernel.dart';

import 'continuation.dart';

abstract class ProxiedTreeVisitor<R> extends Visitor<R> {
  R visitProxyExpression(ProxyExpression node) => defaultExpression(node);
}

abstract class ProxiedTreeTransformer = Transformer
    with ProxiedTreeVisitor<TreeNode>;

class ProxyExpression extends Expression {
  /// Actual value of this subexpression: either original subexpression or
  /// load from a corresponding temporary variable.
  Expression node;

  /// Number of emitted pending statements that need to be executed before
  /// evaluating this subexpression.
  /// It is only positive for expression that were lifted into temporary
  /// variables (variable initialization needs to be executed prior to
  /// evaluating this expression).
  /// For non-lifted expressions we reuse this variable to cache
  /// negated dependencyBoundary of the last lifted subexpression.
  int dependencyBoundary = 0;

  bool get wasLifted => dependencyBoundary > 0;

  ProxyExpression(this.node);

  accept(v) => v.visitProxyExpression(this);

  visitChildren(ProxiedTreeVisitor v) {}

  transformChildren(ProxiedTreeTransformer v) {}
}

class ProxyExpressionRemover extends ProxiedTreeTransformer {
  ProxyExpressionRemover();

  TreeNode visitProxyExpression(ProxyExpression node) => node.node.accept(this);
}

/// Transformer that introduces temporary variables for all subexpressions that
/// are alive across yield points (AwaitExpression).
///
/// Transformation is done in two passes:
///
///     - first pass recurses into expressions looking for await nodes keeping
///       track of the expression stack state. All encountered subexpressions
///       are wrapped into ProxyExpression nodes. Whenever an await node is
///       encountered all pending subexpressions are marked as lifted (hence
///       the need for proxies) and statements are generated to store these
///       subexpression into temporary variables.
///     - second pass removes all expression proxies converting them either back
///       to the subexpression (if it was not lifted) or into load from a
///       temporary variable containing subexpression.
///
/// Transformation make use of BlockExpression that allows us to have a sequence
/// of statements inside an expression.
///
class ExpressionLifter extends Transformer {
  final AsyncRewriterBase continuationRewriter;

  /// Function that is being transformed - to detect recursing into
  /// nested FunctionNodes and use appropriate state.
  final FunctionNode function;

  /// Determines whether we should wrap current subexpression into a
  /// BlockExpression if there are any statements that need to be emitted.
  /// It is correct to wrap all subexpression individually - but this is
  /// wasteful. That is why transformer tries to aggregate them an emit
  /// all as part of the top-level expression.
  bool shouldWrap = true;

  /// Determines if current subexpression contains await node.
  bool containsAwait = false;

  final List<ProxyExpression> pendingExpressions = <ProxyExpression>[];
  final List<Statement> pendingStatements = <Statement>[];
  final VariableDeclaration asyncResult =
      new VariableDeclaration(':result');
  final List<VariableDeclaration> variables = <VariableDeclaration>[];

  ExpressionLifter(this.continuationRewriter, this.function);

  Expression rewrite(Expression expression) {
    // TODO(vegorov) avoid inserting unnecessary proxies.
    expression = expression.accept(this);
    return expression.accept(new ProxyExpressionRemover());
  }

  VariableDeclaration allocateTemporary(int index) {
    for (var i = variables.length; i <= index; i++) {
      variables.add(new VariableDeclaration(":async-temporary-${i}"));
    }
    return variables[index];
  }

  storeTemp(VariableDeclaration temp, Expression value) {
    if (value is BlockExpression) {
      BlockExpression block = value;
      pendingStatements.addAll(block.body.statements);
      value = block.value;
    }
    emit(new ExpressionStatement(new VariableSet(temp, value)));
  }

  /// Introduce temporary variables for all pending subexpressions.
  liftSubexpressions() {
    for (var i = 0; i < pendingExpressions.length; i++) {
      final expr = pendingExpressions[i];
      if (!expr.wasLifted) {
        final temp = allocateTemporary(i);
        storeTemp(temp, expr.node);
        expr.node = new VariableGet(temp);
        expr.dependencyBoundary = pendingStatements.length;
      }
    }
  }

  emitYield(Expression futureReturningExpression) {
    var arguments = new Arguments([
        futureReturningExpression,
        new VariableGet(continuationRewriter.thenContinuationVariable),
        new VariableGet(continuationRewriter.catchErrorContinuationVariable),
    ]);
    emit(new ExpressionStatement(new StaticInvocation(
            continuationRewriter.helper.awaitHelper, arguments)));

    emit(continuationRewriter.createContinuationPoint());
  }

  emit(Statement stmt) {
    pendingStatements.add(stmt);
  }

  /// Wrap expression into a ProxyExpression and push it onto an expression
  /// stack.
  pushPendingExpression(Expression expr) {
    final ProxyExpression proxy = new ProxyExpression(expr);
    if (pendingExpressions.isNotEmpty) {
      proxy.dependencyBoundary = -pendingExpressions.last.dependencyBoundary;
    }
    pendingExpressions.add(proxy);
    return proxy;
  }

  TreeNode visitAwaitExpression(AwaitExpression node) {
    containsAwait = true;

    // Lift all currently pending subexpression into temporary variables.
    liftSubexpressions();

    // The code below is almost the same as [defaultExpressionImpl] but
    // it also rewrites await F into do { yield F; } :async-result.
    // TODO(vegorov) rewriting related to :async-result should be split out.
    final curShouldWrap = shouldWrap;
    shouldWrap = false;

    final TreeNode operand = node.operand.accept(this);
    shouldWrap = curShouldWrap;

    pendingExpressions.removeLast();

    emitYield(operand);

    return finishExpression(new VariableGet(asyncResult), curShouldWrap);
  }

  TreeNode finishExpression(Expression value, bool shouldWrapThis) {
    shouldWrap = shouldWrapThis;

    // Dependency boundary of the expression at the top of the stack determines
    // if we have any pending statements to emit for this expression.
    final int dependencyBoundary = pendingExpressions.isEmpty
        ? 0
        : pendingExpressions.last.dependencyBoundary;

    // If we are an outermost expression and there are pending statements
    // to emit, then we need to wrap [value] into a [BlockExpression] that
    // contains those statements.
    if (shouldWrapThis && pendingStatements.length > dependencyBoundary) {
      value = new BlockExpression(
          new Block(pendingStatements
              .getRange(dependencyBoundary, pendingStatements.length)
              .toList(growable: false)),
          value);

      // Drop emitted statements.
      pendingStatements.length = dependencyBoundary;
    }

    return shouldWrapThis ? value : pushPendingExpression(value);
  }

  // Note: some expression (e.g. parts of logical expression) are treated
  // as outermost expressions even though they are not outermost in the
  // sense of AST nesting.
  TreeNode defaultExpressionImpl(Expression node, {bool wrapSubexpressions}) {
    final shouldWrapThis = shouldWrap;
    shouldWrap = wrapSubexpressions;

    final int stackHeight = pendingExpressions.length;
    node = defaultTreeNode(node);
    pendingExpressions.length = stackHeight;

    return finishExpression(node, shouldWrapThis);
  }

  TreeNode visitLazyExpression(TreeNode node) {
    final bool outerContainsAwait = containsAwait;
    containsAwait = false;

    node = defaultExpressionImpl(node, wrapSubexpressions: true);

    // If expression stack is not empty and we encountered an await in a
    // subexpression then we have something like: f(..., { ... } expr && ...).
    // We must now lift this expression as whole into a temporary variable to
    // guarantee that expression stack is empty when we yield from inside a
    // subexpression.
    if (pendingExpressions.length > 1 && containsAwait) {
      liftSubexpressions();
    }

    containsAwait = containsAwait || outerContainsAwait;
    return node;
  }

  TreeNode defaultExpression(Expression node) =>
      defaultExpressionImpl(node, wrapSubexpressions: false);

  TreeNode visitLogicalExpression(TreeNode node) => visitLazyExpression(node);

  // TODO(vegorov) in expression A ? B : C we don't need to wrap
  // A in a separate BlockExpression if it contains await.
  // Write a manual visiting method for [ConditionalExpression] to solve this.
  TreeNode visitConditionalExpression(TreeNode node) =>
      visitLazyExpression(node);

  TreeNode visitLet(Let let) {
    // We need to handle [Let] specially in order to *keep* the
    // [VariableDeclaration] (which other nodes refer to) but rewrite the
    // expression using the await-expression rewriter.

    final shouldWrapThis = shouldWrap;
    shouldWrap = true;

    // Translate the expression.
    int stackHeight = pendingExpressions.length;
    let.variable.initializer = let.variable.initializer.accept(this);
    let.variable.initializer.parent = let.variable;
    pendingExpressions.length = stackHeight;

    // Translate the body.
    var resultBody = let.body.accept(this);
    let.body = resultBody;
    let.body.parent = let.body;
    pendingExpressions.length = stackHeight;

    return finishExpression(let, shouldWrapThis);
  }

  TreeNode defaultStatement(Statement stmt) {
    assert(pendingExpressions.length == 0);
    assert(pendingStatements.length == 0);
    stmt = super.defaultStatement(stmt);
    if (pendingStatements.length > 0) {
      stmt = new Block(<Statement>[]
        ..addAll(pendingStatements)
        ..add(stmt));
    }
    pendingStatements.length = 0;
    pendingExpressions.length = 0;
    containsAwait = false;
    return stmt;
  }

  visitFunctionNode(FunctionNode node) {
    var nestedRewriter = new RecursiveContinuationRewriter(
        continuationRewriter.helper);
    return node.accept(nestedRewriter);
  }

  visitDefaultStatement(node) => throw 'UNREACHABLE';
}
