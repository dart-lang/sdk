// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToContains extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_CONTAINS;

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
      var methodName = leftOperand.methodName;
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
        builder.addDeletion(deletionRange);
      });
    } else if (_isInteger(leftOperand) && rightOperand is MethodInvocation) {
      var value = _integerValue(leftOperand);
      var methodName = rightOperand.methodName;
      var deletionRange = range.startStart(leftOperand, rightOperand);
      var notOffset = -1;
      var style =
          _negationStyle(_invertedTokenType(comparison.operator.type), value);
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
      });
    }
  }

  /// Return the value of the given [expression], given that [_isInteger]
  /// returned `true`.
  int _integerValue(Expression expression) {
    if (expression is IntegerLiteral) {
      return expression.value;
    } else if (expression is PrefixExpression &&
        expression.operator.type == TokenType.MINUS) {
      var operand = expression.operand;
      if (operand is IntegerLiteral) {
        return -(operand.value);
      }
    }
    throw StateError('invalid integer value');
  }

  TokenType _invertedTokenType(TokenType type) {
    switch (type) {
      case TokenType.LT_EQ:
        return TokenType.GT_EQ;
      case TokenType.LT:
        return TokenType.GT;
      case TokenType.GT:
        return TokenType.LT;
      case TokenType.GT_EQ:
        return TokenType.LT_EQ;
      default:
        return type;
    }
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToContains newInstance() => ConvertToContains();
}

/// An indication of whether the `contains` test should be negated, not negated,
/// or whether neither is appropriate and the code should be left unchanged.
enum NegationStyle { none, negated, positive }
