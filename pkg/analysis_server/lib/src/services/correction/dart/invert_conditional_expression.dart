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
    if (node is ConditionalExpression) {
      conditionalExpression = node as ConditionalExpression;
    } else if (node.parent is ConditionalExpression) {
      conditionalExpression = node.parent as ConditionalExpression;
    } else {
      return;
    }

    var condition = conditionalExpression.condition;
    var invertedCondition = utils.invertCondition(condition);

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
