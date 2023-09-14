// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r"Don't invoke asynchronous functions in non-async blocks.";

const _details = r'''
Making asynchronous calls in non-`async` functions is usually the sign of a
programming error.  In general these functions should be marked `async` and such
futures should likely be awaited (as enforced by `unawaited_futures`).

**DON'T** invoke asynchronous functions in non-`async` blocks.

**BAD:**
```dart
void recreateDir(String path) {
  deleteDir(path);
  createDir(path);
}

Future<void> deleteDir(String path) async {}

Future<void> createDir(String path) async {}
```

**GOOD:**
```dart
Future<void> recreateDir(String path) async {
  await deleteDir(path);
  await createDir(path);
}

Future<void> deleteDir(String path) async {}

Future<void> createDir(String path) async {}
```
''';

class DiscardedFutures extends LintRule {
  static const LintCode code = LintCode('discarded_futures',
      "Asynchronous function invoked in a non-'async' function.",
      correctionMessage:
          "Try converting the enclosing function to be 'async' and then "
          "'await' the future.");

  DiscardedFutures()
      : super(
            name: 'discarded_futures',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _InvocationVisitor extends RecursiveAstVisitor<void> {
  final LintRule rule;
  _InvocationVisitor(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.body.isAsynchronous) return;
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.staticInvokeType.isFuture) {
      rule.reportLint(node.function);
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.staticElement.isDartAsyncUnawaited) return;
    if (node.staticInvokeType.isFuture) {
      rule.reportLint(node.methodName);
    }
    super.visitMethodInvocation(node);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  void check(FunctionBody body) {
    if (body.isAsynchronous) return;
    var visitor = _InvocationVisitor(rule);
    body.accept(visitor);
  }

  void checkVariables(VariableDeclarationList variables) {
    if (variables.type?.type?.isFuture ?? false) return;
    for (var variable in variables.variables) {
      var initializer = variable.initializer;
      if (initializer is FunctionExpression) {
        check(initializer.body);
      }
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    check(node.body);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    checkVariables(node.fields);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.returnType?.type.isFuture ?? false) return;
    check(node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.returnType?.type.isFuture ?? false) return;
    check(node.body);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    checkVariables(node.variables);
  }
}

extension on DartType? {
  bool get isFuture {
    var self = this;
    DartType? returnType;
    if (self is FunctionType) {
      returnType = self.returnType;
    }
    if (self is InterfaceType) {
      returnType = self;
    }

    return returnType != null &&
        (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr);
  }
}

extension ElementExtension on Element? {
  bool get isDartAsyncUnawaited {
    var self = this;
    return self is FunctionElement &&
        self.name == 'unawaited' &&
        self.library.isDartAsync;
  }
}
