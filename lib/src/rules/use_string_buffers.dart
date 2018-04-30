// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Use string buffer to compose strings.';

const _details = r'''

**DO** use string buffer to compose strings.

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
  final buffer = new StringBuffer();
  for (int i = 0; i < 10; i++) {
    buffer.write('a');
  }
  return buffer.toString();
}
```

''';

SimpleIdentifier _getSimpleIdentifier(Expression rawExpression) {
  final expression = rawExpression.unParenthesized;
  return expression is SimpleIdentifier ? expression : null;
}

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
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForEachStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

class _IdentifierIsPrefixVisitor extends SimpleAstVisitor {
  final LintRule rule;
  SimpleIdentifier identifier;

  _IdentifierIsPrefixVisitor(this.rule, this.identifier);

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.PLUS) {
      node.leftOperand.accept(this);
    }
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) {
    node.expression.accept(this);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.bestElement == identifier.bestElement) {
      rule.reportLint(identifier);
    }
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    if (node.elements.length >= 2 &&
        _isEmptyInterpolationString(node.elements.first)) {
      node.elements[1].accept(this);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    final visitor = new _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    final visitor = new _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }

  @override
  void visitForStatement(ForStatement node) {
    final visitor = new _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    final visitor = new _UseStringBufferVisitor(rule);
    node.body.accept(visitor);
  }
}

class _UseStringBufferVisitor extends SimpleAstVisitor {
  final LintRule rule;
  final localElements = new Set<Element>();

  _UseStringBufferVisitor(this.rule);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.PLUS_EQ &&
        node.operator.type != TokenType.EQ) return;

    final identifier = _getSimpleIdentifier(node.leftHandSide);
    if (identifier != null &&
        DartTypeUtilities.isClass(identifier.bestType, 'String', 'dart.core')) {
      if (node.operator.type == TokenType.PLUS_EQ &&
          !localElements.contains(
              DartTypeUtilities.getCanonicalElement(identifier.bestElement))) {
        rule.reportLint(node);
      }
      if (node.operator.type == TokenType.EQ) {
        final visitor = new _IdentifierIsPrefixVisitor(rule, identifier);
        node.rightHandSide.accept(visitor);
      }
    }
  }

  @override
  visitBlock(Block block) {
    block.visitChildren(this);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (final variable in node.variables.variables) {
      localElements.add(variable.element);
    }
  }
}
