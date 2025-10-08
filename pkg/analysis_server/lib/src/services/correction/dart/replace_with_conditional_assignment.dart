// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithConditionalAssignment extends ResolvedCorrectionProducer {
  ReplaceWithConditionalAssignment({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.replaceWithConditionalAssignment;

  @override
  FixKind get multiFixKind => DartFixKind.replaceWithConditionalAssignmentMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    var ifStatement = node is IfStatement
        ? node
        : node.thisOrAncestorOfType<IfStatement>();
    if (ifStatement == null) {
      return;
    }

    var thenStatement = _uniqueStatement(ifStatement.thenStatement);
    if (thenStatement is ExpressionStatement) {
      var expression = thenStatement.expression.unParenthesized;
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

  static Statement _uniqueStatement(Statement statement) {
    if (statement is Block) {
      return _uniqueStatement(statement.statements.first);
    }
    return statement;
  }
}
