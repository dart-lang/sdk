// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveIfNullOperator extends ResolvedCorrectionProducer {
  RemoveIfNullOperator({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeIfNullOperator;

  @override
  FixKind get multiFixKind => DartFixKind.removeIfNullOperatorMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var expression = node.thisOrAncestorOfType<BinaryExpression>();
    if (expression == null) {
      return;
    }
    SourceRange sourceRange;
    if (expression.leftOperand.unParenthesized is NullLiteral) {
      sourceRange = range.startStart(
        expression.leftOperand,
        expression.rightOperand,
      );
    } else if (expression.rightOperand.unParenthesized is NullLiteral) {
      sourceRange = range.endEnd(
        expression.leftOperand,
        expression.rightOperand,
      );
    } else {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(sourceRange);
    });
  }
}
