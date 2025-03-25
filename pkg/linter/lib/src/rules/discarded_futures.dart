// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

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

      if (_isNotEnclosedInAsyncFunctionBody(node)) {
        // Future expression statement that isn't awaited in synchronous
        // function: while this is legal, it's a very frequent sign of an error.
        _reportOnExpression(expr);
      }
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _visit(node.expression);
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

  bool _isNotEnclosedInAsyncFunctionBody(AstNode node) {
    var enclosingFunctionBody = node.thisOrAncestorOfType<FunctionBody>();
    var isAsyncBody = enclosingFunctionBody?.isAsynchronous ?? false;
    return !isAsyncBody;
  }

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
    if ((expr.staticType.isFutureOrFutureOr) &&
        _isNotEnclosedInAsyncFunctionBody(expr) &&
        expr is! AssignmentExpression) {
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
