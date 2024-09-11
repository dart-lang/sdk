// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc =
    r'Use => for short members whose body is a single return statement.';

const _details = r'''
**CONSIDER** using => for short members whose body is a single return statement.

**BAD:**
```dart
get width {
  return right - left;
}
```

**BAD:**
```dart
bool ready(num time) {
  return minTime == null || minTime <= time;
}
```

**BAD:**
```dart
containsValue(String value) {
  return getValues().contains(value);
}
```

**GOOD:**
```dart
get width => right - left;
```

**GOOD:**
```dart
bool ready(num time) => minTime == null || minTime <= time;
```

**GOOD:**
```dart
containsValue(String value) => getValues().contains(value);
```

''';

class PreferExpressionFunctionBodies extends LintRule {
  PreferExpressionFunctionBodies()
      : super(
          name: 'prefer_expression_function_bodies',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_expression_function_bodies;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addBlockFunctionBody(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    var statements = node.block.statements;
    if (statements.length != 1) return;

    var uniqueStatement = node.block.statements.single;
    if (uniqueStatement is! ReturnStatement) return;
    if (uniqueStatement.expression == null) return;

    rule.reportLint(node);
  }
}
