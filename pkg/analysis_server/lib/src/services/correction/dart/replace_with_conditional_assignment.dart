// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithConditionalAssignment extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    IfStatement ifStatement =
        node is IfStatement ? node : node.thisOrAncestorOfType<IfStatement>();
    if (ifStatement == null) {
      return;
    }
    var thenStatement = ifStatement.thenStatement;
    Statement uniqueStatement(Statement statement) {
      if (statement is Block) {
        return uniqueStatement(statement.statements.first);
      }
      return statement;
    }

    thenStatement = uniqueStatement(thenStatement);
    if (thenStatement is ExpressionStatement) {
      final expression = thenStatement.expression.unParenthesized;
      if (expression is AssignmentExpression) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addReplacement(range.node(ifStatement), (builder) {
            builder.write(utils.getNodeText(expression.leftHandSide));
            builder.write(' ??= ');
            builder.write(utils.getNodeText(expression.rightHandSide));
            builder.write(';');
          });
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithConditionalAssignment newInstance() =>
      ReplaceWithConditionalAssignment();
}
