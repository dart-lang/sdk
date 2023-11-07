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

    // Set of SwitchCases that should be retained, either because they are
    // guaranteed to match, may match and no case before them is guaranteed
    // to match, or because they are the target of a case that may match or
    // is guaranteed to match.
    final toKeep = <SwitchCase>{};
    // Whether an expression from a previous case is guaranteed to match.
    bool foundMatchingCase = false;
    for (final c in node.cases) {
      // Trim any constant expressions that don't match, or any expression
      // that follows a guaranteed-to-match case. Perform this trimming even
      // on cases that follow a guaranteed to match case and thus are not
      // in the initial set to retain, since they may be the target of continue
      // statements and thus added to the set to retain later.
      bool containsMatchingCase = false;
      c.expressions.retainWhere((e) {
        if (foundMatchingCase) return false;
        if (e is! ConstantExpression) return true;
        containsMatchingCase = e.constant == tested.constant;
        return containsMatchingCase;
      });
      if (foundMatchingCase) continue;
      foundMatchingCase = containsMatchingCase;
      if (c.isDefault || c.expressions.isNotEmpty) {
        toKeep.add(c);
      }
    }

    if (toKeep.isEmpty) {
      throw 'Expected at least one possibly matching case: $node';
    }

    // Now iteratively keep cases that are targets of continue statements
    // within the cases we've already marked to keep.
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

    node.cases.retainWhere((c) => toKeep.contains(c));
    if (node.cases.length == 1) {
      return node.cases.first.body;
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
