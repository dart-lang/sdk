// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class InvertConditionalExpression extends ResolvedCorrectionProducer {
  InvertConditionalExpression({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.INVERT_CONDITIONAL_EXPRESSION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    ConditionalExpression? conditionalExpression;
    conditionalExpression = node.thisOrAncestorOfType<ConditionalExpression>();
    if (conditionalExpression == null) {
      return;
    }

    var condition = conditionalExpression.condition;
    var invertedCondition = utils.invertCondition(condition);
    if (condition is ParenthesizedExpression) {
      // If the condition had parentheses, then the inverted condition
      // must also have parentheses, only when the final inverted condition
      // contains white space. We don't want to add parentheses if the
      // condition is not parenthesized.
      var expression = condition.expression;
      if (expression is BinaryExpression || expression is IsExpression) {
        invertedCondition = '($invertedCondition)';
      }
    }

    var thenCode = utils.getNodeText(conditionalExpression.thenExpression);
    var elseCode = utils.getNodeText(conditionalExpression.elseExpression);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(condition), invertedCondition);
      builder.addSimpleReplacement(
          range.node(conditionalExpression!.thenExpression), elseCode);
      builder.addSimpleReplacement(
          range.node(conditionalExpression.elseExpression), thenCode);
    });
  }
}
