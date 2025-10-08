// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeadIfNull extends ResolvedCorrectionProducer {
  RemoveDeadIfNull({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // This fix removes the right operand of an if-null which is not
      // predictably the right thing to do.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.removeIfNullOperator;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var sourceRange = findIfNull();
    if (sourceRange == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(sourceRange);
    });
  }

  /// Finds the dead if-null expression above [node].
  SourceRange? findIfNull() {
    var child = node;
    var parent = node.parent;
    while (parent != null) {
      if (parent is BinaryExpression &&
          parent.operator.type == TokenType.QUESTION_QUESTION &&
          parent.rightOperand == child) {
        return range.endEnd(parent.leftOperand, parent.rightOperand);
      }
      if (parent is AssignmentExpression &&
          parent.operator.type == TokenType.QUESTION_QUESTION_EQ &&
          parent.rightHandSide == child) {
        var assignee = parent.leftHandSide;
        var grandParent = parent.parent;
        if (grandParent is ExpressionStatement &&
            assignee is SimpleIdentifier) {
          return utils.getLinesRange(range.node(grandParent));
        } else {
          return range.endEnd(parent.leftHandSide, parent.rightHandSide);
        }
      }
      child = parent;
      parent = parent.parent;
    }
    return null;
  }
}
