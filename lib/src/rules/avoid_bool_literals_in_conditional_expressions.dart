// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r'Avoid bool literals in conditional expressions.';

const _details = r'''

**AVOID** bool literals in conditional expressions.

**BAD:**
```
condition ? true : boolExpression
condition ? false : boolExpression
condition ? boolExpression : true
condition ? boolExpression : false
```

**GOOD:**
```
condition || boolExpression
!condition && boolExpression
!condition || boolExpression
condition && boolExpression
```

''';

class AvoidBoolLiteralsInConditionalExpressions extends LintRule {
  AvoidBoolLiteralsInConditionalExpressions()
      : super(
            name: 'avoid_bool_literals_in_conditional_expressions',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitConditionalExpression(ConditionalExpression node) {
    final typeProvider = getCompilationUnit(node).element.context.typeProvider;
    final thenExp = node.thenExpression;
    final elseExp = node.elseExpression;

    if (thenExp.bestType == typeProvider.boolType &&
        elseExp.bestType == typeProvider.boolType) {
      if (thenExp is BooleanLiteral) rule.reportLint(node);
      if (elseExp is BooleanLiteral) rule.reportLint(node);
    }
  }
}
