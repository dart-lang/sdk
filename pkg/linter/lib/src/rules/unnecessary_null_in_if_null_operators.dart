// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid using `null` in `??` operators.';

const _details = r'''
**AVOID** using `null` as an operand in `??` operators.

Using `null` in an `if null` operator is redundant, regardless of which side
`null` is used on.

**BAD:**
```dart
var x = a ?? null;
var y = null ?? 1;
```

**GOOD:**
```dart
var x = a ?? 1;
```

''';

class UnnecessaryNullInIfNullOperators extends LintRule {
  UnnecessaryNullInIfNullOperators()
      : super(
          name: 'unnecessary_null_in_if_null_operators',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_null_in_if_null_operators;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION) {
      if (node.rightOperand.isNullLiteral) {
        rule.reportLint(node.rightOperand);
      } else if (node.leftOperand.isNullLiteral) {
        rule.reportLint(node.leftOperand);
      }
    }
  }
}
