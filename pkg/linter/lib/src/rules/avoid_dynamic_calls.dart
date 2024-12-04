// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid method calls or property accesses on a `dynamic` target.';

class AvoidDynamicCalls extends LintRule {
  AvoidDynamicCalls()
      : super(
          name: LintNames.avoid_dynamic_calls,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_dynamic_calls;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry
      ..addAssignmentExpression(this, visitor)
      ..addBinaryExpression(this, visitor)
      ..addFunctionExpressionInvocation(this, visitor)
      ..addIndexExpression(this, visitor)
      ..addMethodInvocation(this, visitor)
      ..addPostfixExpression(this, visitor)
      ..addPrefixExpression(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  /// Member names which are allowed to be accessed on `dynamic`- or
  /// `Function`-typed expressions.
  static const _allowedMemberAccesses = {
    'hashCode',
    'noSuchMethod',
    'runtimeType',
    'toString',
  };

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.readType is! DynamicType) {
      // An assignment expression can only be a dynamic call if it is a
      // "compound assignment" (i.e. such as `x += 1`); so if `readType` is not
      // dynamic, we don't need to check further.
      return;
    }
    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      // x ??= foo is not a dynamic call.
      return;
    }
    rule.reportLint(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!node.operator.isUserDefinableOperator) {
      // Operators that can never be provided by the user can't be dynamic.
      return;
    }
    switch (node.operator.type) {
      case TokenType.EQ_EQ:
      case TokenType.BANG_EQ:
        // These operators exist on every type, even "Object?". While they are
        // virtually dispatched, they are not considered dynamic calls by the
        // CFE. They would also make landing this lint exponentially harder.
        return;
    }
    _reportIfDynamic(node.leftOperand);
    // We don't check node.rightOperand, because that is an implicit cast, not a
    // dynamic call (the call itself is based on leftOperand). While it would be
    // useful to do so, it is better solved by other more specific lints to
    // disallow implicit casts from dynamic.
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _reportIfDynamicOrFunction(node.function);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _reportIfDynamic(node.realTarget);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var methodName = node.methodName.name;
    if (node.target != null) {
      if (methodName == 'noSuchMethod' &&
          node.argumentList.arguments.length == 1 &&
          node.argumentList.arguments.first is! NamedExpression) {
        // Allowed as these exist on every object, even those typed `Object?`.
        return;
      }
      if (methodName == 'toString' && node.argumentList.arguments.isEmpty) {
        // Allowed as these exist on every object, even those typed `Object?`.
        return;
      }
    }
    if (_isExplicitCast(node.realTarget)) return;
    var receiverWasDynamic = _reportIfDynamic(node.realTarget);
    if (!receiverWasDynamic) {
      var target = node.realTarget;
      // The `.call` method is special, where `a.call()` is treated ~as `a()`.
      //
      // If the method is `call`, and the receiver is a function, we assume then
      // we are really checking the static type of the receiver, not the static
      // type of the `call` method itself.
      DartType? staticType;
      if (methodName == 'call' &&
          target != null &&
          target.staticType is FunctionType) {
        staticType = target.staticType;
      }
      _reportIfDynamicOrFunction(node.function, staticType: staticType);
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      // `x!` is not a dynamic call, even if `x` is `dynamic`.
      return;
    }
    _reportPrefixOrPostfixExpression(node, node.operand);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_allowedMemberAccesses.contains(node.identifier.name)) {
      // Allowed as these exist on every object, even those typed `Object?`.
      return;
    }
    _reportIfDynamic(node.prefix);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _reportPrefixOrPostfixExpression(node, node.operand);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_allowedMemberAccesses.contains(node.propertyName.name)) {
      // Allowed as these exist on every object, even those typed `Object?`.
      return;
    }
    _reportIfDynamic(node.realTarget);
  }

  bool _reportIfDynamic(Expression? node) {
    if (node == null || node.staticType is! DynamicType) return false;
    if (_isExplicitCast(node)) return false;

    rule.reportLint(node);
    return true;
  }

  void _reportIfDynamicOrFunction(Expression node, {DartType? staticType}) {
    staticType ??= node.staticType;
    if (staticType == null) return;
    if (_isExplicitCast(node)) return;
    if (staticType is DynamicType || staticType.isDartCoreFunction) {
      rule.reportLint(node);
    }
  }

  void _reportPrefixOrPostfixExpression(Expression root, Expression operand) {
    if (_reportIfDynamic(operand)) {
      return;
    }
    if (root is CompoundAssignmentExpression) {
      if (root.readType is DynamicType) {
        // An assignment expression can only be a dynamic call if it is a
        // "compound assignment" (i.e. such as `x += 1`); so if `readType` is
        // `dynamic` we should report.
        rule.reportLint(root);
      }
    }
  }

  /// Whether an expression matches a pattern to allow a dynamic call.
  ///
  /// This should only be used to check expressions which have a static type of
  /// `dynamic` or `Function`.
  ///
  /// Expressions with a static type of `dynamic` can be used only if they are
  /// expliticly a parenthesized cast (which must be to `dynamic` or `Function`
  /// to be relevant).
  static bool _isExplicitCast(Expression? node) =>
      node?.unParenthesized is AsExpression;
}
