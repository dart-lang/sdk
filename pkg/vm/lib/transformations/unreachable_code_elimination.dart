// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart' show StaticTypeContext;

import 'vm_constant_evaluator.dart' show VMConstantEvaluator;

/// Simple unreachable code elimination: removes asserts and if statements
/// with constant conditions. Does a very limited constant folding of
/// logical expressions.
///
/// Also performs some additional constant evaluation via [evaluator], which is
/// applied to certain types of expressions (currently only StaticGet).
Component transformComponent(
    Component component, bool enableAsserts, VMConstantEvaluator evaluator) {
  SimpleUnreachableCodeElimination(enableAsserts, evaluator)
      .visitComponent(component, null);
  return component;
}

class SimpleUnreachableCodeElimination extends RemovingTransformer {
  final bool enableAsserts;
  final VMConstantEvaluator constantEvaluator;
  StaticTypeContext? _staticTypeContext;

  SimpleUnreachableCodeElimination(this.enableAsserts, this.constantEvaluator);

  @override
  TreeNode defaultMember(Member node, TreeNode? removalSentinel) {
    _staticTypeContext =
        StaticTypeContext(node, constantEvaluator.typeEnvironment);
    final result = super.defaultMember(node, removalSentinel);
    _staticTypeContext = null;
    return result;
  }

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

  Statement _makeEmptyBlockIfEmptyStatement(Statement node, TreeNode parent) =>
      node is EmptyStatement ? (Block(<Statement>[])..parent = parent) : node;

  @override
  TreeNode visitIfStatement(IfStatement node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final condition = node.condition;
    if (_isBoolConstant(condition)) {
      final value = _getBoolConstantValue(condition);
      return value
          ? node.then
          : (node.otherwise ?? removalSentinel ?? new EmptyStatement());
    }
    node.then = _makeEmptyBlockIfEmptyStatement(node.then, node);
    return node;
  }

  @override
  visitConditionalExpression(
      ConditionalExpression node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final condition = node.condition;
    if (_isBoolConstant(condition)) {
      final value = _getBoolConstantValue(condition);
      return value ? node.then : node.otherwise;
    }
    return node;
  }

  @override
  TreeNode visitNot(Not node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final operand = node.operand;
    if (_isBoolConstant(operand)) {
      return _createBoolLiteral(
          !_getBoolConstantValue(operand), node.fileOffset);
    }
    return node;
  }

  @override
  TreeNode visitLogicalExpression(
      LogicalExpression node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
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
  visitStaticGet(StaticGet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final target = node.target;
    if (target is Field && target.isConst) {
      throw 'StaticGet from const field $target should be evaluated by front-end: $node';
    }
    if (constantEvaluator.transformerShouldEvaluateExpression(node)) {
      final context = _staticTypeContext!;
      final result = constantEvaluator.evaluate(context, node);
      assert(result is! UnevaluatedConstant);
      return new ConstantExpression(result, node.getStaticType(context))
        ..fileOffset = node.fileOffset;
    }
    return node;
  }

  @override
  TreeNode visitAssertStatement(
      AssertStatement node, TreeNode? removalSentinel) {
    if (!enableAsserts) {
      return removalSentinel ?? new EmptyStatement();
    }
    return super.visitAssertStatement(node, removalSentinel);
  }

  @override
  TreeNode visitAssertBlock(AssertBlock node, TreeNode? removalSentinel) {
    if (!enableAsserts) {
      return removalSentinel ?? new EmptyStatement();
    }
    return super.visitAssertBlock(node, removalSentinel);
  }

  @override
  TreeNode visitAssertInitializer(
      AssertInitializer node, TreeNode? removalSentinel) {
    if (!enableAsserts) {
      // Initializers only occur in the initializer list where they are always
      // removable.
      return removalSentinel!;
    }
    return super.visitAssertInitializer(node, removalSentinel);
  }

  @override
  TreeNode visitTryFinally(TryFinally node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final fin = node.finalizer;
    if (fin is EmptyStatement || (fin is Block && fin.statements.isEmpty)) {
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
  TreeNode visitTryCatch(TryCatch node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    // Can replace try/catch with its body if all catches are just rethrow.
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
  TreeNode visitWhileStatement(WhileStatement node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    node.body = _makeEmptyBlockIfEmptyStatement(node.body, node);
    return node;
  }

  @override
  TreeNode visitDoStatement(DoStatement node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    node.body = _makeEmptyBlockIfEmptyStatement(node.body, node);
    return node;
  }

  @override
  TreeNode visitForStatement(ForStatement node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    node.body = _makeEmptyBlockIfEmptyStatement(node.body, node);
    return node;
  }

  @override
  TreeNode visitForInStatement(ForInStatement node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    node.body = _makeEmptyBlockIfEmptyStatement(node.body, node);
    return node;
  }
}
