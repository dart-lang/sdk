// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedCatchStack extends ResolvedCorrectionProducer {
  RemoveUnusedCatchStack({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // May not be appropriate while actively coding.
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => DartFixKind.removeUnusedCatchStack;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnusedCatchStackMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var stackTraceParameter = node;
    if (stackTraceParameter is! CatchClauseParameter) {
      return;
    }

    var catchClause = stackTraceParameter.parent;
    if (catchClause is! CatchClause) {
      return;
    }

    var exceptionParameter = catchClause.exceptionParameter;
    if (exceptionParameter == null) {
      return;
    }

    if (catchClause.stackTraceParameter == stackTraceParameter) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(
          range.endEnd(exceptionParameter, stackTraceParameter),
        );
      });
    }
  }
}
