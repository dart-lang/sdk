// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SortChildPropertyLast extends ResolvedCorrectionProducer {
  SortChildPropertyLast({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.sortChildPropertyLast;

  @override
  FixKind get fixKind => DartFixKind.sortChildPropertyLast;

  @override
  FixKind get multiFixKind => DartFixKind.sortChildPropertyLastMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var childProperty = _findNamedArgument(node);
    if (childProperty == null) {
      return;
    }

    var creationExpression = childProperty.parent?.parent;
    if (creationExpression is! InstanceCreationExpression ||
        !creationExpression.isWidgetCreation) {
      return;
    }

    var args = creationExpression.argumentList;

    var last = args.arguments.last;
    if (last == childProperty) {
      // Already sorted.
      return;
    }

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      var hasTrailingComma = last.endToken.next!.type == TokenType.COMMA;

      var childStart = childProperty.beginToken.previous!.end;
      var childEnd = childProperty.endToken.next!.end;

      // There is definitely a next argument since `last != childProperty`.
      var nextArgument = args.arguments[1];
      var childLine = unitResult.lineInfo.getLocation(childEnd);
      var nextLine = unitResult.lineInfo.getLocation(nextArgument.offset);
      var argsAreOnSameLine = childLine.lineNumber == nextLine.lineNumber;
      if (!argsAreOnSameLine) {
        // A comment which comes after the child's trailing comma is technically
        // not associated with the child, but is clearly meant to be associated
        // with it. Move it as well.
        Token? precedingComment = nextArgument.beginToken.precedingComments;
        while (precedingComment is CommentToken) {
          var precedingCommentLine = unitResult.lineInfo.getLocation(
            precedingComment.offset,
          );
          if (precedingCommentLine.lineNumber == childLine.lineNumber) {
            childEnd = precedingComment.end;
          } else {
            break;
          }
          precedingComment = precedingComment.next;
        }
      }

      // The range of the child/children argument which is used for the inserted
      // text after the last argument. (This might be different from the text
      // which is deleted, insofar as leading/trailing whitespace is accounted
      // for.)
      var childRange = range.startOffsetEndOffset(childStart, childEnd);

      var deletionRange = childRange;
      if (childProperty == args.arguments.first) {
        var deletionStart = childProperty.offset;
        var deletionEnd = nextArgument.offset;
        deletionRange = range.startOffsetEndOffset(deletionStart, deletionEnd);
      }

      if (!hasTrailingComma) {
        childEnd = childProperty.end;
        childRange = range.startOffsetEndOffset(childStart, childEnd);
      }
      var childText = utils.getRangeText(childRange);

      var insertionPoint = last.end;
      if (hasTrailingComma) {
        insertionPoint = last.endToken.next!.end;
      } else if (childStart == childProperty.offset) {
        childText = ', $childText';
      } else {
        childText = ',$childText';
      }

      fileEditBuilder.addDeletion(deletionRange);
      fileEditBuilder.addSimpleInsertion(insertionPoint, childText);

      builder.setSelection(Position(file, insertionPoint));
    });
  }

  /// Using the [node] as the starting point, find the named argument that is
  /// for either the `child` or `children` parameter.
  NamedArgument? _findNamedArgument(AstNode node) {
    if (node is NamedArgument) {
      var name = node.name.lexeme;
      if (name == 'child' || name == 'children') {
        return node;
      }
    }
    return node.findArgumentNamed('child') ??
        node.findArgumentNamed('children');
  }
}
