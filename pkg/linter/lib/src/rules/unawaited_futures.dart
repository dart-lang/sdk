// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'`Future` results in `async` function bodies must be '
    '`await`ed or marked `unawaited` using `dart:async`.';

class UnawaitedFutures extends LintRule {
  UnawaitedFutures()
      : super(
          name: LintNames.unawaited_futures,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unawaited_futures;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
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
    if (type.implementsInterface('Future', 'dart.async')) {
      // Ignore a couple of special known cases.
      if (_isFutureDelayedInstanceCreationWithComputation(expr) ||
          _isMapPutIfAbsentInvocation(expr)) {
        return;
      }

      if (_isEnclosedInAsyncFunctionBody(node)) {
        // Future expression statement that isn't awaited in an async function:
        // while this is legal, it's a very frequent sign of an error.
        rule.reportLint(node);
      }
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
      (expr.staticType?.isDartAsyncFuture ?? false) &&
      expr.constructorName.name?.name == 'delayed' &&
      expr.argumentList.arguments.length == 2;

  bool _isMapClass(Element? e) =>
      e is ClassElement && e.name == 'Map' && e.library.name == 'dart.core';

  /// Detects Map.putIfAbsent invocations.
  bool _isMapPutIfAbsentInvocation(Expression expr) =>
      expr is MethodInvocation &&
      expr.methodName.name == 'putIfAbsent' &&
      _isMapClass(expr.methodName.staticElement?.enclosingElement3);

  void _visit(Expression expr) {
    if ((expr.staticType?.isDartAsyncFuture ?? false) &&
        _isEnclosedInAsyncFunctionBody(expr) &&
        expr is! AssignmentExpression) {
      rule.reportLint(expr);
    }
  }
}
