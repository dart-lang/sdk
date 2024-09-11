// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Use rethrow to rethrow a caught exception.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#do-use-rethrow-to-rethrow-a-caught-exception):

**DO** use rethrow to rethrow a caught exception.

As Dart provides rethrow as a feature, it should be used to improve terseness
and readability.

**BAD:**
```dart
try {
  somethingRisky();
} catch(e) {
  if (!canHandle(e)) throw e;
  handle(e);
}
```

**GOOD:**
```dart
try {
  somethingRisky();
} catch(e) {
  if (!canHandle(e)) rethrow;
  handle(e);
}
```

''';

class UseRethrowWhenPossible extends LintRule {
  UseRethrowWhenPossible()
      : super(
          name: 'use_rethrow_when_possible',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_rethrow_when_possible;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (node.parent is! ExpressionStatement) return;

    var element = node.expression.canonicalElement;
    if (element != null) {
      var catchClause = node.thisOrAncestorOfType<CatchClause>();
      var exceptionParameter =
          catchClause?.exceptionParameter?.declaredElement?.canonicalElement;
      if (element == exceptionParameter) {
        rule.reportLint(node);
      }
    }
  }
}
