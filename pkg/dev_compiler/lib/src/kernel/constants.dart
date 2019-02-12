// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/constants.dart';
import 'package:kernel/type_environment.dart';
import 'kernel_helpers.dart';

/// Implements constant evaluation for dev compiler:
///
/// [isConstant] determines if an expression is constant.
/// [evaluate] computes the value of a constant expression, if available.
class DevCompilerConstants {
  final _ConstantVisitor _visitor;
  final ConstantEvaluator _evaluator;

  DevCompilerConstants(
      TypeEnvironment types, Map<String, String> declaredVariables)
      : _visitor = _ConstantVisitor(types.coreTypes),
        _evaluator = ConstantEvaluator(_ConstantsBackend(), declaredVariables,
            types, false, const _ErrorReporter());

  /// Determines if an expression is constant.
  bool isConstant(Expression e) => _visitor.isConstant(e);

  /// Evaluates [e] to find its constant value, returning `null` if evaluation
  /// failed, or if the constant was unavailable.
  ///
  /// Returns [NullConstant] to represent the `null` value.
  ///
  /// To avoid performance costs associated with try+catch on invalid constant
  /// evaluation, call this after [isConstant] is known to be true.
  Constant evaluate(Expression e, {bool cache = false}) {
    if (e == null) return null;

    try {
      var result = cache ? _evaluator.evaluate(e) : e.accept(_evaluator);
      return result is UnevaluatedConstant ? null : result;
    } on _AbortCurrentEvaluation {
      // TODO(jmesserly): the try+catch is necessary because the front end is
      // not issuing sufficient errors, so the constant evaluation can fail.
      //
      // It can also be caused by methods in the evaluator that don't understand
      // unavailable constants.
      return null;
    } on NoSuchMethodError {
      // TODO(jmesserly): this is probably the same issue as above, but verify
      // that it's fixed once Kernel does constant evaluation.
      return null;
    }
  }

  /// If [node] is an annotation with a field named `name`, returns that field's
  /// value.
  ///
  /// This assumes the `name` field is populated from a named argument `name:`
  /// or from the first positional argument.
  ///
  /// For example:
  ///
  ///     class MyAnnotation {
  ///       final String name;
  ///       // ...
  ///       const MyAnnotation(this.name/*, ... other params ... */);
  ///     }
  ///
  ///     @MyAnnotation('FooBar')
  ///     main() { ... }
  ///
  /// Given the node for `@MyAnnotation('FooBar')` this will return `'FooBar'`.
  String getNameFromAnnotation(ConstructorInvocation node) {
    if (node == null) return null;

    // TODO(jmesserly): this does not use the normal evaluation engine, because
    // it won't work if we don't have the const constructor body available.
    //
    // We may need to address this in the kernel outline files.
    Expression first;
    var named = node.arguments.named;
    if (named.isNotEmpty) {
      first =
          named.firstWhere((n) => n.name == 'name', orElse: () => null)?.value;
    }
    var positional = node.arguments.positional;
    if (positional.isNotEmpty) first ??= positional[0];
    if (first != null) {
      first = _followConstFields(first);
      if (first is StringLiteral) return first.value;
    }
    return null;
  }

  Expression _followConstFields(Expression expr) {
    if (expr is StaticGet) {
      var target = expr.target;
      if (target is Field) {
        return _followConstFields(target.initializer);
      }
    }
    return expr;
  }
}

/// Finds constant expressions as defined in Dart language spec 4th ed,
/// 16.1 Constants.
class _ConstantVisitor extends ExpressionVisitor<bool> {
  final CoreTypes coreTypes;
  _ConstantVisitor(this.coreTypes);

  bool isConstant(Expression e) => e.accept(this);

  defaultExpression(node) => false;
  defaultBasicLiteral(node) => true;
  visitTypeLiteral(node) => true; // TODO(jmesserly): deferred libraries?
  visitSymbolLiteral(node) => true;
  visitListLiteral(node) => node.isConst;
  visitMapLiteral(node) => node.isConst;
  visitStaticInvocation(node) {
    return node.isConst ||
        node.target == coreTypes.identicalProcedure &&
            node.arguments.positional.every(isConstant) ||
        isFromEnvironmentInvocation(coreTypes, node) &&
            node.arguments.positional.every(isConstant) &&
            node.arguments.named.every((n) => isConstant(n.value));
  }

  visitDirectMethodInvocation(node) {
    return node.receiver is BasicLiteral &&
        isOperatorMethodName(node.name.name) &&
        node.arguments.positional.every((p) => p is BasicLiteral);
  }

  visitMethodInvocation(node) {
    return node.receiver is BasicLiteral &&
        isOperatorMethodName(node.name.name) &&
        node.arguments.positional.every((p) => p is BasicLiteral);
  }

  visitConstructorInvocation(node) => node.isConst;
  visitStringConcatenation(node) =>
      node.expressions.every((e) => e is BasicLiteral);
  visitStaticGet(node) {
    var target = node.target;
    return target is Procedure || target is Field && target.isConst;
  }

  visitVariableGet(node) => node.variable.isConst;
  visitNot(node) {
    var operand = node.operand;
    return operand is BoolLiteral ||
        operand is DirectMethodInvocation &&
            visitDirectMethodInvocation(operand) ||
        operand is MethodInvocation && visitMethodInvocation(operand);
  }

  visitLogicalExpression(node) =>
      node.left is BoolLiteral && node.right is BoolLiteral;
  visitConditionalExpression(node) =>
      node.condition is BoolLiteral &&
      node.then is BoolLiteral &&
      node.otherwise is BoolLiteral;

  visitLet(Let node) {
    var init = node.variable.initializer;
    return (init == null || isConstant(init)) && isConstant(node.body);
  }
}

/// Implement the class for compiler specific behavior.
class _ConstantsBackend extends ConstantsBackend {
  _ConstantsBackend();

  @override
  Constant lowerConstant(Constant constant) {
    if (constant is DoubleConstant) {
      // Convert to an integer when possible (matching the runtime behavior
      // of `is int`).
      var d = constant.value;
      if (d.isFinite) {
        var i = d.toInt();
        if (d == i.toDouble()) return IntConstant(i);
      }
    }
    return constant;
  }

  // Use doubles to match JS number semantics.
  num prepareNumericOperand(num operand) => operand.toDouble();
}

class _ErrorReporter extends SimpleErrorReporter {
  const _ErrorReporter();

  @override
  report(context, message, node) => throw const _AbortCurrentEvaluation();
}

// TODO(jmesserly): this class is private in Kernel constants library, so
// we have our own version.
class _AbortCurrentEvaluation {
  const _AbortCurrentEvaluation();
}
