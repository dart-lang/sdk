// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    'There should be no `Future`-returning calls in synchronous functions unless they '
    'are assigned or returned.';

class DiscardedFutures extends LintRule {
  DiscardedFutures()
    : super(name: LintNames.discarded_futures, description: _desc);

  @override
  LintCode get lintCode => LinterLintCode.discarded_futures;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addExpressionStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
    registry.addInterpolationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCascadeExpression(CascadeExpression node) {
    var sections = node.cascadeSections;
    for (var i = 0; i < sections.length; i++) {
      _visit(sections[i]);
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    var expr = node.expression;
    if (expr is AssignmentExpression) return;

    if (_isEnclosedInAsyncFunctionBody(node)) {
      return;
    }

    if (expr case AwaitExpression(:var expression)) {
      expr = expression;
    }

    if (expr.isAwaitNotRequired) {
      return;
    }

    var type = expr.staticType;
    if (type == null) {
      return;
    }
    if (type.isFutureOrFutureOr) {
      // Ignore a couple of special known cases.
      if (_isFutureDelayedInstanceCreationWithComputation(expr) ||
          _isMapPutIfAbsentInvocation(expr)) {
        return;
      }

      _reportOnExpression(expr);
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _visit(node.expression);
  }

  bool _isEnclosedInAsyncFunctionBody(AstNode node) {
    var enclosingFunctionBody = node.thisOrAncestorOfType<FunctionBody>();
    return enclosingFunctionBody?.isAsynchronous ?? false;
  }

  /// Detects `Future.delayed(duration, [computation])` creations with a
  /// computation.
  bool _isFutureDelayedInstanceCreationWithComputation(Expression expr) =>
      expr is InstanceCreationExpression &&
      (expr.staticType.isFutureOrFutureOr) &&
      expr.constructorName.name?.name == 'delayed' &&
      expr.argumentList.arguments.length == 2;

  bool _isMapClass(Element2? e) =>
      e is ClassElement2 && e.name3 == 'Map' && e.library2.name3 == 'dart.core';

  /// Detects Map.putIfAbsent invocations.
  bool _isMapPutIfAbsentInvocation(Expression expr) =>
      expr is MethodInvocation &&
      expr.methodName.name == 'putIfAbsent' &&
      _isMapClass(expr.methodName.element?.enclosingElement2);

  void _reportOnExpression(Expression expr) {
    rule.reportLint(switch (expr) {
      MethodInvocation(:var methodName) => methodName,
      InstanceCreationExpression(:var constructorName) => constructorName,
      FunctionExpressionInvocation(:var function) => function,
      PrefixedIdentifier(:var identifier) => identifier,
      PropertyAccess(:var propertyName) => propertyName,
      _ => expr,
    });
  }

  void _visit(Expression expr) {
    if (expr.isAwaitNotRequired) {
      return;
    }

    if ((expr.staticType.isFutureOrFutureOr) &&
        !_isEnclosedInAsyncFunctionBody(expr) &&
        expr is! AssignmentExpression) {
      // TODO(srawlins): Take `@awaitNotRequired` into account.
      _reportOnExpression(expr);
    }
  }
}

extension on DartType? {
  bool get isFutureOrFutureOr {
    var self = this;
    if (self == null) return false;
    if (self.isDartAsyncFuture) return true;
    if (self.isDartAsyncFutureOr) return true;
    return false;
  }
}
