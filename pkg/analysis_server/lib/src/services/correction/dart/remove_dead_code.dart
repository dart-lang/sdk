// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeadCode extends CorrectionProducer {
  @override
  // Not predictably the correct action.
  bool get canBeAppliedInBulk => false;

  @override
  // Not predictably the correct action.
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_DEAD_CODE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final coveredNode = this.coveredNode;
    var parent = coveredNode?.parent;

    if (coveredNode is Expression) {
      if (parent is BinaryExpression) {
        if (parent.rightOperand == coveredNode) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(range.endEnd(parent.leftOperand, coveredNode));
          });
        }
      }
    } else if (coveredNode is Block) {
      var block = coveredNode;
      var statementsToRemove = <Statement>[];
      var problemMessage = diagnostic?.problemMessage;
      if (problemMessage == null) {
        return;
      }
      var errorRange =
          SourceRange(problemMessage.offset, problemMessage.length);
      for (var statement in block.statements) {
        if (range.node(statement).intersects(errorRange)) {
          statementsToRemove.add(statement);
        }
      }
      if (statementsToRemove.isNotEmpty) {
        var rangeToRemove = utils.getLinesRangeStatements(statementsToRemove);
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(rangeToRemove);
        });
      }
    } else if (coveredNode is Statement) {
      var rangeToRemove =
          utils.getLinesRangeStatements(<Statement>[coveredNode]);
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(rangeToRemove);
      });
    } else if (coveredNode is CatchClause && parent is TryStatement) {
      var catchClauses = parent.catchClauses;
      var index = catchClauses.indexOf(coveredNode);
      var previous = index == 0 ? parent.body : catchClauses[index - 1];
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.endEnd(previous, coveredNode));
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveDeadCode newInstance() => RemoveDeadCode();
}
