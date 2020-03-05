// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SplitAndCondition extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.SPLIT_AND_CONDITION;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    // check that user invokes quick assist on binary expression
    if (node is! BinaryExpression) {
      return;
    }
    BinaryExpression binaryExpression = node as BinaryExpression;
    // prepare operator position
    if (!isOperatorSelected(binaryExpression)) {
      return;
    }
    // should be &&
    if (binaryExpression.operator.type != TokenType.AMPERSAND_AMPERSAND) {
      return;
    }
    // prepare "if"
    Statement statement = node.thisOrAncestorOfType<Statement>();
    if (statement is! IfStatement) {
      return;
    }
    IfStatement ifStatement = statement as IfStatement;
    // no support "else"
    if (ifStatement.elseStatement != null) {
      return;
    }
    // check that binary expression is part of first level && condition of "if"
    BinaryExpression condition = binaryExpression;
    while (condition.parent is BinaryExpression &&
        (condition.parent as BinaryExpression).operator.type ==
            TokenType.AMPERSAND_AMPERSAND) {
      condition = condition.parent as BinaryExpression;
    }
    if (ifStatement.condition != condition) {
      return;
    }
    // prepare environment
    String prefix = utils.getNodePrefix(ifStatement);
    String indent = utils.getIndent(1);
    // prepare "rightCondition"
    String rightConditionSource;
    {
      SourceRange rightConditionRange =
          range.startEnd(binaryExpression.rightOperand, condition);
      rightConditionSource = getRangeText(rightConditionRange);
    }

    await builder.addFileEdit(file, (builder) {
      // remove "&& rightCondition"
      builder
          .addDeletion(range.endEnd(binaryExpression.leftOperand, condition));
      // update "then" statement
      Statement thenStatement = ifStatement.thenStatement;
      if (thenStatement is Block) {
        Block thenBlock = thenStatement;
        SourceRange thenBlockRange = range.node(thenBlock);
        // insert inner "if" with right part of "condition"
        int thenBlockInsideOffset = thenBlockRange.offset + 1;
        builder.addSimpleInsertion(thenBlockInsideOffset,
            '$eol$prefix${indent}if ($rightConditionSource) {');
        // insert closing "}" for inner "if"
        int thenBlockEnd = thenBlockRange.end;
        // insert before outer "then" block "}"
        builder.addSimpleInsertion(thenBlockEnd - 1, '$indent}$eol$prefix');
      } else {
        // insert inner "if" with right part of "condition"
        String source = '$eol$prefix${indent}if ($rightConditionSource)';
        builder.addSimpleInsertion(
            ifStatement.rightParenthesis.offset + 1, source);
      }
      // indent "then" statements to correspond inner "if"
      {
        List<Statement> thenStatements = getStatements(thenStatement);
        SourceRange linesRange = utils.getLinesRangeStatements(thenStatements);
        String thenIndentOld = '$prefix$indent';
        String thenIndentNew = '$thenIndentOld$indent';
        builder.addSimpleReplacement(
            linesRange,
            utils.replaceSourceRangeIndent(
                linesRange, thenIndentOld, thenIndentNew));
      }
    });
  }
}
