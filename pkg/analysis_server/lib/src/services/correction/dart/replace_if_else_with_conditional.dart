// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceIfElseWithConditional extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // should be "if"
    if (node is! IfStatement) {
      return;
    }
    var ifStatement = node as IfStatement;
    // single then/else statements
    var thenStatement = getSingleStatement(ifStatement.thenStatement);
    var elseStatement = getSingleStatement(ifStatement.elseStatement);
    if (thenStatement == null || elseStatement == null) {
      return;
    }
    Expression thenExpression;
    Expression elseExpression;
    var hasReturnStatements = false;
    if (thenStatement is ReturnStatement && elseStatement is ReturnStatement) {
      hasReturnStatements = true;
      thenExpression = thenStatement.expression;
      elseExpression = elseStatement.expression;
    }
    var hasExpressionStatements = false;
    if (thenStatement is ExpressionStatement &&
        elseStatement is ExpressionStatement) {
      if (thenStatement.expression is AssignmentExpression &&
          elseStatement.expression is AssignmentExpression) {
        hasExpressionStatements = true;
        thenExpression = thenStatement.expression;
        elseExpression = elseStatement.expression;
      }
    }

    if (hasReturnStatements || hasExpressionStatements) {
      await builder.addDartFileEdit(file, (builder) {
        // returns
        if (hasReturnStatements) {
          var conditionSrc = utils.getNodeText(ifStatement.condition);
          var theSrc = utils.getNodeText(thenExpression);
          var elseSrc = utils.getNodeText(elseExpression);
          builder.addSimpleReplacement(range.node(ifStatement),
              'return $conditionSrc ? $theSrc : $elseSrc;');
        }
        // assignments -> v = Conditional;
        if (hasExpressionStatements) {
          AssignmentExpression thenAssignment = thenExpression;
          AssignmentExpression elseAssignment = elseExpression;
          var thenTarget = utils.getNodeText(thenAssignment.leftHandSide);
          var elseTarget = utils.getNodeText(elseAssignment.leftHandSide);
          if (thenAssignment.operator.type == TokenType.EQ &&
              elseAssignment.operator.type == TokenType.EQ &&
              thenTarget == elseTarget) {
            var conditionSrc = utils.getNodeText(ifStatement.condition);
            var theSrc = utils.getNodeText(thenAssignment.rightHandSide);
            var elseSrc = utils.getNodeText(elseAssignment.rightHandSide);
            builder.addSimpleReplacement(range.node(ifStatement),
                '$thenTarget = $conditionSrc ? $theSrc : $elseSrc;');
          }
        }
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ReplaceIfElseWithConditional newInstance() =>
      ReplaceIfElseWithConditional();
}
