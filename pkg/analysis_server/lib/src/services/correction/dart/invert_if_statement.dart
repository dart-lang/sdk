// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class InvertIfStatement extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.INVERT_IF_STATEMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! IfStatement) {
      return;
    }
    var ifStatement = node as IfStatement;
    var condition = ifStatement.condition;
    // should have both "then" and "else"
    var thenStatement = ifStatement.thenStatement;
    var elseStatement = ifStatement.elseStatement;
    if (thenStatement == null || elseStatement == null) {
      return;
    }
    // prepare source
    var invertedCondition = utils.invertCondition(condition);
    var thenSource = utils.getNodeText(thenStatement);
    var elseSource = utils.getNodeText(elseStatement);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(condition), invertedCondition);
      builder.addSimpleReplacement(range.node(thenStatement), elseSource);
      builder.addSimpleReplacement(range.node(elseStatement), thenSource);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static InvertIfStatement newInstance() => InvertIfStatement();
}
