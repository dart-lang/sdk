// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

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
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(_ReportNoClearEffectVisitor(this));
    registry.addExpressionStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
  }
}

class _ReportNoClearEffectVisitor extends UnifyingAstVisitor {
  final LintRule rule;

  _ReportNoClearEffectVisitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // Has a clear effect
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    // Has a clear effect
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
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
  void visitCascadeExpression(CascadeExpression node) {
    // Has a clear effect
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // Has a clear effect
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // A few APIs use this for side effects, like Timer. Also, for constructors
    // that have side effects, they should have tests. Those tests will often
    // include an instantiation expression statement with nothing else.
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Has a clear effect
  }

  @override
  void visitNode(AstNode expression) {
    rule.reportLint(expression);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    // Has a clear effect
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Allow getters; getters with side effects were the main cause of false
    // positives.
    var element = node.identifier.staticElement;
    if (element is PropertyAccessorElement && !element.isSynthetic) {
      return;
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '--' || node.operator.lexeme == '++') {
      // Has a clear effect
      return;
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Allow getters; getters with side effects were the main cause of false
    // positives.
    var element = node.propertyName.staticElement;
    if (element is PropertyAccessorElement && !element.isSynthetic) {
      return;
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    // Has a clear effect
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Allow getters; getters with side effects were the main cause of false
    // positives.
    var element = node.staticElement;
    if (element is PropertyAccessorElement && !element.isSynthetic) {
      return;
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // Has a clear effect
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    // Has a clear effect
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final _ReportNoClearEffectVisitor reportNoClearEffect;

  _Visitor(this.reportNoClearEffect);
  @override
  void visitCascadeExpression(CascadeExpression node) {
    for (var section in node.cascadeSections) {
      if (section is PropertyAccess && section.staticType is FunctionType) {
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
    final loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithExpression) {
      loopParts.initialization?.accept(reportNoClearEffect);
      loopParts.updaters?.forEach((u) {
        u.accept(reportNoClearEffect);
      });
    }
  }
}
