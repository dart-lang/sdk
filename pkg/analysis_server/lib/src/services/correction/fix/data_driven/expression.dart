// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_generator.dart';

/// A binary expression.
class BinaryExpression extends Expression {
  /// The left operand.
  final Expression leftOperand;

  /// The operator.
  final Operator operator;

  /// The right operand.
  final Expression rightOperand;

  /// Initialize a newly created binary expression consisting of the
  /// [leftOperand], [operator], and [rightOperand].
  BinaryExpression(this.leftOperand, this.operator, this.rightOperand);

  @override
  Object evaluateIn(TemplateContext context) {
    switch (operator) {
      case Operator.and:
        var left = leftOperand.evaluateIn(context);
        var right = rightOperand.evaluateIn(context);
        if (left is bool && right is bool) {
          return left && right;
        }
        return null;
      case Operator.equal:
        var left = leftOperand.evaluateIn(context);
        var right = rightOperand.evaluateIn(context);
        return left == right;
      case Operator.notEqual:
        var left = leftOperand.evaluateIn(context);
        var right = rightOperand.evaluateIn(context);
        return left != right;
    }
    return null;
  }
}

/// An expression.
abstract class Expression {
  /// Return the result of evaluating this expression.
  Object evaluateIn(TemplateContext context);
}

/// A literal string.
class LiteralString extends Expression {
  /// The value of the literal string.
  final String value;

  /// Initialize a newly created literal string to have the given [value].
  LiteralString(this.value);

  @override
  String evaluateIn(TemplateContext context) {
    return value;
  }
}

/// An operator used in a binary expression.
enum Operator {
  and,
  equal,
  notEqual,
}

/// A reference to a variable.
class VariableReference extends Expression {
  /// The generator used to generate the value of the variable.
  final ValueGenerator generator;

  /// Initialize a newly created variable reference to reference the variable
  /// whose value is computed by the [generator].
  VariableReference(this.generator);

  @override
  String evaluateIn(TemplateContext context) {
    return generator.evaluateIn(context);
  }
}
