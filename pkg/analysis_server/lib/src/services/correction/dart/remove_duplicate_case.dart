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

class RemoveDuplicateCase extends ResolvedCorrectionProducer {
  RemoveDuplicateCase({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeDuplicateCase;

  @override
  FixKind get multiFixKind => DartFixKind.removeDuplicateCaseMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveringNode?.parent;
    if (node is! SwitchCase) {
      return;
    }

    var switchStatement = node.parent;
    if (switchStatement is! SwitchStatement) {
      return;
    }

    var members = switchStatement.members;
    var index = members.indexOf(node);
    await builder.addDartFileEdit(file, (builder) {
      SourceRange deletionRange;
      if (index > 0 && members[index - 1].statements.isNotEmpty) {
        deletionRange = range.node(node);
      } else {
        deletionRange = range.startEnd(node, node.colon);
      }
      builder.addDeletion(utils.getLinesRange(deletionRange));
    });
  }
}
