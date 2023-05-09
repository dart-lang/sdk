// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToBooleanExpression extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;
  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_BOOL_EXPRESSION;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_BOOL_EXPRESSION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? node = this.node;
    if (node is BooleanLiteral) node = node.parent;
    if (node is! BinaryExpression) return;

    var rightOperand = node.rightOperand;
    var leftOperand = node.leftOperand;

    Expression expression;
    BooleanLiteral literal;

    var deleteRange = range.endEnd(leftOperand, rightOperand);

    if (rightOperand is BooleanLiteral) {
      literal = rightOperand;
      expression = node.leftOperand;
    } else if (leftOperand is BooleanLiteral) {
      literal = leftOperand;
      expression = node.rightOperand;
      deleteRange = range.startStart(leftOperand, rightOperand);
    } else {
      return;
    }

    var negated = !isPositiveCase(node, literal);
    await builder.addDartFileEdit(file, (builder) {
      if (negated) {
        builder.addSimpleInsertion(expression.offset, '!');
      }
      builder.addDeletion(deleteRange);
    });
  }

  static bool isPositiveCase(
      BinaryExpression expression, BooleanLiteral literal) {
    if (expression.operator.lexeme == '==') return literal.value;
    return !literal.value;
  }
}
