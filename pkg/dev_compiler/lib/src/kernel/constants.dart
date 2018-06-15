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
  final _ConstantEvaluator _evaluator;

  DevCompilerConstants(
      TypeEnvironment types, Map<String, String> declaredVariables)
      : _visitor = _ConstantVisitor(types.coreTypes),
        _evaluator = _ConstantEvaluator(types, declaredVariables);

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
      return identical(result, _evaluator.unavailableConstant) ? null : result;
    } on _AbortCurrentEvaluation {
      // TODO(jmesserly): the try+catch is necessary because the front end is
      // not issuing sufficient errors, so the constant evaluation can fail.
      //
      // It can also be caused by methods in the evaluator that don't understand
      // unavailable constants.
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

/// The visitor that evaluates constants, building on Kernel's
/// [ConstantEvaluator] class (used by the VM) and fixing some of its behavior
/// to work better for DDC.
//
// TODO(jmesserly): make some changes in the base class to make it a better fit
// for compilers like DDC?
class _ConstantEvaluator extends ConstantEvaluator {
  final Map<String, String> declaredVariables;

  /// Used to denote an unavailable constant value from another module
  ///
  // TODO(jmesserly): this happens when we try to evaluate constant values from
  // an external library, that was from an outline kernel file. The kernel file
  // does not contain the initializer value of the constant.
  final Constant unavailableConstant;

  _ConstantEvaluator(TypeEnvironment types, this.declaredVariables,
      {bool enableAsserts})
      : unavailableConstant = InstanceConstant(
            types.coreTypes.index
                .getClass('dart:core', '_ConstantExpressionError')
                .reference,
            [],
            {}),
        super(_ConstantsBackend(types.coreTypes), types, types.coreTypes, true,
            enableAsserts, const _ErrorReporter()) {
    env = EvaluationEnvironment();
  }

  @override
  visitVariableGet(node) {
    // The base evaluator expects that variable declarations are visited during
    // the transformation step, so it doesn't handle constant variables.
    // Instead handle them here.
    if (node.variable.isConst) {
      return evaluate(node.variable.initializer);
    }
    // Fall back to the base evaluator for other cases (e.g. parameters of a
    // constant constructor).
    return super.visitVariableGet(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    // Handle unavailable field constants. This happens if an external library
    // only has its outline available.
    var target = node.target;
    if (target is Field &&
        target.isConst &&
        target.isInExternalLibrary &&
        target.initializer == null) {
      return unavailableConstant;
    }
    return super.visitStaticGet(node);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    // Handle unavailable constructor bodies.
    // This happens if an external library only has its outline available.
    var target = node.target;
    if (target.isConst &&
        target.isInExternalLibrary &&
        target.function.body is EmptyStatement &&
        target.initializers.isEmpty) {
      return unavailableConstant;
    }
    return super.visitConstructorInvocation(node);
  }

  @override
  visitStaticInvocation(node) {
    // Handle int/bool/String.fromEnvironment constructors.
    //
    // (The VM handles this via its `native` calls and implements it in
    // VmConstantsBackend.buildConstantForNative.)
    var target = node.target;
    if (isFromEnvironmentInvocation(coreTypes, node)) {
      var firstArg = evaluatePositionalArguments(node.arguments)[0];
      var defaultArg = evaluateNamedArguments(node.arguments)['defaultValue'];

      var varName = (firstArg as StringConstant).value;
      var value = declaredVariables[varName];
      var targetClass = target.enclosingClass;

      if (targetClass == coreTypes.stringClass) {
        if (value != null) return canonicalize(StringConstant(value));
        return defaultArg ?? nullConstant;
      } else if (targetClass == coreTypes.intClass) {
        var intValue = int.parse(value ?? '', onError: (_) => null);
        if (intValue != null) return canonicalize(IntConstant(intValue));
        return defaultArg ?? nullConstant;
      } else if (targetClass == coreTypes.boolClass) {
        if (value == "true") return trueConstant;
        if (value == "false") return falseConstant;
        return defaultArg ?? falseConstant;
      }
    }
    return super.visitStaticInvocation(node);
  }

  @override
  evaluateBinaryNumericOperation(String op, num a, num b, TreeNode node) {
    // Use doubles to match JS number semantics.
    return super
        .evaluateBinaryNumericOperation(op, a.toDouble(), b.toDouble(), node);
  }

  @override
  canonicalize(Constant constant) {
    if (constant is DoubleConstant) {
      // Convert to an integer when possible (matching the runtime behavior
      // of `is int`).
      var d = constant.value;
      if (d.isFinite) {
        var i = d.toInt();
        if (d == i.toDouble()) return super.canonicalize(IntConstant(i));
      }
    }
    return super.canonicalize(constant);
  }
}

/// Implement the class for compiler specific behavior.
///
/// This is mostly unused by DDC, because we don't use the global constant
/// transformer.
class _ConstantsBackend implements ConstantsBackend {
  final CoreTypes coreTypes;
  final Field symbolNameField;

  _ConstantsBackend(this.coreTypes)
      : symbolNameField = coreTypes.internalSymbolClass.fields
            .firstWhere((f) => f.name.name == '_name');

  @override
  buildConstantForNative(
          nativeName, typeArguments, positionalArguments, namedArguments) =>
      throw StateError('unreachable'); // DDC does not use VM native syntax

  @override
  buildSymbolConstant(StringConstant value) {
    return InstanceConstant(
        coreTypes.internalSymbolClass.reference,
        const <DartType>[],
        <Reference, Constant>{symbolNameField.reference: value});
  }

  @override
  lowerMapConstant(constant) => constant;

  @override
  lowerListConstant(constant) => constant;
}

class _ErrorReporter extends ErrorReporterBase {
  const _ErrorReporter();

  @override
  report(context, message, node) => throw const _AbortCurrentEvaluation();
}

// TODO(jmesserly): this class is private in Kernel constants library, so
// we have our own version.
class _AbortCurrentEvaluation {
  const _AbortCurrentEvaluation();
}
