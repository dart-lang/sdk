// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDuplicateCase extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_DUPLICATE_CASE;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_DUPLICATE_CASE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveredNode;
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveDuplicateCase newInstance() => RemoveDuplicateCase();
}
