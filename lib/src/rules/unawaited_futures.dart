// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/linter.dart';

const desc =
    'Await for future expression statements inside async function bodies.';

const details = r'''
**DO** await for Future return value of expression statements, or explicitly
ignore those cases.

It's easy to forget await in async methods as naming conventions usually don't
tell us if a method is sync or async (except for some in `dart:io`).

**GOOD:**
```dart
Future doSomething() => ...;

void main() async {
  await doSomething();

  // ignore: unawaited_futures
  doSomething(); // Explicitly-ignored fire-and-forget.
}
```

**BAD:**
```dart
void main() async {
  doSomething(); // Likely a bug.
}
```
''';

class UnawaitedFutures extends LintRule {
  UnawaitedFutures()
      : super(
            name: 'unawaited_futures',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    var expr = node?.expression;
    if (expr is AssignmentExpression) return;

    var type = expr?.staticType;
    if (type?.isDartAsyncFuture == true) {
      // Ignore a couple of special known cases.
      if (_isFutureDelayedInstanceCreationWithComputation(expr) ||
          _isMapPutIfAbsentInvocation(expr)) {
        return;
      }

      // Not in an async function body: assume fire-and-forget.
      var enclosingFunctionBody =
          node.getAncestor((node) => node is FunctionBody) as FunctionBody;
      if (enclosingFunctionBody?.isAsynchronous != true) return;

      // Future expression statement that isn't awaited in an async function:
      // while this is legal, it's a very frequent sign of an error.
      rule.reportLint(node);
    }
  }

  /// Detects `new Future.delayed(duration, [computation])` creations with a
  /// computation.
  bool _isFutureDelayedInstanceCreationWithComputation(Expression expr) =>
      expr is InstanceCreationExpression &&
      expr.staticElement?.enclosingElement?.type?.isDartAsyncFuture == true &&
      expr.constructorName?.name?.name == 'delayed' &&
      expr.argumentList.arguments.length == 2;

  bool _isMapClass(Element e) =>
      e is ClassElement && e.name == 'Map' && e.library?.name == 'dart.core';

  /// Detects Map.putIfAbsent invocations.
  bool _isMapPutIfAbsentInvocation(Expression expr) =>
      expr is MethodInvocation &&
      expr.methodName.name == 'putIfAbsent' &&
      _isMapClass(expr.methodName.staticElement?.enclosingElement);
}
