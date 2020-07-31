// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeadIfNull extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_IF_NULL_OPERATOR;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    //
    // Find the dead if-null expression.
    //
    BinaryExpression findIfNull() {
      var child = node;
      var parent = node.parent;
      while (parent != null) {
        if (parent is BinaryExpression &&
            parent.operator.type == TokenType.QUESTION_QUESTION &&
            parent.rightOperand == child) {
          return parent;
        }
        child = parent;
        parent = parent.parent;
      }
      return null;
    }

    var expression = findIfNull();
    if (expression == null) {
      return;
    }
    //
    // Extract the information needed to build the edit.
    //
    var sourceRange =
        range.endEnd(expression.leftOperand, expression.rightOperand);
    //
    // Build the edit.
    //
    await builder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(sourceRange);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveDeadIfNull newInstance() => RemoveDeadIfNull();
}
