// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.whitespace_around_ops;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/linter.dart';

const desc = r'Use proper whitespace around operators.';

const details = r'''
**DO** ensure that there are spaces around binary operators and before any
unary ones.

Improper whitespace can create confusion, especially when applied to operators
where it's possible to get a binary operator when you mean a unary one.  For
example, the mistyping of `5 /~ 10` when you mean `5 ~/ 10` is hidden by the
improper spacing.  (Properly spaced, the mistake is more clear: `5 / ~10`.)
Whenever possible, use the formatter to cleanup whitespace.  Otherwise, take
care to ensure that there are spaces around binary operators and before any
unary ones.


**BAD:**
```
print(5 /~ 10); //whoops
```

**GOOD:**
```
print(5 / ~10); //aha!
```
''';

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (!spaced(node.leftOperand.endToken, node.operator) ||
        !spaced(node.operator, node.rightOperand.beginToken)) {
      rule.reportLintForToken(node.operator);
    }
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    if (spaced(node.operator, node.operand.beginToken)) {
      rule.reportLintForToken(node.operator);
    }
  }

  static bool spaced(Token first, Token second) =>
      first != null && second != null && first.end != second.offset;
}

class WhitespaceAroundOps extends LintRule {
  WhitespaceAroundOps()
      : super(
            name: 'whitespace_around_ops',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}
