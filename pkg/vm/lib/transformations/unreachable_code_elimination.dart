// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Simple unreachable code elimination: removes asserts and if statements
/// with constant conditions. Does a very limited constant folding of
/// logical expressions.
Component transformComponent(Component component, bool enableAsserts) {
  new SimpleUnreachableCodeElimination(enableAsserts).visitComponent(component);
  return component;
}

class SimpleUnreachableCodeElimination extends Transformer {
  final bool enableAsserts;

  SimpleUnreachableCodeElimination(this.enableAsserts);

  bool _isBoolConstant(Expression node) =>
      node is BoolLiteral ||
      (node is ConstantExpression && node.constant is BoolConstant);

  bool _getBoolConstantValue(Expression node) {
    if (node is BoolLiteral) {
      return node.value;
    }
    if (node is ConstantExpression) {
      final constant = node.constant;
      if (constant is BoolConstant) {
        return constant.value;
      }
    }
    throw 'Expected bool constant: $node';
  }

  Expression _createBoolLiteral(bool value, int fileOffset) =>
      new BoolLiteral(value)..fileOffset = fileOffset;

  Statement _makeEmptyBlockIfNull(Statement node, TreeNode parent) =>
      node == null ? (Block(<Statement>[])..parent = parent) : node;

  @override
  TreeNode visitIfStatement(IfStatement node) {
    node.transformChildren(this);
    final condition = node.condition;
    if (_isBoolConstant(condition)) {
      final value = _getBoolConstantValue(condition);
      return value ? node.then : node.otherwise;
    }
    node.then = _makeEmptyBlockIfNull(node.then, node);
    return node;
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    node.transformChildren(this);
    final condition = node.condition;
    if (_isBoolConstant(condition)) {
      final value = _getBoolConstantValue(condition);
      return value ? node.then : node.otherwise;
    }
    return node;
  }

  @override
  TreeNode visitNot(Not node) {
    node.transformChildren(this);
    final operand = node.operand;
    if (_isBoolConstant(operand)) {
      return _createBoolLiteral(
          !_getBoolConstantValue(operand), node.fileOffset);
    }
    return node;
  }

  @override
  TreeNode visitLogicalExpression(LogicalExpression node) {
    node.transformChildren(this);
    final left = node.left;
    final right = node.right;
    final operatorEnum = node.operatorEnum;
    if (_isBoolConstant(left)) {
      final leftValue = _getBoolConstantValue(left);
      if (_isBoolConstant(right)) {
        final rightValue = _getBoolConstantValue(right);
        if (operatorEnum == LogicalExpressionOperator.OR) {
          return _createBoolLiteral(leftValue || rightValue, node.fileOffset);
        } else if (operatorEnum == LogicalExpressionOperator.AND) {
          return _createBoolLiteral(leftValue && rightValue, node.fileOffset);
        } else {
          throw 'Unexpected LogicalExpression operator ${operatorEnum}: $node';
        }
      } else {
        if (leftValue && operatorEnum == LogicalExpressionOperator.OR) {
          return _createBoolLiteral(true, node.fileOffset);
        } else if (!leftValue &&
            operatorEnum == LogicalExpressionOperator.AND) {
          return _createBoolLiteral(false, node.fileOffset);
        }
      }
    }
    return node;
  }

  @override
  visitStaticGet(StaticGet node) {
    node.transformChildren(this);
    final target = node.target;
    if (target is Field && target.isConst) {
      throw 'StaticGet from const field $target should be evaluated by front-end: $node';
    }
    return node;
  }

  @override
  TreeNode visitAssertStatement(AssertStatement node) {
    if (!enableAsserts) {
      return null;
    }
    return super.visitAssertStatement(node);
  }

  @override
  TreeNode visitAssertBlock(AssertBlock node) {
    if (!enableAsserts) {
      return null;
    }
    return super.visitAssertBlock(node);
  }

  @override
  TreeNode visitAssertInitializer(AssertInitializer node) {
    if (!enableAsserts) {
      return null;
    }
    return super.visitAssertInitializer(node);
  }

  @override
  TreeNode visitTryFinally(TryFinally node) {
    node.transformChildren(this);
    final fin = node.finalizer;
    if (fin == null || (fin is Block && fin.statements.isEmpty)) {
      return node.body;
    }
    return node;
  }

  bool _isRethrow(Statement body) {
    if (body is ExpressionStatement && body.expression is Rethrow) {
      return true;
    } else if (body is Block && body.statements.length == 1) {
      return _isRethrow(body.statements.single);
    }
    return false;
  }

  @override
  TreeNode visitTryCatch(TryCatch node) {
    node.transformChildren(this);
    // Can replace try/catch with its body if all catches are just rethow.
    for (Catch catchClause in node.catches) {
      if (!_isRethrow(catchClause.body)) {
        return node;
      }
    }
    return node.body;
  }

  // Make sure we're not generating `null` bodies.
  // Try/catch, try/finally and switch/case statements
  // always have a Block in a body, so there is no
  // need to guard against null.

  @override
  TreeNode visitWhileStatement(WhileStatement node) {
    node.transformChildren(this);
    node.body = _makeEmptyBlockIfNull(node.body, node);
    return node;
  }

  @override
  TreeNode visitDoStatement(DoStatement node) {
    node.transformChildren(this);
    node.body = _makeEmptyBlockIfNull(node.body, node);
    return node;
  }

  @override
  TreeNode visitForStatement(ForStatement node) {
    node.transformChildren(this);
    node.body = _makeEmptyBlockIfNull(node.body, node);
    return node;
  }

  @override
  TreeNode visitForInStatement(ForInStatement node) {
    node.transformChildren(this);
    node.body = _makeEmptyBlockIfNull(node.body, node);
    return node;
  }
}
