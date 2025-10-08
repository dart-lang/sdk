// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveUnnecessaryStringEscape extends ParsedCorrectionProducer {
  RemoveUnnecessaryStringEscape({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeUnnecessaryStringEscape;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnnecessaryStringEscapeMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var offset = diagnostic?.problemMessage.offset;
    if (offset == null) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      if (node is! InterpolationString) {
        builder.addDeletion(SourceRange(offset, 1));
        return;
      }

      var childEntities = (node.parent as StringInterpolation).elements;
      var index = childEntities.indexOf(node as InterpolationString);
      var prevNode = index > 0 ? childEntities.elementAt(index - 1) : null;
      if (offset == node.offset &&
          (prevNode is InterpolationExpression &&
              prevNode.rightBracket == null)) {
        builder.addSimpleReplacement(SourceRange(offset, 1), '}');
        builder.addSimpleInsertion(
          childEntities.elementAt(index - 1).offset + 1,
          '{',
        );
      } else {
        builder.addDeletion(SourceRange(offset, 1));
      }
    });
  }
}
