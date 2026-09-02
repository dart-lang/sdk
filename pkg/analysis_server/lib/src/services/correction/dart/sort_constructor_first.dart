// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class SortConstructorFirst extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.sortConstructorFirst;

  @override
  FixKind get multiFixKind => DartFixKind.sortConstructorFirstMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var constructor =
        coveringNode?.thisOrAncestorOfType<ConstructorDeclaration>() ??
        coveringNode?.thisOrAncestorOfType<PrimaryConstructorBody>();
    if (constructor == null) return;

    var body =
        constructor.thisOrAncestorOfType<BlockClassBody>() ??
        constructor.thisOrAncestorOfType<BlockEnumBody>();
    if (body == null) return;

    int insertionOffset;
    if (body is BlockClassBody) {
      insertionOffset = body.leftBracket.end;
    } else if (body is BlockEnumBody) {
      insertionOffset =
          body.semicolon?.end ??
          body.constants.lastOrNull?.end ??
          body.leftBracket.end;
    } else {
      return;
    }

    // The text between the end of the previous member and the start of the
    // constructor's own text (comments/metadata included) is separator
    // whitespace, not part of the constructor. Moving it verbatim to the
    // front of the member list (as this fix used to do) turned a blank line
    // that separated the constructor from the *previous* member into a
    // stray leading blank line at the top of the body, while leaving no
    // separator between the relocated constructor and the member that now
    // follows it.
    var lineInfo = unitResult.lineInfo;
    var previousToken = constructor.firstNonCommentToken.previous!;
    var nodeRange = range.nodeWithComments(lineInfo, constructor);
    var gapText = utils.getRangeText(
      SourceRange(previousToken.end, nodeRange.offset - previousToken.end),
    );
    var nodeText = utils.getRangeText(nodeRange);

    // The constructor always starts on its own line at the insertion point,
    // using just the newline and indentation from the end of the gap (never
    // a leading blank line, even if one separated it from its previous
    // member at its old position). The one exception is an enum body, where
    // the insertion point is the boundary between the constant list and the
    // members that follow it; see `leadingBlankLine` below.
    var eol = utils.endOfLine;
    var lastNewline = gapText.lastIndexOf(eol);
    var newlineAndIndent = lastNewline < 0
        ? gapText
        : gapText.substring(lastNewline);
    var hadBlankLineBeforeOldPosition = eol.allMatches(gapText).length > 1;

    // If a blank line used to separate the constructor from the previous
    // member, that separation should still exist somewhere: move it after
    // the constructor, so it now separates the constructor from whatever
    // follows it at the insertion point. But skip this if a blank line is
    // already there naturally (e.g. the insertion point is followed by a
    // blank line unrelated to the constructor's old position), to avoid a
    // double blank line.
    var alreadyHasBlankLineAfter = _hasBlankLineAfter(
      lineInfo,
      insertionOffset,
    );
    var blankLineSeparator =
        hadBlankLineBeforeOldPosition && !alreadyHasBlankLineAfter ? eol : '';

    // For an enum, the insertion point is right after the constant list
    // (the semicolon, or the last constant). If the file already uses blank
    // lines to separate members (as evidenced by a blank line having
    // separated the constructor from its own previous member), also add a
    // blank line between the constant list and the relocated constructor,
    // so that boundary isn't left inconsistent with the rest of the file.
    // A class body has no such analogous boundary: the insertion point
    // there is the opening brace, where a leading blank line is never
    // wanted.
    var leadingBlankLine =
        body is BlockEnumBody && hadBlankLineBeforeOldPosition ? eol : '';

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
        SourceRange(previousToken.end, nodeRange.end - previousToken.end),
      );
      builder.addSimpleInsertion(
        insertionOffset,
        '$leadingBlankLine$newlineAndIndent$nodeText$blankLineSeparator',
      );
    });
  }

  /// Whether the line containing [offset] is blank from [offset] onward,
  /// and the line following it is blank too.
  bool _hasBlankLineAfter(LineInfo lineInfo, int offset) {
    var lineNumber = lineInfo.getLocation(offset).lineNumber;
    if (lineNumber >= lineInfo.lineCount) return false;
    var nextLineStart = lineInfo.getOffsetOfLine(lineNumber);
    var content = unitResult.content;
    if (content.substring(offset, nextLineStart).trim().isNotEmpty) {
      return false;
    }
    if (lineNumber + 1 >= lineInfo.lineCount) return false;
    var lineAfterNextStart = lineInfo.getOffsetOfLine(lineNumber + 1);
    return content.substring(nextLineStart, lineAfterNextStart).trim().isEmpty;
  }
}
