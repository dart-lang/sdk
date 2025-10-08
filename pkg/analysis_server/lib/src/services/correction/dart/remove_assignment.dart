// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveAssignment extends ResolvedCorrectionProducer {
  RemoveAssignment({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeAssignment;

  @override
  FixKind get multiFixKind => DartFixKind.removeAssignmentMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var expression = node;
    if (expression is! AssignmentExpression) {
      return;
    }

    SourceRange sourceRange;
    var parent = expression.parent;
    while (parent is ParenthesizedExpression) {
      parent = parent.parent;
    }
    if (parent is ExpressionStatement) {
      sourceRange = utils.getLinesRange(range.node(parent));
    } else {
      sourceRange = range.endEnd(
        expression.leftHandSide.endToken,
        expression.rightHandSide.endToken,
      );
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(sourceRange);
    });
  }
}
