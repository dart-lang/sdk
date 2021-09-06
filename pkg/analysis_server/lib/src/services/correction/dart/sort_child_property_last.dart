// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SortChildPropertyLast extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.SORT_CHILD_PROPERTY_LAST;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.SORT_CHILD_PROPERTY_LAST;

  @override
  FixKind get multiFixKind => DartFixKind.SORT_CHILD_PROPERTY_LAST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var childProp = _findNamedExpression(node);
    if (childProp == null) {
      return;
    }

    var creationExpression = childProp.parent?.parent;
    if (creationExpression is! InstanceCreationExpression ||
        !flutter.isWidgetCreation(creationExpression)) {
      return;
    }

    var args = creationExpression.argumentList;

    var last = args.arguments.last;
    if (last == childProp) {
      // Already sorted.
      return;
    }

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      var hasTrailingComma = last.endToken.next!.type == TokenType.COMMA;

      var childStart = childProp.beginToken.previous!.end;
      var childEnd = childProp.endToken.next!.end;
      var childRange = range.startOffsetEndOffset(childStart, childEnd);

      var deletionRange = childRange;
      if (childProp == args.arguments.first) {
        var deletionStart = childProp.offset;
        var deletionEnd = args.arguments[1].offset;
        deletionRange = range.startOffsetEndOffset(deletionStart, deletionEnd);
      }

      if (!hasTrailingComma) {
        childEnd = childProp.end;
        childRange = range.startOffsetEndOffset(childStart, childEnd);
      }
      var childText = utils.getRangeText(childRange);

      var insertionPoint = last.end;
      if (hasTrailingComma) {
        insertionPoint = last.endToken.next!.end;
      } else if (childStart == childProp.offset) {
        childText = ', $childText';
      } else {
        childText = ',$childText';
      }

      fileEditBuilder.addDeletion(deletionRange);
      fileEditBuilder.addSimpleInsertion(insertionPoint, childText);

      builder.setSelection(Position(file, insertionPoint));
    });
  }

  /// Using the [node] as the starting point, find the named expression that is
  /// for either the `child` or `children` parameter.
  NamedExpression? _findNamedExpression(AstNode node) {
    if (node is NamedExpression) {
      var name = node.name.label.name;
      if (name == 'child' || name == 'children') {
        return node;
      }
    }
    return flutter.findNamedExpression(node, 'child') ??
        flutter.findNamedExpression(node, 'children');
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static SortChildPropertyLast newInstance() => SortChildPropertyLast();
}
