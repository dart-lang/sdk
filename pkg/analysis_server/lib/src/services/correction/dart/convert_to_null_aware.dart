// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToNullAware extends ResolvedCorrectionProducer {
  ConvertToNullAware({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_NULL_AWARE;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_NULL_AWARE;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_NULL_AWARE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;
    var parent = targetNode.parent;
    if (parent is BinaryExpression) {
      var grandParent = parent.parent;
      if (grandParent is ConditionalExpression) {
        targetNode = grandParent;
      }
    }
    if (targetNode is! ConditionalExpression) {
      return;
    }
    var condition = targetNode.condition.unParenthesized;
    String conditionText;
    Expression nullExpression;
    Expression nonNullExpression;

    if (condition is BinaryExpression) {
      //
      // Identify the variable being compared to `null`, or return if the
      // condition isn't a simple comparison of `null` to another expression.
      //
      var leftOperand = condition.leftOperand;
      var rightOperand = condition.rightOperand;
      if (leftOperand is NullLiteral && rightOperand is! NullLiteral) {
        conditionText = rightOperand.toString();
      } else if (rightOperand is NullLiteral && leftOperand is! NullLiteral) {
        conditionText = leftOperand.toString();
      } else {
        return;
      }
      //
      // Identify the expression executed when the variable is `null` and when
      // it is non-`null`. Return if the `null` expression isn't a null literal
      // or if the non-`null` expression isn't a method invocation whose target
      // is the save variable being compared to `null`.
      //
      if (condition.operator.type == TokenType.EQ_EQ) {
        nullExpression = targetNode.thenExpression;
        nonNullExpression = targetNode.elseExpression;
      } else if (condition.operator.type == TokenType.BANG_EQ) {
        nonNullExpression = targetNode.thenExpression;
        nullExpression = targetNode.elseExpression;
      } else {
        return;
      }
      if (nullExpression.unParenthesized is! NullLiteral) {
        return;
      }
      Expression? resultExpression = nonNullExpression.unParenthesized;
      Token? operator;
      while (true) {
        switch (resultExpression) {
          case PrefixedIdentifier():
            operator = resultExpression.period;
            resultExpression = resultExpression.prefix;
          case MethodInvocation():
            operator = resultExpression.operator;
            resultExpression = resultExpression.target;
          case PostfixExpression()
              when resultExpression.operator.type == TokenType.BANG:
            // (Operator remains unaffected.)
            resultExpression = resultExpression.operand;
          case PropertyAccess():
            operator = resultExpression.operator;
            resultExpression = resultExpression.target;
          default:
            return;
        }
        if (resultExpression.toString() == conditionText) {
          break;
        }
      }
      if (resultExpression == null) {
        return;
      }

      SourceRange operatorRange;
      var optionalQuestionMark = '';
      if (operator != null) {
        if (operator.type == TokenType.PERIOD) {
          optionalQuestionMark = '?';
        }
        operatorRange = range.endStart(resultExpression, operator);
      } else if (resultExpression.parent is PostfixExpression) {
        // The case where the expression is just `foo!`.
        operatorRange =
            range.endEnd(resultExpression, resultExpression.parent!);
      } else {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(targetNode, nonNullExpression));
        builder.addSimpleReplacement(operatorRange, optionalQuestionMark);
        builder.addDeletion(range.endEnd(nonNullExpression, targetNode));
      });
    }
  }
}
