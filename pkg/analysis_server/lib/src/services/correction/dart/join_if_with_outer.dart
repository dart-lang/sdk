// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class JoinIfWithOuter extends ResolvedCorrectionProducer {
  JoinIfWithOuter({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.JOIN_IF_WITH_OUTER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // climb up condition to the (supposedly) "if" statement
    var targetIfStatement = node.enclosingIfStatement;
    // prepare target "if" statement
    if (targetIfStatement == null) {
      return;
    }
    if (targetIfStatement.elseStatement != null) {
      return;
    }
    // prepare outer "if" statement
    var parent = targetIfStatement.parent;
    if (parent is Block) {
      if (parent.statements.length != 1) {
        return;
      }
      parent = parent.parent;
    }
    if (parent is! IfStatement) {
      return;
    }
    var outerIfStatement = parent;
    if (outerIfStatement.elseStatement != null) {
      return;
    }

    // If target (inner) is if-case, we cannot join them.
    if (targetIfStatement.caseClause != null) {
      return;
    }

    // prepare environment
    var prefix = utils.getNodePrefix(outerIfStatement);
    // merge conditions
    var targetCondition = targetIfStatement.expression;
    var outerCondition = outerIfStatement.expression;
    var targetConditionSource = utils.getNodeText(targetCondition);
    var outerConditionSource = utils.getNodeText(outerCondition);
    if (targetCondition.shouldWrapParenthesisBeforeAnd) {
      targetConditionSource = '($targetConditionSource)';
    }
    if (outerCondition.shouldWrapParenthesisBeforeAnd) {
      outerConditionSource = '($outerConditionSource)';
    }

    var condition = '$outerConditionSource && $targetConditionSource';

    // If outer is if-case.
    var outerCaseClause = outerIfStatement.caseClause;
    if (outerCaseClause != null) {
      var casePattern = outerCaseClause.guardedPattern.pattern;
      var caseWhenExpression =
          outerCaseClause.guardedPattern.whenClause?.expression;

      if (caseWhenExpression != null) {
        var caseWhenSource = '$caseWhenExpression';
        if (caseWhenExpression.shouldWrapParenthesisBeforeAnd) {
          caseWhenSource = '($caseWhenSource)';
        }

        condition =
            '$outerConditionSource case $casePattern when $caseWhenSource && $targetConditionSource';
      } else {
        condition =
            '$outerConditionSource case $casePattern when $targetConditionSource';
      }
    }

    // replace outer "if" statement
    var targetThenStatement = targetIfStatement.thenStatement;
    var targetThenStatements = getStatements(targetThenStatement);
    var lineRanges = utils.getLinesRangeStatements(targetThenStatements);
    var oldSource = utils.getRangeText(lineRanges);
    var newSource = utils.indentSourceLeftRight(oldSource);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(outerIfStatement),
        'if ($condition) {$eol$newSource$prefix}',
      );
    });
  }
}
