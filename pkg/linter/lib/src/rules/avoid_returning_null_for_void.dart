// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid returning `null` for `void`.';

class AvoidReturningNullForVoid extends LintRule {
  AvoidReturningNullForVoid()
      : super(
          name: LintNames.avoid_returning_null_for_void,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.avoid_returning_null_for_void_from_function,
        LinterLintCode.avoid_returning_null_for_void_from_method
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
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
    if (node.expression case var nodeExpression?) {
      _visit(node, nodeExpression);
    }
  }

  void _visit(AstNode node, Expression expression) {
    if (expression is! NullLiteral) return;

    var parent = node.thisOrAncestorMatching(
        (e) => e is FunctionExpression || e is MethodDeclaration);
    if (parent == null) return;

    var (type, isAsync, code) = switch (parent) {
      FunctionExpression() => (
          parent.element?.returnType,
          parent.body.isAsynchronous,
          LinterLintCode.avoid_returning_null_for_void_from_function,
        ),
      MethodDeclaration() => (
          parent.declaredFragment?.element.returnType,
          parent.body.isAsynchronous,
          LinterLintCode.avoid_returning_null_for_void_from_method,
        ),
      _ => throw StateError('Unexpected type'),
    };
    if (type == null) return;

    if (!isAsync && type is VoidType) {
      rule.reportLint(node, errorCode: code);
    } else if (isAsync &&
        type.isDartAsyncFuture &&
        (type as InterfaceType).typeArguments.first is VoidType) {
      rule.reportLint(node, errorCode: code);
    }
  }
}

extension on FunctionExpression {
  ExecutableElement2? get element =>
      declaredFragment?.element ?? declaredElement2;
}
