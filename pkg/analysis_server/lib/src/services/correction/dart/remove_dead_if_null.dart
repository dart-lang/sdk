// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeadIfNull extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_IF_NULL_OPERATOR;

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
  SourceRange findIfNull() {
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
        if (parent.parent is ExpressionStatement &&
            assignee is SimpleIdentifier &&
            assignee.staticElement is PromotableElement) {
          return utils.getLinesRange(range.node(parent.parent));
        } else {
          return range.endEnd(parent.leftHandSide, parent.rightHandSide);
        }
      }
      child = parent;
      parent = parent.parent;
    }
    return null;
  }

  /// Returns an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveDeadIfNull newInstance() => RemoveDeadIfNull();
}
