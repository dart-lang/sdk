// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveEmptyConstructorBody extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_EMPTY_CONSTRUCTOR_BODY;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_EMPTY_CONSTRUCTOR_BODY_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! Block) {
      return;
    }
    if (node.leftBracket.isSynthetic || node.rightBracket.isSynthetic) {
      return;
    }

    var blockBody = node.parent;
    if (blockBody is! BlockFunctionBody) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        utils.getLinesRange(range.node(blockBody)),
        ';',
      );
    });
  }
}
