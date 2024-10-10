// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid using unnecessary statements.';

class UnnecessaryStatements extends LintRule {
  UnnecessaryStatements()
      : super(
          name: LintNames.unnecessary_statements,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_statements;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(_ReportNoClearEffectVisitor(this));
    registry.addExpressionStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addCascadeExpression(this, visitor);
  }
}

/// A visitor that reports expressions that have no clear effect.
///
/// This visitor works a little differently from most. It reports lint rule
/// violations in `visitNode`, a sort of "catch all" location. It also contains
/// many empty-bodied "visit" method overrides that serve to short-circuit a
/// traversal down the syntax tree. Each empty-bodied "visit" method represents
/// a case where an expression can validly act as a statement, as there are
/// common cases where the expression has a clear effect.
///
/// In this way the visitor's visitations are typically very shallow, starting
/// either with a method that just returns without visiting any children, or
/// starting with `visitNode`, which reports a violation and also does not
/// descend. We descend into only a few node types, like binary expressions and
/// conditional expressions.
class _ReportNoClearEffectVisitor extends UnifyingAstVisitor<void> {
  final LintRule rule;

  _ReportNoClearEffectVisitor(this.rule);

  @override
  void visitAsExpression(AsExpression node) {
    //  https://github.com/dart-lang/linter/issues/2163
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    switch (node.operator.lexeme) {
      case '??':
      case '||':
      case '&&':
        // These are OK when used for control flow.
        node.rightOperand.accept(this);
        return;
    }

    super.visitBinaryExpression(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // A few APIs use this for side effects, like Timer. Also, constructors
    // that have side effects typically have tests will often include an
    // instantiation expression statement.
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitNode(AstNode expression) {
    rule.reportLint(expression);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Allow getters; getters with side effects were the main cause of false
    // positives.
    var element = node.identifier.element;
    if (element is GetterElement && !element.isSynthetic) {
      return;
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '--' || node.operator.lexeme == '++') {
      // Has a clear effect. Do not descend.
      return;
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Allow getters; previously getters with side effects were the main cause
    // of false positives.
    var element = node.propertyName.element;
    if (element is GetterElement && !element.isSynthetic) {
      return;
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Allow getter (in this case with an implicit `this.`); previously, getters
    // with side effects were the main cause of false positives.
    var element = node.element;
    if (element is GetterElement && !element.isSynthetic) {
      return;
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // Has a clear effect. Do not descend.
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    // Has a clear effect. Do not descend.
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
    var loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithExpression) {
      loopParts.initialization?.accept(reportNoClearEffect);
      for (var u in loopParts.updaters) {
        u.accept(reportNoClearEffect);
      }
    }
  }
}
