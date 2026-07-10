// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

import '../extensions.dart';

/// A function that returns whether a given [Expression] is "interesting," and
/// should be considered for a lint report.
typedef IsInterestingFilter = bool Function(Expression node);
typedef Reporter = void Function(AstNode node, DartType type);

/// A shared visitor for the `discarded_futures` and `unawaited_futures` lint
/// rules.
///
/// The two rules instantiate this with different [IsInterestingFilter]
/// predicates (`discarded_futures` is concerned with _synchronous_ functions;
/// `unawaited_futures` is concerned with _asynchronous_ functions).
class UnusedFuturesVisitor extends SimpleAstVisitor<void> {
  final Reporter _reportAt;

  /// Returns whether an [Expression] is "interesting," that is, whether we
  /// might report on it.
  final IsInterestingFilter _isInteresting;

  final TypeProvider _typeProvider;

  new({
    required this._reportAt,
    required this._isInteresting,
    required this._typeProvider,
  });

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
    if (expr is AwaitExpression) return;

    var type = expr.staticType;
    if (type == null || !_relevantType(type)) return;
    if (!_isInteresting(expr)) return;
    if (expr.isAwaitNotRequired) return;

    // Ignore a couple of special known cases.
    if (_isFutureDelayedInstanceCreationWithComputation(expr) ||
        _isMapPutIfAbsentInvocation(expr)) {
      return;
    }

    _reportOnExpression(expr, type);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _visit(node.expression);
  }

  /// Detects `Future.delayed(duration, [computation])` creations with a
  /// computation.
  bool _isFutureDelayedInstanceCreationWithComputation(Expression expr) =>
      expr is InstanceCreationExpression &&
      (expr.staticType?.isDartAsyncFuture ?? false) &&
      expr.constructorName.name?.name == 'delayed' &&
      expr.argumentList.arguments.length == 2;

  bool _isMapClass(Element? e) =>
      e is ClassElement && e.name == 'Map' && e.library.name == 'dart.core';

  /// Detects `Map.putIfAbsent` invocations.
  bool _isMapPutIfAbsentInvocation(Expression expr) =>
      expr is MethodInvocation &&
      expr.methodName.name == 'putIfAbsent' &&
      _isMapClass(expr.methodName.element?.enclosingElement);

  bool _relevantType(DartType type) =>
      type.asInstanceOf(_typeProvider.futureElement) != null ||
      type.asInstanceOf(_typeProvider.futureOrElement) != null;

  void _reportOnExpression(Expression expr, DartType type) {
    _reportAt(switch (expr) {
      MethodInvocation(:var methodName) => methodName,
      InstanceCreationExpression(:var constructorName) => constructorName,
      FunctionExpressionInvocation(:var function) => function,
      PrefixedIdentifier(:var identifier) => identifier,
      PropertyAccess(:var propertyName) => propertyName,
      _ => expr,
    }, type);
  }

  void _visit(Expression expr) {
    if (expr.isAwaitNotRequired) {
      return;
    }

    var type = expr.staticType;
    if (type != null &&
        _relevantType(type) &&
        _isInteresting(expr) &&
        expr is! AssignmentExpression) {
      _reportOnExpression(expr, type);
    }
  }
}
