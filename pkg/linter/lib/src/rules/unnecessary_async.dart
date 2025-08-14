// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc = r'No await no async.';

class UnnecessaryAsync extends LintRule {
  UnnecessaryAsync()
    : super(
        name: LintNames.unnecessary_async,
        description: _desc,
        state: const RuleState.experimental(),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.unnecessaryAsync;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _HasAwaitVisitor extends RecursiveAstVisitor<void> {
  bool hasAwait = false;
  bool everyReturnHasValue = true;
  bool returnsOnlyFuture = true;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    hasAwait = true;
    super.visitAwaitExpression(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _updateWithExpression(node.expression);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitForElement(ForElement node) {
    hasAwait |= node.awaitKeyword != null;
    super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    hasAwait |= node.awaitKeyword != null;
    super.visitForStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Stop the recursion.
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    var expression = node.expression;
    if (expression != null) {
      _updateWithExpression(expression);
    } else {
      everyReturnHasValue = false;
    }

    super.visitReturnStatement(node);
  }

  void _updateWithExpression(Expression expression) {
    var type = expression.staticType;
    if (!(type is InterfaceType &&
        type.isDartAsyncFutureOrSubtype &&
        type.nullabilitySuffix == NullabilitySuffix.none)) {
      returnsOnlyFuture = false;
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    _checkBody(
      body: node.functionExpression.body,
      returnType: element.returnType,
    );
  }

  @override
  void visitFunctionExpression(covariant FunctionExpressionImpl node) {
    // Here we handle only closures.
    if (node.parent is FunctionDeclaration) {
      return;
    }

    var bodyContext = node.body.bodyContext;

    _checkBody(body: node.body, returnType: bodyContext?.imposedType);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    _checkBody(body: node.body, returnType: element.returnType);
  }

  void _checkBody({
    required FunctionBodyImpl body,
    required DartType? returnType,
  }) {
    var asyncKeyword = body.keyword;
    if (asyncKeyword == null || asyncKeyword.keyword != Keyword.ASYNC) {
      return;
    }

    if (body.star != null) {
      return;
    }

    var bodyContext = body.bodyContext;
    if (bodyContext == null) {
      return;
    }

    var visitor = _HasAwaitVisitor();
    body.accept(visitor);

    if (visitor.hasAwait) {
      return;
    }

    // If no imposed return type, then any type is OK.
    if (returnType == null) {
      rule.reportAtToken(asyncKeyword);
      return;
    }

    // We don't have to return anything.
    // So, the generated `Future` is not necessary.
    if (returnType is VoidType) {
      rule.reportAtToken(asyncKeyword);
      return;
    }

    // It is OK to return values into `FutureOr`.
    // So, wrapping values into `Future` is not necessary.
    if (returnType.isDartAsyncFutureOr) {
      rule.reportAtToken(asyncKeyword);
      return;
    }

    // We handle only `Future<T>` below.
    if (!returnType.isDartAsyncFuture) {
      return;
    }

    // If the body may complete normally, we cannot remove `async`.
    // This would make the body return `null`.
    // And `null` is not the same as `Future.value(null)`.
    if (bodyContext.mayCompleteNormally) {
      return;
    }

    // If every `return` returns `Future`, we don't need wrapping.
    if (visitor.everyReturnHasValue && visitor.returnsOnlyFuture) {
      rule.reportAtToken(asyncKeyword);
      return;
    }
  }
}

extension on InterfaceType {
  bool get isDartAsyncFutureOrSubtype {
    var typeProvider = element.library.typeProvider;
    return asInstanceOf(typeProvider.futureElement) != null;
  }
}
