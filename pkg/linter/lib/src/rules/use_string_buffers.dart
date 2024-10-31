// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Use string buffers to compose strings.';

bool _isEmptyInterpolationString(AstNode node) =>
    node is InterpolationString && node.value == '';

/// The motivation of this rule is performance stuffs, and the explanation is
/// that if we use N strings additions using the + operator the order of that
/// algorithm is O(~N^2) and that is because a String is not mutable, so in each
/// step it creates an auxiliary String that takes O(amount of chars) to be
/// computed, in otherwise using a StringBuffer the order is reduced to O(~N)
/// so the bad case is N times slower than the good case.
class UseStringBuffers extends LintRule {
  UseStringBuffers()
      : super(
          name: LintNames.use_string_buffers,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_string_buffers;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

class _IdentifierIsPrefixVisitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  SimpleIdentifier identifier;

  _IdentifierIsPrefixVisitor(this.rule, this.identifier);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.PLUS) {
      node.leftOperand.accept(this);
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == identifier.element) {
      rule.reportLint(identifier);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.elements.length >= 2 &&
        _isEmptyInterpolationString(node.elements.first)) {
      node.elements[1].accept(this);
    }
  }
}

class _UseStringBufferVisitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final localElements = <Element2?>{};

  _UseStringBufferVisitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.PLUS_EQ &&
        node.operator.type != TokenType.EQ) {
      return;
    }

    var left = node.leftHandSide;
    var writeType = node.writeType;
    if (left is SimpleIdentifier &&
        writeType is InterfaceType &&
        writeType.isDartCoreString) {
      if (node.operator.type == TokenType.PLUS_EQ &&
          !localElements.contains(node.writeElement2)) {
        rule.reportLint(node);
      }
      if (node.operator.type == TokenType.EQ) {
        var visitor = _IdentifierIsPrefixVisitor(rule, left);
        node.rightHandSide.accept(visitor);
      }
    }
  }

  @override
  void visitBlock(Block block) {
    block.visitChildren(this);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (var variable in node.variables.variables) {
      localElements.add(variable.declaredElement2);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    var visitor = _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }

  @override
  void visitForStatement(ForStatement node) {
    var visitor = _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    var visitor = _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }
}
