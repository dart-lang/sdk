// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use `forEach` to only apply a function to all the elements.';

class PreferForeach extends LintRule {
  PreferForeach() : super(name: LintNames.prefer_foreach, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferForeach;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
  }
}

class _PreferForEachVisitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  LocalVariableElement? element;
  ForStatement? forEachStatement;

  _PreferForEachVisitor(this.rule);

  @override
  void visitBlock(Block node) {
    if (node.statements.length == 1) {
      node.statements.first.accept(this);
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForEachPartsWithDeclaration) {
      var element = loopParts.loopVariable.declaredFragment?.element;
      if (element != null) {
        forEachStatement = node;
        this.element = element;
        node.body.accept(this);
      }
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var arguments = node.argumentList.arguments;
    if (arguments.length == 1 && arguments.first.canonicalElement == element) {
      rule.reportAtNode(forEachStatement);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var arguments = node.argumentList.arguments;
    var target = node.target;
    if (arguments.length == 1 &&
        arguments.first.canonicalElement == element &&
        (target == null || !_ReferenceFinder(element).references(target))) {
      rule.reportAtNode(forEachStatement);
    }
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }
}

class _ReferenceFinder extends UnifyingAstVisitor<void> {
  bool found = false;
  final LocalVariableElement? element;
  _ReferenceFinder(this.element);

  bool references(Expression target) {
    if (target.canonicalElement == element) return true;

    target.accept(this);
    return found;
  }

  @override
  visitNode(AstNode node) {
    if (found) return;

    found = node.canonicalElement == element;
    if (!found) {
      super.visitNode(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForEachParts) {
      var visitor = _PreferForEachVisitor(rule);
      node.accept(visitor);
    }
  }
}
