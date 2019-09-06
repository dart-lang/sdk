// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(askesc): We should not need to call the constant evaluator
// explicitly once constant-update-2018 is shipped.
import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    show ConstantEvaluator, SimpleErrorReporter;

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
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
        _evaluator = ConstantEvaluator(const DevCompilerConstantsBackend(),
            declaredVariables, types, const _ErrorReporter());

  /// Determines if an expression is constant.
  bool isConstant(Expression e) => _visitor.isConstant(e);

  /// Evaluates [e] to find its constant value, returning `null` if evaluation
  /// failed, or if the constant was unavailable.
  ///
  /// Returns [NullConstant] to represent the `null` value.
  Constant evaluate(Expression e) {
    if (e == null) return null;

    Constant result = _evaluator.evaluate(e);
    return result is UnevaluatedConstant ? null : result;
  }

  /// If [node] is an annotation with a field named [name], returns that field's
  /// value.
  ///
  /// This assumes the field is populated from a named argument with that name,
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
  Object getFieldValueFromAnnotation(Expression node, String name) {
    node = unwrapUnevaluatedConstant(node);
    if (node is ConstantExpression) {
      var constant = node.constant;
      if (constant is InstanceConstant) {
        var value = constant.fieldValues.entries
            .firstWhere((e) => e.key.asField.name.name == name,
                orElse: () => null)
            ?.value;
        if (value is PrimitiveConstant) return value.value;
        if (value is UnevaluatedConstant) {
          return _evaluateAnnotationArgument(value.expression);
        }
        return null;
      }
    }

    // TODO(jmesserly): this does not use the normal evaluation engine, because
    // it won't work if we don't have the const constructor body available.
    //
    // We may need to address this in the kernel outline files.
    if (node is ConstructorInvocation) {
      Expression first;
      var named = node.arguments.named;
      if (named.isNotEmpty) {
        first =
            named.firstWhere((n) => n.name == name, orElse: () => null)?.value;
      }
      var positional = node.arguments.positional;
      if (positional.isNotEmpty) first ??= positional[0];
      if (first != null) {
        return _evaluateAnnotationArgument(first);
      }
    }
    return null;
  }

  Object _evaluateAnnotationArgument(Expression node) {
    node = unwrapUnevaluatedConstant(node);
    if (node is ConstantExpression) {
      var constant = node.constant;
      if (constant is PrimitiveConstant) return constant.value;
    }
    if (node is StaticGet) {
      var target = node.target;
      if (target is Field) {
        return _evaluateAnnotationArgument(target.initializer);
      }
    }
    return node is BasicLiteral ? node.value : null;
  }
}

/// Finds constant expressions as defined in Dart language spec 4th ed,
/// 16.1 Constants.
class _ConstantVisitor extends ExpressionVisitor<bool> {
  final CoreTypes coreTypes;
  _ConstantVisitor(this.coreTypes);

  bool isConstant(Expression e) => e.accept(this) as bool;

  @override
  defaultExpression(node) => false;
  @override
  defaultBasicLiteral(node) => true;
  @override
  visitTypeLiteral(node) => true; // TODO(jmesserly): deferred libraries?
  @override
  visitSymbolLiteral(node) => true;
  @override
  visitListLiteral(node) => node.isConst;
  @override
  visitMapLiteral(node) => node.isConst;
  @override
  visitStaticInvocation(node) {
    return node.isConst ||
        node.target == coreTypes.identicalProcedure &&
            node.arguments.positional.every(isConstant) ||
        isFromEnvironmentInvocation(coreTypes, node) &&
            node.arguments.positional.every(isConstant) &&
            node.arguments.named.every((n) => isConstant(n.value));
  }

  @override
  visitDirectMethodInvocation(node) {
    return node.receiver is BasicLiteral &&
        isOperatorMethodName(node.name.name) &&
        node.arguments.positional.every((p) => p is BasicLiteral);
  }

  @override
  visitMethodInvocation(node) {
    return node.receiver is BasicLiteral &&
        isOperatorMethodName(node.name.name) &&
        node.arguments.positional.every((p) => p is BasicLiteral);
  }

  @override
  visitConstructorInvocation(node) => node.isConst;
  @override
  visitStringConcatenation(node) =>
      node.expressions.every((e) => e is BasicLiteral);
  @override
  visitStaticGet(node) {
    var target = node.target;
    return target is Procedure || target is Field && target.isConst;
  }

  @override
  visitVariableGet(node) => node.variable.isConst;
  @override
  visitNot(node) {
    var operand = node.operand;
    return operand is BoolLiteral ||
        operand is DirectMethodInvocation &&
            visitDirectMethodInvocation(operand) ||
        operand is MethodInvocation && visitMethodInvocation(operand);
  }

  @override
  visitLogicalExpression(node) =>
      node.left is BoolLiteral && node.right is BoolLiteral;
  @override
  visitConditionalExpression(node) =>
      node.condition is BoolLiteral &&
      node.then is BoolLiteral &&
      node.otherwise is BoolLiteral;

  @override
  visitLet(Let node) {
    var init = node.variable.initializer;
    return (init == null || isConstant(init)) && isConstant(node.body);
  }
}

/// Implement the class for compiler specific behavior.
class DevCompilerConstantsBackend extends ConstantsBackend {
  const DevCompilerConstantsBackend();

  @override
  NumberSemantics get numberSemantics => NumberSemantics.js;

  @override
  bool shouldInlineConstant(ConstantExpression initializer) {
    Constant constant = initializer.constant;
    if (constant is StringConstant) {
      // Only inline small string constants, not large ones.
      // (The upper bound value is arbitrary.)
      return constant.value.length < 32;
    } else if (constant is PrimitiveConstant) {
      // Inline all other primitives.
      return true;
    } else {
      // Don't inline other constants, because it would take too much code size.
      // Better to refer to them by their field/variable name.
      return false;
    }
  }
}

class _ErrorReporter extends SimpleErrorReporter {
  const _ErrorReporter();

  // Ignore reported errors.
  @override
  reportMessage(Uri uri, int offset, String message) {}
}
