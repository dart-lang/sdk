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

  bool? _getBoolConstantValue(Expression node) {
    if (node is BoolLiteral) return node.value;
    if (node is! ConstantExpression) return null;
    final constant = node.constant;
    return constant is BoolConstant ? constant.value : null;
  }

  Expression _makeConstantExpression(Constant constant, Expression node) {
    if (constant is UnevaluatedConstant &&
        constant.expression is InvalidExpression) {
      return constant.expression;
    }
    ConstantExpression constantExpression = new ConstantExpression(
        constant, node.getStaticType(_staticTypeContext!))
      ..fileOffset = node.fileOffset;
    if (node is FileUriExpression) {
      return new FileUriConstantExpression(constantExpression.constant,
          type: constantExpression.type, fileUri: node.fileUri)
        ..fileOffset = node.fileOffset;
    }
    return constantExpression;
  }

  Expression _createBoolConstantExpression(bool value, Expression node) =>
      _makeConstantExpression(
          constantEvaluator.canonicalize(BoolConstant(value)), node);

  Statement _makeEmptyBlockIfEmptyStatement(Statement node, TreeNode parent) =>
      node is EmptyStatement ? (Block(<Statement>[])..parent = parent) : node;

  @override
  TreeNode visitIfStatement(IfStatement node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final condition = node.condition;
    final value = _getBoolConstantValue(condition);
    if (value != null) {
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
    final value = _getBoolConstantValue(condition);
    if (value != null) {
      return value ? node.then : node.otherwise;
    }
    return node;
  }

  @override
  TreeNode visitNot(Not node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final operand = node.operand;
    final value = _getBoolConstantValue(operand);
    if (value != null) {
      return _createBoolConstantExpression(!value, node);
    }
    return node;
  }

  @override
  TreeNode visitLogicalExpression(
      LogicalExpression node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    bool? value = _getBoolConstantValue(node.left);
    // Because of short-circuiting, these operators cannot be treated as
    // symmetric, so a non-constant left and a constant right is left as-is.
    if (value == null) return node;
    switch (node.operatorEnum) {
      case LogicalExpressionOperator.OR:
        return value ? node.left : node.right;
      case LogicalExpressionOperator.AND:
        return value ? node.right : node.left;
    }
  }

  @override
  TreeNode visitSwitchStatement(
      SwitchStatement node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final tested = node.expression;
    if (tested is! ConstantExpression) return node;

    // First, keep any reachable case. As a side effect, any expressions that
    // cannot match in the SwitchCases are removed. An expression cannot match
    // if it is a non-matching constant expression or it follows a constant
    // expression that is guaranteed to match.
    final toKeep = <SwitchCase>{};
    bool foundMatchingCase = false;
    for (final c in node.cases) {
      if (foundMatchingCase) {
        c.expressions.clear();
        continue;
      }
      c.expressions.retainWhere((e) {
        if (foundMatchingCase) return false;
        if (e is! ConstantExpression) return true;
        foundMatchingCase = e.constant == tested.constant;
        return foundMatchingCase;
      });
      if (c.isDefault || c.expressions.isNotEmpty) {
        toKeep.add(c);
      }
    }

    if (toKeep.isEmpty) {
      if (node.isExhaustive) {
        throw 'Expected at least one kept case from exhaustive switch: $node';
      }
      return removalSentinel ?? new EmptyStatement();
    }

    // Now iteratively find additional cases to keep by following targets of
    // continue statements in kept cases.
    final worklist = [...toKeep];
    final collector = ContinueSwitchStatementTargetCollector(node);
    while (worklist.isNotEmpty) {
      final next = worklist.removeLast();
      final targets = collector.collectTargets(next);
      for (final target in targets) {
        if (toKeep.add(target)) {
          worklist.add(target);
        }
      }
    }

    // Finally, remove any cases not marked for keeping. If only one case
    // is kept, then the switch statement can be replaced with its body.
    if (toKeep.length == 1) {
      return toKeep.first.body;
    }
    node.cases.retainWhere(toKeep.contains);
    if (foundMatchingCase && !node.hasDefault) {
      // While the expression may not be explicitly exhaustive for the type
      // of the tested expression, it is guaranteed to execute at least one
      // of the remaining cases, so the backends don't need to handle the case
      // where no listed case is hit for this switch.
      //
      // If the original program has the matching case directly falls through
      // to the default case for some reason:
      //
      // switch (4) {
      //    ...
      //    case 4:
      //    default:
      //      ...
      // }
      //
      // this means the default case is kept despite finding a guaranteed to
      // match expression, as it contains that matching expression. If that
      // happens, then we don't do this, to keep the invariant that
      // isExplicitlyExhaustive is false if there is a default case.
      node.isExplicitlyExhaustive = true;
    }
    return node;
  }

  @override
  TreeNode visitStaticGet(StaticGet node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    final target = node.target;
    if (target is Field && target.isConst) {
      throw 'StaticGet from const field $target should be evaluated by front-end: $node';
    }
    if (!constantEvaluator.transformerShouldEvaluateExpression(node)) {
      return node;
    }
    final result = constantEvaluator.evaluate(_staticTypeContext!, node);
    return _makeConstantExpression(result, node);
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

class ContinueSwitchStatementTargetCollector extends RecursiveVisitor {
  final SwitchStatement parent;
  late Set<SwitchCase> collected;

  ContinueSwitchStatementTargetCollector(this.parent);

  Set<SwitchCase> collectTargets(SwitchCase node) {
    collected = {};
    node.accept(this);
    return collected;
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    node.visitChildren(this);
    // Only keep targets that are within the original node being checked.
    if (node.target.parent == parent) {
      collected.add(node.target);
    }
  }
}
