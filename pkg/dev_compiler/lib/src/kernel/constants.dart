// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';

/// Implements constant evaluation for dev compiler:
///
/// [isConstant] determines if an expression is constant.
/// [evaluate] computes the value of a constant expression, if available.
class DevCompilerConstants {
  DevCompilerConstants();

  /// Determines if an expression is constant.
  bool isConstant(Expression e) => e is ConstantExpression;

  /// Evaluates [e] to find its constant value, returning `null` if evaluation
  /// failed, or if the constant was unavailable.
  ///
  /// Returns [NullConstant] to represent the `null` value.
  Constant evaluate(Expression e) {
    return e is ConstantExpression ? e.constant : null;
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
    if (node is ConstantExpression) {
      var constant = node.constant;
      if (constant is InstanceConstant) {
        var value = constant.fieldValues.entries
            .firstWhere((e) => e.key.asField.name.text == name,
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

/// Implement the class for compiler specific behavior.
class DevCompilerConstantsBackend extends ConstantsBackend {
  const DevCompilerConstantsBackend();

  @override
  NumberSemantics get numberSemantics => NumberSemantics.js;

  @override
  bool shouldInlineConstant(ConstantExpression initializer) {
    var constant = initializer.constant;
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
