// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid catches without on clauses.';

class AvoidCatchesWithoutOnClauses extends LintRule {
  AvoidCatchesWithoutOnClauses()
      : super(
          name: LintNames.avoid_catches_without_on_clauses,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_catches_without_on_clauses;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _CaughtExceptionUseVisitor extends RecursiveAstVisitor<void> {
  final Element2 caughtException;

  var exceptionWasUsed = false;

  _CaughtExceptionUseVisitor(this.caughtException);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == caughtException) {
      exceptionWasUsed = true;
    }
  }
}

class _ValidUseVisitor extends RecursiveAstVisitor<void> {
  final Element2 caughtException;

  bool hasValidUse = false;

  var _canRethrow = true;

  _ValidUseVisitor(this.caughtException);

  @override
  void visitCatchClause(CatchClause node) {
    _canRethrow = false;
    super.visitCatchClause(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.staticType is NeverType) {
      _checkUseInArgument(node.argumentList);
      return;
    }

    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.name?.name == 'error' &&
        node.staticType.isSameAs('Future', 'dart.async')) {
      _checkUseInArgument(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.staticType is NeverType) {
      _checkUseInArgument(node.argumentList);
    } else if (node.methodName.name == 'reportError') {
      var target = node.realTarget;
      var targetElement = target is Identifier ? target.element : null;
      if (targetElement is ClassElement2 &&
          targetElement.name == 'FlutterError') {
        _checkUseInArgument(node.argumentList);
      }
    } else if (node.methodName.name == 'completeError') {
      var type = node.realTarget?.staticType;
      if (type != null) {
        if (type.extendsClass('Completer', 'dart.async')) {
          _checkUseInArgument(node.argumentList);
        }
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    hasValidUse = _canRethrow;
    super.visitRethrowExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    var caughtExceptionUseVisitor = _CaughtExceptionUseVisitor(caughtException);
    node.accept(caughtExceptionUseVisitor);
    if (caughtExceptionUseVisitor.exceptionWasUsed) {
      hasValidUse = true;
    }
    super.visitThrowExpression(node);
  }

  void _checkUseInArgument(ArgumentList node) {
    // Check whether any argument has a reference to `caughtException`.
    var caughtExceptionUseVisitor = _CaughtExceptionUseVisitor(caughtException);
    node.accept(caughtExceptionUseVisitor);
    if (caughtExceptionUseVisitor.exceptionWasUsed) {
      hasValidUse = true;
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCatchClause(CatchClause node) {
    if (node.onKeyword != null) return;
    var caughtException = node.exceptionParameter?.declaredElement2;
    if (caughtException == null) return;

    var validUseVisitor = _ValidUseVisitor(caughtException);
    node.body.accept(validUseVisitor);
    if (validUseVisitor.hasValidUse) return;

    rule.reportLintForToken(node.catchKeyword);
  }
}
