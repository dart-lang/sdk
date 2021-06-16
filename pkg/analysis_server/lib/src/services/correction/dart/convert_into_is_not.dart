// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIntoIsNot extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_IS_NOT;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_IS_NOT;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_IS_NOT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the is expression
    var isExpression = node.thisOrAncestorOfType<IsExpression>();
    if (isExpression == null) {
      final node = this.node;
      if (node is PrefixExpression) {
        var operand = node.operand;
        if (operand is ParenthesizedExpression) {
          var expression = operand.expression;
          if (expression is IsExpression) {
            isExpression = expression;
          }
        }
      } else if (node is ParenthesizedExpression) {
        var expression = node.expression;
        if (expression is IsExpression) {
          isExpression = expression;
        }
      }
    }
    if (isExpression == null) {
      return;
    }
    if (isExpression.notOperator != null) {
      return;
    }
    // prepare enclosing ()
    var parExpression = isExpression.parent;
    if (parExpression is! ParenthesizedExpression) {
      return;
    }
    // prepare enclosing !()
    var prefExpression = parExpression.parent;
    if (prefExpression is! PrefixExpression) {
      return;
    }
    if (prefExpression.operator.type != TokenType.BANG) {
      return;
    }

    final isExpression_final = isExpression;
    await builder.addDartFileEdit(file, (builder) {
      if (getExpressionParentPrecedence(prefExpression) >=
          Precedence.relational) {
        builder.addDeletion(range.token(prefExpression.operator));
      } else {
        builder.addDeletion(
            range.startEnd(prefExpression, parExpression.leftParenthesis));
        builder.addDeletion(
            range.startEnd(parExpression.rightParenthesis, prefExpression));
      }
      builder.addSimpleInsertion(isExpression_final.isOperator.end, '!');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertIntoIsNot newInstance() => ConvertIntoIsNot();
}
