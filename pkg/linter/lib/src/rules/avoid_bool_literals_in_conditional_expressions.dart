// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid `bool` literals in conditional expressions.';

const _details = r'''
**AVOID** `bool` literals in conditional expressions.

**BAD:**
```dart
condition ? true : boolExpression
condition ? false : boolExpression
condition ? boolExpression : true
condition ? boolExpression : false
```

**GOOD:**
```dart
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
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.avoid_bool_literals_in_conditional_expressions;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    var typeProvider = context.typeProvider;
    var thenExp = node.thenExpression.unParenthesized;
    var elseExp = node.elseExpression.unParenthesized;

    if (thenExp.staticType == typeProvider.boolType &&
        elseExp.staticType == typeProvider.boolType) {
      if (thenExp is BooleanLiteral) rule.reportLint(node);
      if (elseExp is BooleanLiteral) rule.reportLint(node);
    }
  }
}
