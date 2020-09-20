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
  FixKind fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    /// Return the value of an integer literal or prefix expression with a
    /// minus and then an integer literal. For anything else, returns `null`.
    int getIntValue(Expression expressions) {
      // Copied from package:linter/src/rules/prefer_is_empty.dart.
      if (expressions is IntegerLiteral) {
        return expressions.value;
      } else if (expressions is PrefixExpression) {
        var operand = expressions.operand;
        if (expressions.operator.type == TokenType.MINUS &&
            operand is IntegerLiteral) {
          return -operand.value;
        }
      }
      return null;
    }

    /// Return the expression producing the object on which `length` is being
    /// invoked, or `null` if there is no such expression.
    Expression getLengthTarget(Expression expression) {
      if (expression is PropertyAccess &&
          expression.propertyName.name == 'length') {
        return expression.target;
      } else if (expression is PrefixedIdentifier &&
          expression.identifier.name == 'length') {
        return expression.prefix;
      }
      return null;
    }

    var binary = node.thisOrAncestorOfType<BinaryExpression>();
    var operator = binary.operator.type;
    String getter;
    Expression lengthTarget;
    var rightValue = getIntValue(binary.rightOperand);
    if (rightValue != null) {
      lengthTarget = getLengthTarget(binary.leftOperand);
      if (rightValue == 0) {
        if (operator == TokenType.EQ_EQ || operator == TokenType.LT_EQ) {
          getter = 'isEmpty';
          fixKind = DartFixKind.REPLACE_WITH_IS_EMPTY;
        } else if (operator == TokenType.GT || operator == TokenType.BANG_EQ) {
          getter = 'isNotEmpty';
          fixKind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
        }
      } else if (rightValue == 1) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator == TokenType.GT_EQ) {
          getter = 'isNotEmpty';
          fixKind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
        } else if (operator == TokenType.LT) {
          getter = 'isEmpty';
          fixKind = DartFixKind.REPLACE_WITH_IS_EMPTY;
        }
      }
    } else {
      var leftValue = getIntValue(binary.leftOperand);
      if (leftValue != null) {
        lengthTarget = getLengthTarget(binary.rightOperand);
        if (leftValue == 0) {
          if (operator == TokenType.EQ_EQ || operator == TokenType.GT_EQ) {
            getter = 'isEmpty';
            fixKind = DartFixKind.REPLACE_WITH_IS_EMPTY;
          } else if (operator == TokenType.LT ||
              operator == TokenType.BANG_EQ) {
            getter = 'isNotEmpty';
            fixKind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
          }
        } else if (leftValue == 1) {
          // '1 <= length' is same as 'isNotEmpty',
          // and '1 > length' is same as 'isEmpty'
          if (operator == TokenType.LT_EQ) {
            getter = 'isNotEmpty';
            fixKind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
          } else if (operator == TokenType.GT) {
            getter = 'isEmpty';
            fixKind = DartFixKind.REPLACE_WITH_IS_EMPTY;
          }
        }
      }
    }
    if (lengthTarget == null || getter == null || fixKind == null) {
      return;
    }
    var target = utils.getNodeText(lengthTarget);
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(binary), '$target.$getter');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithIsEmpty newInstance() => ReplaceWithIsEmpty();
}
