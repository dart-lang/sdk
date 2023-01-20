// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
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
    var firstToken = node.beginToken.precedingComments ?? node.beginToken;
    var lastToken = node.endToken;
    var text = utils.getRangeText(range.startEnd(firstToken, lastToken));
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.nodeInList(initializers, node));
      builder.addSimpleInsertion(initializers.last.end, ', $text');
    });
  }
}
