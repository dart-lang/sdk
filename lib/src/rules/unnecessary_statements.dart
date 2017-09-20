// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Statements should have a clear effect.';

const details = r'''
**AVOID** unnecessary statements.

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
new SomeClass();
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
    node.expression.accept(reportNoClearEffect);
  }

  @override
  visitForStatement(ForStatement node) {
    node.initialization?.accept(reportNoClearEffect);
    node.updaters?.forEach((u) {
      u.accept(reportNoClearEffect);
    });
  }
}

class _ReportNoClearEffectVisitor extends UnifyingAstVisitor {
  final LintRule rule;
  _ReportNoClearEffectVisitor(this.rule);

  @override
  visitMethodInvocation(MethodInvocation node) {
    // Has a clear effect
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // Has a clear effect
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
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
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    // A few APIs use this for side effects, like Timer. Also, for constructors
    // that have side effects, they should have tests. Those tests will often
    // include an instantiation expression statement with nothing else.
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
  visitNode(AstNode expression) {
    rule.reportLint(expression);
  }
}
