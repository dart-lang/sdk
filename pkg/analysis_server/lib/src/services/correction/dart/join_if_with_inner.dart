// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class JoinIfWithInner extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.JOIN_IF_WITH_INNER;

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
    // prepare inner "if" statement
    var targetThenStatement = targetIfStatement.thenStatement;
    var innerIfStatement = getSingleStatement(targetThenStatement);
    if (innerIfStatement is! IfStatement) {
      return;
    }
    if (innerIfStatement.elseStatement != null) {
      return;
    }
    // prepare environment
    var prefix = utils.getNodePrefix(targetIfStatement);
    // merge conditions
    var targetCondition = targetIfStatement.expression;
    var innerCondition = innerIfStatement.expression;
    var targetConditionSource = utils.getNodeText(targetCondition);
    var innerConditionSource = utils.getNodeText(innerCondition);
    if (shouldWrapParenthesisBeforeAnd(targetCondition)) {
      targetConditionSource = '($targetConditionSource)';
    }
    if (shouldWrapParenthesisBeforeAnd(innerCondition)) {
      innerConditionSource = '($innerConditionSource)';
    }
    var condition = '$targetConditionSource && $innerConditionSource';
    // replace target "if" statement
    var innerThenStatement = innerIfStatement.thenStatement;
    var innerThenStatements = getStatements(innerThenStatement);
    var lineRanges = utils.getLinesRangeStatements(innerThenStatements);
    var oldSource = utils.getRangeText(lineRanges);
    var newSource = utils.indentSourceLeftRight(oldSource);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    });
  }
}
