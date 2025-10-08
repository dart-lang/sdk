// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedCatchClause extends ResolvedCorrectionProducer {
  RemoveUnusedCatchClause({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // May not be appropriate while actively coding.
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => DartFixKind.removeUnusedCatchClause;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnusedCatchClauseMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var exceptionParameter = node;
    if (exceptionParameter is! CatchClauseParameter) {
      return;
    }

    var catchClause = exceptionParameter.parent;
    if (catchClause is! CatchClause) {
      return;
    }

    var catchKeyword = catchClause.catchKeyword;
    if (catchKeyword == null) {
      return;
    }

    if (catchClause.exceptionParameter == exceptionParameter) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(catchKeyword, catchClause.body));
      });
    }
  }
}
