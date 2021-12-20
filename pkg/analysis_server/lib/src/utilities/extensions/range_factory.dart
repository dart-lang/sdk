// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

extension RangeFactoryExtensions on RangeFactory {
  /// Return a source range that covers the given [node] in the containing
  /// [list]. This includes a leading or trailing comma, as appropriate, and any
  /// leading or trailing comments. The [lineInfo] is used to differentiate
  /// trailing comments (on the same line as the end of the node) from leading
  /// comments (on lines between the start of the node and the preceding comma).
  ///
  /// Throws an `ArgumentError` if the [node] is not an element of the [list].
  SourceRange nodeInListWithComments<T extends AstNode>(
      LineInfo lineInfo, NodeList<T> list, T node) {
    // TODO(brianwilkerson) Improve the name and signature of this method and
    //  make it part of the API of either `RangeFactory` or
    //  `DartFileEditBuilder`. The implementation currently assumes that the
    //  list is an argument list, and we might want to generalize that.
    // TODO(brianwilkerson) Consider adding parameters to allow us to access the
    //  left and right parentheses in cases where the only element of the list
    //  is being removed.
    // TODO(brianwilkerson) Consider adding a `separator` parameter so that we
    //  can handle things like statements in a block.
    if (list.length == 1) {
      if (list[0] != node) {
        throw ArgumentError('The node must be in the list.');
      }
      // If there's only one item in the list, then delete everything including
      // any leading or trailing comments, including any trailing comma.
      var leadingComment = _leadingComment(lineInfo, node.beginToken);
      var trailingComment = _trailingComment(lineInfo, node.endToken, true);
      return startEnd(leadingComment, trailingComment);
    }
    final index = list.indexOf(node);
    if (index < 0) {
      throw ArgumentError('The node must be in the list.');
    }
    if (index == 0) {
      // If this is the first item in the list, then delete everything from the
      // leading comment for this item to the leading comment for the next item.
      // This will include the comment after this item.
      var thisLeadingComment = _leadingComment(lineInfo, node.beginToken);
      var nextLeadingComment = _leadingComment(lineInfo, list[1].beginToken);
      return startStart(thisLeadingComment, nextLeadingComment);
    } else {
      // If this isn't the first item in the list, then delete everything from
      // the end of the previous item, after the comma and any trailing comment,
      // to the end of this item, also after the comma and any trailing comment.
      var previousTrailingComment =
          _trailingComment(lineInfo, list[index - 1].endToken, false);
      var previousHasTrailingComment = previousTrailingComment is CommentToken;
      var thisTrailingComment =
          _trailingComment(lineInfo, node.endToken, previousHasTrailingComment);
      if (!previousHasTrailingComment && thisTrailingComment is CommentToken) {
        // But if this item has a trailing comment and the previous didn't, then
        // we'd be deleting both commas, which would leave invalid code. We
        // can't leave the comment, so instead we leave the preceding comma.
        previousTrailingComment = previousTrailingComment.next!;
      }
      return endEnd(previousTrailingComment, thisTrailingComment);
    }
  }

  /// Return a source range that covers the given [node] with any leading and
  /// trailing comments.
  ///
  /// The range begins at the start of any leading comment token (excluding any
  /// token considered a trailing comment for the previous node) or the start
  /// of the node itself if there are none.
  ///
  /// The range ends at the end of the trailing comment token or the end of the
  /// node itself if there is not one.
  SourceRange nodeWithComments(LineInfo lineInfo, AstNode node) {
    // If the node is the first thing in the unit, leading comments are treated
    // as headers and should never be included in the range.
    final isFirstItem = node.beginToken == node.root.beginToken;

    var thisLeadingComment = isFirstItem
        ? node.beginToken
        : _leadingComment(lineInfo, node.beginToken);
    var thisTrailingComment = _trailingComment(lineInfo, node.endToken, false);

    return startEnd(thisLeadingComment, thisTrailingComment);
  }

  /// Return the left-most comment immediately before the [token] that is not on
  /// the same line as the first non-comment token before the [token]. Return
  /// the [token] if there is no such comment.
  Token _leadingComment(LineInfo lineInfo, Token token) {
    var previous = token.previous;
    if (previous == null || previous.type == TokenType.EOF) {
      return token.precedingComments ?? token;
    }
    var previousLine = lineInfo.getLocation(previous.offset).lineNumber;
    Token? comment = token.precedingComments;
    while (comment != null) {
      var commentLine = lineInfo.getLocation(comment.offset).lineNumber;
      if (commentLine != previousLine) {
        break;
      }
      comment = comment.next;
    }
    return comment ?? token;
  }

  /// Return the comment token immediately following the [token] if it is on the
  /// same line as the [token], or the [token] if there is no comment after the
  /// [token] or if the comment is on a different line than the [token]. If
  /// [returnComma] is `true` and there is a comma after the [token], then the
  /// comma will be returned when the [token] would have been.
  Token _trailingComment(LineInfo lineInfo, Token token, bool returnComma) {
    var lastToken = token;
    var nextToken = lastToken.next!;
    if (nextToken.type == TokenType.COMMA) {
      lastToken = nextToken;
      nextToken = lastToken.next!;
    }
    var tokenLine = lineInfo.getLocation(lastToken.offset).lineNumber;
    Token? comment = nextToken.precedingComments;
    if (comment != null &&
        lineInfo.getLocation(comment.offset).lineNumber == tokenLine) {
      // This doesn't account for the possibility of multiple trailing block
      // comments.
      return comment;
    }
    return returnComma ? lastToken : token;
  }
}
