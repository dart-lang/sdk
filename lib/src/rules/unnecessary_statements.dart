// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = r'Statements should have a clear effect.';

const details = r'''
**AVOID** unnecessary statments.

Statements which have no clear effect are usually unnecessary, or should be
broken up.

For example.

**BAD:**
```
myvar;
1 + 2;
some.getter;
methodOne() + methodTwo();
foo ? bar : baz;
```

While the getter may trigger a side-effect, it is not usually obvious. And while
the added methods have a clear effect, the addition itself does not unless there
is some magical overload of the + operator.

Usually code like this indicates an incomplete thought, and is a bug. For
instance, the getter was likely supposed to be a function call.

**GOOD:**
```
some.method();
methodOne();
methodTwo();
foo ? bar() : baz();
return myvar;
```
''';

class UnnecessaryStatements extends LintRule {
  UnnecessaryStatements()
      : super(
            name: 'unnecessary_statements',
            description: desc,
            details: details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() =>
      new _Visitor(new _ReportNoClearEffectVisitor(this));
}

class _Visitor extends SimpleAstVisitor {
  final _ReportNoClearEffectVisitor reportNoClearEffect;
  _Visitor(this.reportNoClearEffect);

  @override
  visitExpressionStatement(ExpressionStatement node) {
    if (node.parent is FunctionBody) {
      return;
    }
    node.accept(reportNoClearEffect);
  }

  @override
  visitForStatement(ForStatement node) {
    node.initialization?.accept(reportNoClearEffect);
    node.updaters?.forEach((u) {
      u.accept(reportNoClearEffect);
    });
  }
}

class _ReportNoClearEffectVisitor extends GeneralizingAstVisitor {
  final LintRule rule;
  _ReportNoClearEffectVisitor(this.rule);

  @override
  visitInvocationExpression(InvocationExpression node) {
    // Has a clear effect
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    // Has a clear effect
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    // Has a clear effect
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    // Has a clear effect
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    // Has a clear effect
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '--' || node.operator.lexeme == '++') {
      // Has a clear effect
      return;
    }
    super.visitPrefixExpression(node);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    // Has a clear effect
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    // Has a clear effect
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    switch (node.operator.lexeme) {
      case '??':
      case '||':
      case '&&':
        // these are OK when used for control flow
        node.rightOperand.accept(this);
        return;
    }

    super.visitBinaryExpression(node);
  }

  @override
  visitExpression(Expression expression) {
    rule.reportLint(expression);
  }
}
