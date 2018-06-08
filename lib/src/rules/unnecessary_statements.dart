// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid using unnecessary statements.';

const _details = r'''

**AVOID** using unnecessary statements.

Statements which have no clear effect are usually unnecessary, or should be
broken up.

For example,

**BAD:**
```
myvar;
list.clear;
1 + 2;
methodOne() + methodTwo();
foo ? bar : baz;
```

Though the added methods have a clear effect, the addition itself does not
unless there is some magical overload of the + operator.

Usually code like this indicates an incomplete thought, and is a bug.

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

class UnnecessaryStatements extends LintRule implements NodeLintRule {
  UnnecessaryStatements()
      : super(
            name: 'unnecessary_statements',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(new _ReportNoClearEffectVisitor(this));
    registry.addExpressionStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final _ReportNoClearEffectVisitor reportNoClearEffect;

  _Visitor(this.reportNoClearEffect);
  @override
  void visitCascadeExpression(CascadeExpression node) {
    for (var section in node.cascadeSections) {
      if (section is PropertyAccess && section.bestType is FunctionType) {
        reportNoClearEffect.rule.reportLint(section);
      }
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    if (node.parent is FunctionBody) {
      return;
    }
    node.expression.accept(reportNoClearEffect);
  }

  @override
  void visitForStatement(ForStatement node) {
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
  visitAssignmentExpression(AssignmentExpression node) {
    // Has a clear effect
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    // Has a clear effect
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
  visitCascadeExpression(CascadeExpression node) {
    // Has a clear effect
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // Has a clear effect
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    // A few APIs use this for side effects, like Timer. Also, for constructors
    // that have side effects, they should have tests. Those tests will often
    // include an instantiation expression statement with nothing else.
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    // Has a clear effect
  }

  @override
  visitNode(AstNode expression) {
    rule.reportLint(expression);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    // Has a clear effect
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Allow getters; they may have a side effect.
    if (node.identifier.bestElement is PropertyAccessorElement) return;

    super.visitPrefixedIdentifier(node);
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
  visitPropertyAccess(PropertyAccess node) {
    // Allow getters; they may have a side effect.
    if (node.propertyName.bestElement is PropertyAccessorElement) return;

    super.visitPropertyAccess(node);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    // Has a clear effect
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // Has a clear effect
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    // Allow getters; they may have a side effect.
    if (node.bestElement is PropertyAccessorElement) return;

    super.visitSimpleIdentifier(node);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    // Has a clear effect
  }
}
