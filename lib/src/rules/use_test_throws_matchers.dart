// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Use throwsA matcher instead of fail().';

const _details = r'''
Use the `throwsA` matcher instead of try-catch with `fail()`.

**BAD:**

```dart
// sync code
try {
  someSyncFunctionThatThrows();
  fail('expected Error');
} on Error catch (error) {
  expect(error.message, contains('some message'));
}

// async code
try {
  await someAsyncFunctionThatThrows();
  fail('expected Error');
} on Error catch (error) {
  expect(error.message, contains('some message'));
}
```

**GOOD:**
```dart
// sync code
expect(
  () => someSyncFunctionThatThrows(),
  throwsA(isA<Error>().having((Error error) => error.message, 'message', contains('some message'))),
);

// async code
await expectLater(
  () => someAsyncFunctionThatThrows(),
  throwsA(isA<Error>().having((Error error) => error.message, 'message', contains('some message'))),
);
```

''';

class UseTestThrowsMatchers extends LintRule {
  static const LintCode code = LintCode(
      'use_test_throws_matchers',
      "Use the 'throwsA' matcher instead of using 'fail' when there is no "
          'exception thrown.',
      correctionMessage:
          "Try removing the try-catch and using 'throwsA' to expect an exception.");

  UseTestThrowsMatchers()
      : super(
          name: 'use_test_throws_matchers',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addTryStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isTestInvocation(Statement statement, String functionName) {
    if (statement is! ExpressionStatement) return false;
    var expression = statement.expression;
    if (expression is! MethodInvocation) return false;
    var element = expression.methodName.staticElement;
    return element is FunctionElement &&
        element.source.uri ==
            Uri.parse('package:test_api/src/frontend/expect.dart') &&
        element.name == functionName;
  }

  @override
  void visitTryStatement(TryStatement node) {
    if (node.catchClauses.length != 1 || node.body.statements.isEmpty) return;

    var lastBodyStatement = node.body.statements.last;

    if (isTestInvocation(lastBodyStatement, 'fail') &&
        node.finallyBlock == null) {
      rule.reportLint(lastBodyStatement);
    }
  }
}
