// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SortChildPropertyLast extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.SORT_CHILD_PROPERTY_LAST;

  @override
  FixKind get fixKind => DartFixKind.SORT_CHILD_PROPERTY_LAST;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    var childProp = flutter.findNamedExpression(node, 'child');
    childProp ??= flutter.findNamedExpression(node, 'children');
    if (childProp == null) {
      return;
    }

    var parent = childProp.parent?.parent;
    if (parent is! InstanceCreationExpression ||
        !flutter.isWidgetCreation(parent)) {
      return;
    }

    InstanceCreationExpression creationExpression = parent;
    var args = creationExpression.argumentList;

    var last = args.arguments.last;
    if (last == childProp) {
      // Already sorted.
      return;
    }

    await builder.addFileEdit(file, (DartFileEditBuilder fileEditBuilder) {
      var start = childProp.beginToken.previous.end;
      var end = childProp.endToken.next.end;
      var childRange = range.startOffsetEndOffset(start, end);

      var childText = utils.getRangeText(childRange);
      fileEditBuilder.addSimpleReplacement(childRange, '');
      fileEditBuilder.addSimpleInsertion(last.end + 1, childText);

      builder.setSelection(Position(file, last.end + 1));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static SortChildPropertyLast newInstance() => SortChildPropertyLast();
}
