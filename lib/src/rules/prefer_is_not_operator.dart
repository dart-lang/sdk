// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer is! operator.';

const _details = r'''
When checking if an object is not of a specified type, it is preferable to use the 'is!' operator.

**BAD:**
```
if (!(foo is Foo)) {
  ...
}
```

**GOOD:**
```
if (foo is! Foo) {
  ...
}
```

''';

class PreferIsNotOperator extends LintRule implements NodeLintRule {
  PreferIsNotOperator()
      : super(
            name: 'prefer_is_not_operator',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addIsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitIsExpression(IsExpression node) {
    // Return if it is `is!` expression
    if (node.notOperator != null) {
      return;
    }

    // Check whether is expression is inside parenthesis
    if (node.parent is ParenthesizedExpression) {
      final parenthesizedExpression = node.parent;
      final prefixExpression = parenthesizedExpression.parent;
      // Check for NOT (!) operator
      if (prefixExpression is PrefixExpression &&
          prefixExpression.operator.type == TokenType.BANG) {
        rule.reportLint(parenthesizedExpression.parent);
      }
    }
  }
}
