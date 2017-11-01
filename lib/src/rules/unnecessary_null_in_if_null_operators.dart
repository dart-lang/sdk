// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid using `null` in `if null` operators.';

const _details = r'''

**AVOID** using `null` as an operand in `if null` operators.

Using `null` in an `if null` operator is redundant, regardless of which side
`null` is used on.

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

class UnnecessaryNullInIfNullOperators extends LintRule {
  UnnecessaryNullInIfNullOperators()
      : super(
            name: 'unnecessary_null_in_if_null_operators',
            description: _desc,
            details: _details,
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
        (DartTypeUtilities.isNullLiteral(node.rightOperand) ||
            DartTypeUtilities.isNullLiteral(node.leftOperand))) {
      rule.reportLint(node);
    }
  }
}
