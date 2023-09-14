// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedCatchStack extends ResolvedCorrectionProducer {
  @override
  // May not be appropriate while actively coding.
  bool get canBeAppliedAutomatically => false;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_CATCH_STACK;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNUSED_CATCH_STACK_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final stackTraceParameter = node;
    if (stackTraceParameter is! CatchClauseParameter) {
      return;
    }

    final catchClause = stackTraceParameter.parent;
    if (catchClause is! CatchClause) {
      return;
    }

    final exceptionParameter = catchClause.exceptionParameter;
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
