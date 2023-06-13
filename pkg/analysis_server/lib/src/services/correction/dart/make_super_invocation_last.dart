// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeSuperInvocationLast extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.MAKE_SUPER_INVOCATION_LAST;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! ConstructorInitializer) return;
    var parent = node.parent;
    if (parent is! ConstructorDeclaration) return;

    var initializers = parent.initializers;
    var lineInfo = unitResult.lineInfo;

    var deletionRange =
        range.nodeInListWithComments(lineInfo, initializers, node);

    var nodeRange = range.nodeWithComments(lineInfo, node);
    var text = utils.getRangeText(nodeRange);
    var insertionOffset = range
        .trailingComment(lineInfo, initializers.last.endToken,
            returnComma: false)
        .token
        .end;
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(deletionRange);
      builder.addSimpleInsertion(insertionOffset, ', $text');
    });
  }
}
