// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ExchangeOperands extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.EXCHANGE_OPERANDS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // check that user invokes quick assist on binary expression
    if (node is! BinaryExpression) {
      return;
    }
    var binaryExpression = node as BinaryExpression;
    // prepare operator position
    if (!isOperatorSelected(binaryExpression)) {
      return;
    }
    // add edits
    var leftOperand = binaryExpression.leftOperand;
    var rightOperand = binaryExpression.rightOperand;
    // find "wide" enclosing binary expression with same operator
    while (binaryExpression.parent is BinaryExpression) {
      var newBinaryExpression = binaryExpression.parent as BinaryExpression;
      if (newBinaryExpression.operator.type != binaryExpression.operator.type) {
        break;
      }
      binaryExpression = newBinaryExpression;
    }
    // exchange parts of "wide" expression parts
    var leftRange = range.startEnd(binaryExpression, leftOperand);
    var rightRange = range.startEnd(rightOperand, binaryExpression);
    // maybe replace the operator
    var operator = binaryExpression.operator;
    // prepare a new operator
    String newOperator;
    var operatorType = operator.type;
    if (operatorType == TokenType.LT) {
      newOperator = '>';
    } else if (operatorType == TokenType.LT_EQ) {
      newOperator = '>=';
    } else if (operatorType == TokenType.GT) {
      newOperator = '<';
    } else if (operatorType == TokenType.GT_EQ) {
      newOperator = '<=';
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(leftRange, getRangeText(rightRange));
      builder.addSimpleReplacement(rightRange, getRangeText(leftRange));
      // Optionally replace the operator.
      if (newOperator != null) {
        builder.addSimpleReplacement(range.token(operator), newOperator);
      }
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ExchangeOperands newInstance() => ExchangeOperands();
}
