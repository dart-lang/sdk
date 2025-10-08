// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryLate extends ResolvedCorrectionProducer {
  RemoveUnnecessaryLate({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeUnnecessaryLate;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnnecessaryLateMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var declarationList = node;
    if (declarationList is! VariableDeclarationList) {
      return;
    }

    if (declarationList.variables.any((v) => v.initializer == null)) {
      // At least one variable declared in the same list does _not_ have an
      // initializer; removing `late` may make such a variable declaration
      // invalid.
      return;
    }

    var lateToken = declarationList.lateKeyword;
    if (lateToken == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(lateToken, lateToken.next!));
    });
  }
}
