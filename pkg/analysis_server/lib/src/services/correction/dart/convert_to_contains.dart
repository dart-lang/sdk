// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToContains extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_CONTAINS;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_CONTAINS_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var comparison = node.thisOrAncestorOfType<BinaryExpression>();
    if (comparison == null) {
      return;
    }
    var leftOperand = comparison.leftOperand;
    var rightOperand = comparison.rightOperand;
    if (leftOperand is MethodInvocation && _isInteger(rightOperand)) {
      var value = _integerValue(rightOperand);
      if (value == null) {
        return;
      }
      var methodName = leftOperand.methodName;
      var startArgumentRange = _startArgumentRange(leftOperand);
      var deletionRange = range.endEnd(leftOperand, rightOperand);
      var notOffset = -1;
      var style = _negationStyle(comparison.operator.type, value);
      if (style == NegationStyle.none) {
        return;
      } else if (style == NegationStyle.negated) {
        notOffset = leftOperand.offset;
      }

      await builder.addDartFileEdit(file, (builder) {
        if (notOffset > 0) {
          builder.addSimpleInsertion(notOffset, '!');
        }
        builder.addSimpleReplacement(range.node(methodName), 'contains');
        if (startArgumentRange != null) {
          builder.addDeletion(startArgumentRange);
        }
        builder.addDeletion(deletionRange);
      });
    } else if (_isInteger(leftOperand) && rightOperand is MethodInvocation) {
      var value = _integerValue(leftOperand);
      if (value == null) {
        return;
      }
      var methodName = rightOperand.methodName;
      var startArgumentRange = _startArgumentRange(rightOperand);
      var deletionRange = range.startStart(leftOperand, rightOperand);
      var notOffset = -1;
      var style = _negationStyle(comparison.operator.type.inverted, value);
      if (style == NegationStyle.none) {
        return;
      } else if (style == NegationStyle.negated) {
        notOffset = rightOperand.offset;
      }

      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(deletionRange);
        if (notOffset > 0) {
          builder.addSimpleInsertion(notOffset, '!');
        }
        builder.addSimpleReplacement(range.node(methodName), 'contains');
        if (startArgumentRange != null) {
          builder.addDeletion(startArgumentRange);
        }
      });
    }
  }

  /// Return the value of the given [expression], given that [_isInteger]
  /// returned `true`.
  int? _integerValue(Expression expression) {
    if (expression is IntegerLiteral) {
      return expression.value;
    } else if (expression is PrefixExpression &&
        expression.operator.type == TokenType.MINUS) {
      var operand = expression.operand;
      if (operand is IntegerLiteral) {
        var value = operand.value;
        if (value != null) {
          return -value;
        }
      }
    }
    return null;
  }

  /// Return `true` if the given [expression] is a literal integer, possibly
  /// prefixed by a negation operator.
  bool _isInteger(Expression expression) {
    return (expression is IntegerLiteral) ||
        (expression is PrefixExpression &&
            expression.operator.type == TokenType.MINUS &&
            expression.operand is IntegerLiteral);
  }

  NegationStyle _negationStyle(TokenType type, int value) {
    if (value == -1) {
      if (type == TokenType.EQ_EQ || type == TokenType.LT_EQ) {
        // `indexOf == -1` is the same as `!contains`
        // `indexOf <= -1` is the same as `!contains`
        return NegationStyle.negated;
      } else if (type == TokenType.BANG_EQ || type == TokenType.GT) {
        // `indexOf != -1` is the same as `contains`
        // `indexOf > -1` is the same as `contains`
        return NegationStyle.positive;
      } else if (type == TokenType.LT || type == TokenType.GT_EQ) {
        // `indexOf < -1` is always false
        // `indexOf >= -1` is always true
        return NegationStyle.none;
      }
    } else if (value == 0) {
      if (type == TokenType.GT_EQ) {
        // `indexOf >= 0` is the same as `contains`
        return NegationStyle.positive;
      } else if (type == TokenType.LT) {
        // `indexOf < 0` is the same as `!contains`
        return NegationStyle.negated;
      }
      // Any other comparison with zero should not have been flagged, so we
      // should never reach this point.
      return NegationStyle.none;
    } else if (value < -1) {
      // 'indexOf' is always >= -1, so comparing with lesser values makes
      // no sense.
      return NegationStyle.none;
    }
    // Comparison with any value greater than zero should not have been flagged,
    // so we should never reach this point.
    return NegationStyle.none;
  }

  SourceRange? _startArgumentRange(MethodInvocation invocation) {
    var arguments = invocation.argumentList.arguments;
    if (arguments.length == 2) {
      var firstArgument = arguments[0];
      var secondArgument = arguments[1];
      return range.endEnd(firstArgument, secondArgument);
    }
    return null;
  }
}

/// An indication of whether the `contains` test should be negated, not negated,
/// or whether neither is appropriate and the code should be left unchanged.
enum NegationStyle { none, negated, positive }

extension on TokenType {
  TokenType get inverted => switch (this) {
        TokenType.LT_EQ => TokenType.GT_EQ,
        TokenType.LT => TokenType.GT,
        TokenType.GT => TokenType.LT,
        TokenType.GT_EQ => TokenType.LT_EQ,
        _ => this
      };
}
