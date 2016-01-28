// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';

import 'ast_builder.dart';

/// Creates an index of variable assignments and declarations occurring in all
/// the provided [nodes].
///
/// Expands any compound assignment expression (e.g. `i += 2` yields an assigned
/// expression of `i + 2`), and treats declarations with no assignment as having
/// a `null` assigned expression.
Map<LocalVariableElement, List<Expression>> indexLocalAssignments(
    Iterable<AstNode> nodes) {
  var visitor = new _LocalAssignmentsVisitor();
  nodes.forEach((n) => n.accept(visitor));
  return visitor.assignedExpressions;
}

/// Visits variable declarations and assignments and exposes an
/// [AssignmentIndex] interface.
///
// TODO(ochafik): Introduce flow analysis (a variable may be nullable in
// some places and not in others).
class _LocalAssignmentsVisitor extends RecursiveAstVisitor {
  final assignedExpressions = <LocalVariableElement, List<Expression>>{};

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    var element = node.element;
    if (element is LocalVariableElement) {
      _addAssignment(element, node.initializer ?? AstBuilder.nullLiteral());
    }
    super.visitVariableDeclaration(node);
  }

  @override
  visitCatchClause(CatchClause node) {
    for (var ident in [node.exceptionParameter, node.stackTraceParameter]) {
      if (ident == null) continue;
      assert(ident.staticElement is LocalVariableElement);
      _addAssignment(ident.staticElement, AstBuilder.nullLiteral());
    }
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    var lhs = node.leftHandSide;
    var e = _getLocalVariable(lhs);
    if (e != null) _addAssignment(e, node.rightHandSide);
    super.visitAssignmentExpression(node);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    var op = node.operator.type;
    if (op.isAssignmentOperator) {
      var e = _getLocalVariable(node.leftOperand);
      if (e != null) {
        // TODO(ochafik): Once we have non-nullable types, compute the static
        // type for this AST node.
        _addAssignment(
            e,
            RawAstBuilder.binaryExpression(node.leftOperand,
                _opToken(_expandAssignmentOp(op)), node.rightOperand));
      }
    }
    super.visitBinaryExpression(node);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    var op = node.operator.type;
    if (op.isAssignmentOperator) {
      // Treat `x++` as statically assigning `x + 1` to variable `x`.
      var e = _getLocalVariable(node.operand);
      if (e != null) _handleIncrOrDecr(e, node.operand, op);
    }
    super.visitPostfixExpression(node);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    var op = node.operator.type;
    if (op.isAssignmentOperator) {
      // Treat `++x` as statically assigning `x + 1` to variable `x`.
      var e = _getLocalVariable(node.operand);
      if (e != null) _handleIncrOrDecr(e, node.operand, op);
    }
    super.visitPrefixExpression(node);
  }

  /// Note: we're not interested in differences between prefix & suffix.
  _handleIncrOrDecr(LocalVariableElement e, Expression operand, TokenType op) {
    if (!op.isIncrementOperator) throw new ArgumentError('Unexpected op: $op');
    // TODO(ochafik): Once we have non-nullable types, compute the static
    // type for this AST node.
    _addAssignment(
        e,
        RawAstBuilder.binaryExpression(
            operand, _opToken(op), AstBuilder.integerLiteral(1)));
  }

  void _addAssignment(VariableElement e, Expression value) =>
      assignedExpressions.putIfAbsent(e, () => <Expression>[]).add(value);

  LocalVariableElement _getLocalVariable(Expression target) {
    if (target is SimpleIdentifier) {
      var e = target.bestElement;
      if (e is LocalVariableElement && e is! PropertyAccessorElement) {
        return e;
      }
    }
    return null;
  }
}

const Map<TokenType, TokenType> _opByAssignmentOp = const {
  TokenType.AMPERSAND_EQ: TokenType.AMPERSAND,
  TokenType.BAR_EQ: TokenType.BAR,
  TokenType.CARET_EQ: TokenType.CARET,
  TokenType.GT_GT_EQ: TokenType.GT_GT,
  TokenType.LT_LT_EQ: TokenType.LT_LT,
  TokenType.MINUS_EQ: TokenType.MINUS,
  TokenType.PERCENT_EQ: TokenType.PERCENT,
  TokenType.PLUS_EQ: TokenType.PLUS,
  TokenType.QUESTION_QUESTION_EQ: TokenType.QUESTION_QUESTION,
  TokenType.SLASH_EQ: TokenType.SLASH,
  TokenType.STAR_EQ: TokenType.STAR,
  TokenType.TILDE_SLASH_EQ: TokenType.TILDE_SLASH,
};

Token _opToken(TokenType t) => new Token(t, 0);

/// Transforms `+=` to `+`, `??=` to `??`, etc.
TokenType _expandAssignmentOp(TokenType assignmentOp) {
  assert(assignmentOp.isAssignmentOperator);
  var op = _opByAssignmentOp[assignmentOp];
  if (op == null) throw new ArgumentError("Can't expand op $assignmentOp");
  return op;
}
