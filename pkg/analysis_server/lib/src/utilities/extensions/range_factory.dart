// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/utilities/index_range.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class TokenWithOptionalComma {
  final Token token;

  /// `true` if a comma is previously included.
  final bool includesComma;

  TokenWithOptionalComma(this.token, this.includesComma);
}

extension RangeFactoryExtensions on RangeFactory {
  /// Return a source range that covers the given [node] in the containing
  /// [list]. This includes a leading or trailing comma, as appropriate, and any
  /// leading or trailing comments. The [lineInfo] is used to differentiate
  /// trailing comments (on the same line as the end of the node) from leading
  /// comments (on lines between the start of the node and the preceding comma).
  ///
  /// Throws an `ArgumentError` if the [node] is not an element of the [list].
  ///
  /// This method is useful for deleting a node in a list.
  ///
  /// See [nodeWithComments].
  SourceRange nodeInListWithComments<T extends AstNode>(
      LineInfo lineInfo, NodeList<T> list, T node) {
    // TODO(brianwilkerson): Improve the name and signature of this method and
    //  make it part of the API of either `RangeFactory` or
    //  `DartFileEditBuilder`. The implementation currently assumes that the
    //  list is an argument list, and we might want to generalize that.
    // TODO(brianwilkerson): Consider adding parameters to allow us to access the
    //  left and right parentheses in cases where the only element of the list
    //  is being removed.
    // TODO(brianwilkerson): Consider adding a `separator` parameter so that we
    //  can handle things like statements in a block.
    if (list.length == 1) {
      if (list[0] != node) {
        throw ArgumentError('The node must be in the list.');
      }
      // If there's only one item in the list, then delete everything including
      // any leading or trailing comments, including any trailing comma.
      var leading = _leadingComment(lineInfo, node.beginToken);
      var trailing =
          trailingComment(lineInfo, node.endToken, returnComma: true);
      return startEnd(leading, trailing.token);
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
      var previousTrailingComment = trailingComment(
          lineInfo, list[index - 1].endToken,
          returnComma: false);
      var thisTrailingComment = trailingComment(lineInfo, node.endToken,
          returnComma: previousTrailingComment.includesComma);
      var previousToken = previousTrailingComment.token;
      if (!previousTrailingComment.includesComma &&
          thisTrailingComment.includesComma) {
        // But if this item has comma and the previous didn't, then
        // we'd be deleting both commas, which would leave invalid code. We
        // can't leave the comment, so instead we leave the preceding comma.
        previousToken = previousToken.next!;
      }
      return endEnd(previousToken, thisTrailingComment.token);
    }
  }

