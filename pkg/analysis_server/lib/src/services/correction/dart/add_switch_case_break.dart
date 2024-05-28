// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class AddSwitchCaseBreak extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.ADD_SWITCH_CASE_BREAK;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_SWITCH_CASE_BREAK_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var switchCase = node;
    if (switchCase is! SwitchCaseImpl) {
      return;
    }

    var switchStatement = switchCase.parent;
    if (switchStatement is! SwitchStatementImpl) {
      return;
    }

    var group = switchStatement.memberGroups.firstWhereOrNull(
      (group) => group.members.contains(switchCase),
    );
    var lastStatement = group?.statements.lastOrNull;
    if (lastStatement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(lastStatement.end, (builder) {
        builder.write(eol);
        builder.write(utils.getNodePrefix(lastStatement));
        builder.write('break;');
      });
    });
  }
}
