// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.unnecessary_null_in_if_null_operator;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Avoid null in if null operator';

const details = '''
Avoid null as operand in if null operator. `a ?? null` and `null ?? a` can both
be replaced by `a`.

**GOOD:**

```
var x = a ?? 1;
```

**BAD:**

```
var x = a ?? null;
var y = null ?? 1;
```
''';

class UnnecessaryNullInIfNullOperator extends LintRule {
  UnnecessaryNullInIfNullOperator()
      : super(
            name: 'unnecessary_null_in_if_null_operator',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION &&
        (node.rightOperand is NullLiteral || node.leftOperand is NullLiteral)) {
      rule.reportLint(node);
    }
  }
}