  /// Return a list of the ranges that cover all of the elements in the [list]
  /// whose index is in the list of [indexes].
  List<SourceRange> nodesInList<T extends AstNode>(
      NodeList<T> list, List<int> indexes) {
    var ranges = <SourceRange>[];
    var indexRanges = IndexRange.contiguousSubRanges(indexes);
    if (indexRanges.length == 1) {
      var indexRange = indexRanges[0];
      if (indexRange.lower == 0 && indexRange.upper == list.length - 1) {
        ranges.add(startEnd(list[indexRange.lower], list[indexRange.upper]));
        return ranges;
      }
    }
    for (var indexRange in indexRanges) {
      if (indexRange.lower == 0) {
        ranges.add(
            startStart(list[indexRange.lower], list[indexRange.upper + 1]));
      } else {
        ranges.add(endEnd(list[indexRange.lower - 1], list[indexRange.upper]));
      }
    }
    return ranges;
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
  ///
  /// See [nodeInListWithComments].
  SourceRange nodeWithComments(LineInfo lineInfo, AstNode node) {
    var beginToken = node.beginToken;
    // If the node is the first thing in the unit, leading comments are treated
    // as headers and should never be included in the range.
    final isFirstItem = beginToken == node.root.beginToken;

    var thisLeadingComment =
        isFirstItem ? beginToken : _leadingComment(lineInfo, beginToken);
    var thisTrailingComment =
        trailingComment(lineInfo, node.endToken, returnComma: false);

    return startEnd(thisLeadingComment, thisTrailingComment.token);
  }

  /// Return the trailing comment token following the [token] if it is on the
  /// same line as the [token], or return the [token] if there is no trailing
  /// comment or if the comment is on a different line than the [token].
  ///
  /// If there is a trailing comment, the returned `includesComma` indicates
  /// that there is a `comma` between the token and the trailing comment.
  ///
  /// If [returnComma] is `true` and there is a comma after the
  /// [token], then the comma will be returned when the [token] would have been.
  ///
  TokenWithOptionalComma trailingComment(LineInfo lineInfo, Token token,
      {required bool returnComma}) {
    var lastToken = token;
    var nextToken = lastToken.next!;
    var includesComma = nextToken.type == TokenType.COMMA &&
        _shouldIncludeCommentsAfterComma(lineInfo, nextToken);
    // There are comments after the comma that follows token, which are probably
    // meant to apply to token, so we must actually proceed with nextToken
    // instead of token.
    if (includesComma) {
      lastToken = nextToken;
      nextToken = lastToken.next!;
    }
    Token? comment = nextToken.precedingComments;

    // If there is no comment after the next comma, and the comma is on a
    // different line than the token.
    if (comment == null &&
        includesComma &&
        _areDifferentLines(lineInfo, token, lastToken)) {
      comment = lastToken.precedingComments;
      lastToken = token;
    }
    if (comment != null) {
      var tokenLine = _lineNumber(lineInfo, lastToken);
      if (_lineNumber(lineInfo, comment) == tokenLine) {
        var next = comment.next;
        while (next != null && _lineNumber(lineInfo, next) == tokenLine) {
          comment = next;
          next = next.next;
        }
        return TokenWithOptionalComma(comment!, includesComma);
      }
    }
    return TokenWithOptionalComma(returnComma ? lastToken : token, false);
  }

  /// Return `true` if the line number of the given [token] is different than
  /// the line number of the [other].
  bool _areDifferentLines(LineInfo lineInfo, Token token, Token other) =>
      _lineNumber(lineInfo, token) != _lineNumber(lineInfo, other);

  /// Return the left-most comment immediately before the [token] that is not on
  /// the same line as the first non-comment token before the [token]. Return
  /// the [token] if there is no such comment.
  Token _leadingComment(LineInfo lineInfo, Token token) {
    var previous = token.previous;
    if (previous == null || previous.isEof) {
      return token.precedingComments ?? token;
    }
    var tokenLine = lineInfo.getLocation(token.offset).lineNumber;
    var previousLine = lineInfo.getLocation(previous.offset).lineNumber;
    Token? comment = token.precedingComments;
    if (tokenLine != previousLine) {
      while (comment != null) {
        var commentLine = lineInfo.getLocation(comment.offset).lineNumber;
        if (commentLine != previousLine) {
          break;
        }
        comment = comment.next;
      }
    }
    return comment ?? token;
  }

  /// Return the line number of the given [token].
  int _lineNumber(LineInfo lineInfo, Token token) =>
      lineInfo.getLocation(token.offset).lineNumber;

  /// Return `true` if the comments preceding the token after the given [comma]
  /// should be included.
  ///
  /// This happens when the comments precede a closing token (e.g. parenthesis),
  /// or if the token next to [comma] is on a different line.
  bool _shouldIncludeCommentsAfterComma(LineInfo lineInfo, Token comma) {
    var tokenAfterComma = comma.next!;
    var tokenTypeAfterComma = tokenAfterComma.type;
    // Include the comment if the token next to comma is a closing token
    // (e.g. closing parenthesis).
    if (tokenTypeAfterComma == TokenType.CLOSE_CURLY_BRACKET ||
        tokenTypeAfterComma == TokenType.CLOSE_PAREN ||
        tokenTypeAfterComma == TokenType.CLOSE_SQUARE_BRACKET) {
      return true;
    }
    // Include the comment if the token next to comma is not on the same
    // line as the comma.
    return _areDifferentLines(lineInfo, comma, tokenAfterComma);
  }
}
