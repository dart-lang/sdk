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

class ReplaceWithIsEmpty extends CorrectionProducer {
  @override
  FixKind fixKind = DartFixKind.REPLACE_WITH_IS_EMPTY;

  @override
  FixKind multiFixKind = DartFixKind.REPLACE_WITH_IS_EMPTY_MULTI;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var binary = node.thisOrAncestorOfType<BinaryExpression>();
    if (binary == null) {
      return;
    }

    var replacement = _analyzeBinaryExpression(binary);
    if (replacement == null) {
      return;
    }

    fixKind = replacement.fixKind;
    multiFixKind = replacement.multiFixKind;

    var target = utils.getNodeText(replacement.lengthTarget);
    var getter = replacement.getter;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(binary), '$target.$getter');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithIsEmpty newInstance() => ReplaceWithIsEmpty();

  static _Replacement? _analyzeBinaryExpression(BinaryExpression binary) {
    var operator = binary.operator.type;
    var rightValue = _getIntValue(binary.rightOperand);
    if (rightValue != null) {
      var lengthTarget = _getLengthTarget(binary.leftOperand);
      if (lengthTarget == null) {
        return null;
      }
      if (rightValue == 0) {
        if (operator == TokenType.EQ_EQ || operator == TokenType.LT_EQ) {
          return _Replacement.isEmpty(lengthTarget);
        } else if (operator == TokenType.GT || operator == TokenType.BANG_EQ) {
          return _Replacement.isNotEmpty(lengthTarget);
        }
      } else if (rightValue == 1) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator == TokenType.GT_EQ) {
          return _Replacement.isNotEmpty(lengthTarget);
        } else if (operator == TokenType.LT) {
          return _Replacement.isEmpty(lengthTarget);
        }
      }
    } else {
      var leftValue = _getIntValue(binary.leftOperand);
      if (leftValue != null) {
        var lengthTarget = _getLengthTarget(binary.rightOperand);
        if (lengthTarget == null) {
          return null;
        }
        if (leftValue == 0) {
          if (operator == TokenType.EQ_EQ || operator == TokenType.GT_EQ) {
            return _Replacement.isEmpty(lengthTarget);
          } else if (operator == TokenType.LT ||
              operator == TokenType.BANG_EQ) {
            return _Replacement.isNotEmpty(lengthTarget);
          }
        } else if (leftValue == 1) {
          // '1 <= length' is same as 'isNotEmpty',
          // and '1 > length' is same as 'isEmpty'
          if (operator == TokenType.LT_EQ) {
            return _Replacement.isNotEmpty(lengthTarget);
          } else if (operator == TokenType.GT) {
            return _Replacement.isEmpty(lengthTarget);
          }
        }
      }
    }
    return null;
  }

  /// Return the value of an integer literal or prefix expression with a
  /// minus and then an integer literal. For anything else, returns `null`.
  static int? _getIntValue(Expression expressions) {
    // Copied from package:linter/src/rules/prefer_is_empty.dart.
    if (expressions is IntegerLiteral) {
      return expressions.value;
    } else if (expressions is PrefixExpression) {
      var operand = expressions.operand;
      if (expressions.operator.type == TokenType.MINUS &&
          operand is IntegerLiteral) {
        var value = operand.value;
        if (value != null) {
          return -value;
        }
      }
    }
    return null;
  }

  /// Return the expression producing the object on which `length` is being
  /// invoked, or `null` if there is no such expression.
  static Expression? _getLengthTarget(Expression expression) {
    if (expression is PropertyAccess &&
        expression.propertyName.name == 'length') {
      return expression.target;
    } else if (expression is PrefixedIdentifier &&
        expression.identifier.name == 'length') {
      return expression.prefix;
    }
    return null;
  }
}

class _Replacement {
  final FixKind fixKind;
  final FixKind multiFixKind;
  final String getter;
  final Expression lengthTarget;

  _Replacement.isEmpty(Expression lengthTarget)
      : this._(
          fixKind: DartFixKind.REPLACE_WITH_IS_EMPTY,
          multiFixKind: DartFixKind.REPLACE_WITH_IS_EMPTY_MULTI,
          getter: 'isEmpty',
          lengthTarget: lengthTarget,
        );

  _Replacement.isNotEmpty(Expression lengthTarget)
      : this._(
          fixKind: DartFixKind.REPLACE_WITH_IS_NOT_EMPTY,
          multiFixKind: DartFixKind.REPLACE_WITH_IS_NOT_EMPTY_MULTI,
          getter: 'isNotEmpty',
          lengthTarget: lengthTarget,
        );

  _Replacement._({
    required this.fixKind,
    required this.multiFixKind,
    required this.getter,
    required this.lengthTarget,
  });
}
