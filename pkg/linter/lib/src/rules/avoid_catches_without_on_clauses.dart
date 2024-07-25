// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid catches without on clauses.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#avoid-catches-without-on-clauses):

**AVOID** catches without on clauses.

Using catch clauses without on clauses make your code prone to encountering
unexpected errors that won't be thrown (and thus will go unnoticed).

**BAD:**
```dart
try {
 somethingRisky()
} catch(e) {
  doSomething(e);
}
```

**GOOD:**
```dart
try {
 somethingRisky()
} on Exception catch(e) {
  doSomething(e);
}
```

A few exceptional cases are allowed:

* If the body of the catch rethrows the exception.
* If the caught exception is "directly used" in an argument to `Future.error`,
  `Completer.completeError`, or `FlutterError.reportError`, or any function with
  a return type of `Never`.
* If the caught exception is "directly used" in a new throw-expression.

In these cases, "directly used" means that the exception is referenced within
the relevant code (like within an argument). If the exception variable is
referenced _before_ the relevant code, for example to instantiate a wrapper
exception, the variable is not "directly used."

''';

class AvoidCatchesWithoutOnClauses extends LintRule {
  static const LintCode code = LintCode(
      'avoid_catches_without_on_clauses',
      "Catch clause should use 'on' to specify the type of exception being "
          'caught.',
      correctionMessage: "Try adding an 'on' clause before the 'catch'.");

  AvoidCatchesWithoutOnClauses()
      : super(
            name: 'avoid_catches_without_on_clauses',
            description: _desc,
            details: _details,
            categories: {
              LintRuleCategory.effectiveDart,
              LintRuleCategory.style
            });

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _CaughtExceptionUseVisitor extends RecursiveAstVisitor<void> {
  final Element caughtException;

  var exceptionWasUsed = false;

  _CaughtExceptionUseVisitor(this.caughtException);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement == caughtException) {
      exceptionWasUsed = true;
    }
  }
}

class _ValidUseVisitor extends RecursiveAstVisitor<void> {
  final Element caughtException;

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
      var targetElement = target is Identifier ? target.staticElement : null;
      if (targetElement is ClassElement &&
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
    var caughtException = node.exceptionParameter?.declaredElement;
    if (caughtException == null) return;

    var validUseVisitor = _ValidUseVisitor(caughtException);
    node.body.accept(validUseVisitor);
    if (validUseVisitor.hasValidUse) return;

    rule.reportLintForToken(node.catchKeyword);
  }
}
