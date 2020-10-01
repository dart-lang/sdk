// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Use string buffers to compose strings.';

const _details = r'''

**DO** use string buffers to compose strings.

In most cases, using a string buffer is preferred for composing strings due to
its improved performance.

**BAD:**
```
String foo() {
  final buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer += 'a'; // LINT
  }
  return buffer;
}
```

**GOOD:**
```
String foo() {
  final buffer = StringBuffer();
  for (int i = 0; i < 10; i++) {
    buffer.write('a');
  }
  return buffer.toString();
}
```

''';

bool _isEmptyInterpolationString(AstNode node) =>
    node is InterpolationString && node.value == '';

/// The motivation of this rule is performance stuffs, and the explanation is
/// that if we use N strings additions using the + operator the order of that
/// algorithm is O(~N^2) and that is because a String is not mutable, so in each
/// step it creates an auxiliary String that takes O(amount of chars) to be
/// computed, in otherwise using a StringBuffer the order is reduced to O(~N)
/// so the bad case is N times slower than the good case.
class UseStringBuffers extends LintRule implements NodeLintRule {
  UseStringBuffers()
      : super(
            name: 'use_string_buffers',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

class _IdentifierIsPrefixVisitor extends SimpleAstVisitor {
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
    if (node.staticElement == identifier.staticElement) {
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

class _UseStringBufferVisitor extends SimpleAstVisitor {
  final LintRule rule;
  final localElements = <Element>{};

  _UseStringBufferVisitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.PLUS_EQ &&
        node.operator.type != TokenType.EQ) return;

    var left = node.leftHandSide;
    if (left is SimpleIdentifier &&
        DartTypeUtilities.isClass(node.writeType, 'String', 'dart.core')) {
      if (node.operator.type == TokenType.PLUS_EQ &&
          !localElements.contains(
              DartTypeUtilities.getCanonicalElement(node.writeElement))) {
        rule.reportLint(node);
      }
      if (node.operator.type == TokenType.EQ) {
        final visitor = _IdentifierIsPrefixVisitor(rule, left);
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
    for (final variable in node.variables.variables) {
      localElements.add(variable.declaredElement);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    final visitor = _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }

  @override
  void visitForStatement(ForStatement node) {
    final visitor = _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    final visitor = _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }
}
