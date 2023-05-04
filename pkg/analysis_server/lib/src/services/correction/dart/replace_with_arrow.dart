// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithArrow extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_ARROW;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_WITH_ARROW_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! SwitchExpressionCase) {
      return;
    }

    final arrow = node.arrow;
    if (arrow.lexeme != '=>') {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.endEnd(node.guardedPattern, arrow),
          ' =>',
        );
      });
    }
  }
}
