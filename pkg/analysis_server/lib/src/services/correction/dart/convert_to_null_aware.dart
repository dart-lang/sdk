// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToNullAware extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_NULL_AWARE;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_NULL_AWARE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node.parent is BinaryExpression &&
        node.parent.parent is ConditionalExpression) {
      node = node.parent.parent;
    }
    if (node is! ConditionalExpression) {
      return;
    }
    ConditionalExpression conditional = node;
    var condition = conditional.condition.unParenthesized;
    SimpleIdentifier identifier;
    Expression nullExpression;
    Expression nonNullExpression;
    int periodOffset;

    if (condition is BinaryExpression) {
      //
      // Identify the variable being compared to `null`, or return if the
      // condition isn't a simple comparison of `null` to a variable's value.
      //
      var leftOperand = condition.leftOperand;
      var rightOperand = condition.rightOperand;
      if (leftOperand is NullLiteral && rightOperand is SimpleIdentifier) {
        identifier = rightOperand;
      } else if (rightOperand is NullLiteral &&
          leftOperand is SimpleIdentifier) {
        identifier = leftOperand;
      } else {
        return;
      }
      if (identifier.staticElement is! LocalElement) {
        return;
      }
      //
      // Identify the expression executed when the variable is `null` and when
      // it is non-`null`. Return if the `null` expression isn't a null literal
      // or if the non-`null` expression isn't a method invocation whose target
      // is the save variable being compared to `null`.
      //
      if (condition.operator.type == TokenType.EQ_EQ) {
        nullExpression = conditional.thenExpression;
        nonNullExpression = conditional.elseExpression;
      } else if (condition.operator.type == TokenType.BANG_EQ) {
        nonNullExpression = conditional.thenExpression;
        nullExpression = conditional.elseExpression;
      }
      if (nullExpression == null || nonNullExpression == null) {
        return;
      }
      if (nullExpression.unParenthesized is! NullLiteral) {
        return;
      }
      var unwrappedExpression = nonNullExpression.unParenthesized;
      Expression target;
      Token operator;
      if (unwrappedExpression is MethodInvocation) {
        target = unwrappedExpression.target;
        operator = unwrappedExpression.operator;
      } else if (unwrappedExpression is PrefixedIdentifier) {
        target = unwrappedExpression.prefix;
        operator = unwrappedExpression.period;
      } else {
        return;
      }
      if (operator == null || operator.type != TokenType.PERIOD) {
        return;
      }
      if (!(target is SimpleIdentifier &&
          target.staticElement == identifier.staticElement)) {
        return;
      }
      periodOffset = operator.offset;

      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(node, nonNullExpression));
        builder.addSimpleInsertion(periodOffset, '?');
        builder.addDeletion(range.endEnd(nonNullExpression, node));
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToNullAware newInstance() => ConvertToNullAware();
}
