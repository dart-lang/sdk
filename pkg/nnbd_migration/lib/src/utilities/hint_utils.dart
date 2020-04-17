// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:nnbd_migration/src/edit_plan.dart';

/// Determines if the given [token] is followed by a nullability hint, and if
/// so, returns information about it.  Otherwise returns `null`.
HintComment getPostfixHint(Token token) {
  var commentToken = token.next.precedingComments;
  if (commentToken != null) {
    HintCommentKind kind;
    if (commentToken.lexeme == '/*!*/') {
      kind = HintCommentKind.bang;
    } else if (commentToken.lexeme == '/*?*/') {
      kind = HintCommentKind.question;
    } else {
      return null;
    }
    return HintComment(
        kind,
        token.end,
        commentToken.offset,
        commentToken.offset + '/*'.length,
        commentToken.end - '*/'.length,
        commentToken.end,
        commentToken.end);
  }
  return null;
}

/// Determines if the given [token] is preceded by a hint, and if so, returns
/// information about it.  Otherwise returns `null`.
HintComment getPrefixHint(Token token) {
  Token commentToken = token.precedingComments;
  if (commentToken != null) {
    while (true) {
      var nextComment = commentToken.next;
      if (nextComment == null) break;
      commentToken = nextComment;
    }
    var lexeme = commentToken.lexeme;
    if (lexeme.startsWith('/*') &&
        lexeme.endsWith('*/') &&
        lexeme.length > 'late'.length) {
      var commentText =
          lexeme.substring('/*'.length, lexeme.length - '*/'.length).trim();
      if (commentText == 'late') {
        var commentOffset = commentToken.offset;
        var lateOffset = commentOffset + commentToken.lexeme.indexOf('late');
        return HintComment(
            HintCommentKind.late_,
            commentOffset,
            commentOffset,
            lateOffset,
            lateOffset + 'late'.length,
            commentToken.end,
            token.offset);
      }
    }
  }
  return null;
}

/// Information about a hint found in a source file.
class HintComment {
  static final _alphaNumericRegexp = RegExp('[a-zA-Z0-9]');

  /// What kind of hint this is.
  final HintCommentKind kind;

  /// The file offset of the first character that should be removed if the hint
  /// is to be removed.
  final int _removeOffset;

  /// The file offset of the first character of the hint comment itself.
  final int _commentOffset;

  /// The file offset of the first character that should be kept if the hint is
  /// to be replaced with the hinted text.
  final int _keepOffset;

  /// The file offset just beyond the last character that should be kept if the
  /// hint is to be replaced with the hinted text.
  final int _keepEnd;

  /// The file offset just beyond the last character of the hint comment itself.
  final int _commentEnd;

  /// The file offset just beyond the last character that should be removed if
  /// the hint is to be removed.
  final int _removeEnd;

  HintComment(this.kind, this._removeOffset, this._commentOffset,
      this._keepOffset, this._keepEnd, this._commentEnd, this._removeEnd)
      : assert(_removeOffset <= _commentOffset),
        assert(_commentOffset < _keepOffset),
        assert(_keepOffset < _keepEnd),
        assert(_keepEnd < _commentEnd),
        assert(_commentEnd <= _removeEnd);

  /// Creates the changes necessary to accept the given hint (replace it with
  /// its contents and fix up whitespace).
  Map<int, List<AtomicEdit>> changesToAccept(String sourceText,
      {AtomicEditInfo info}) {
    bool prependSpace = false;
    bool appendSpace = false;
    var removeOffset = _removeOffset;
    var removeEnd = _removeEnd;
    if (_isAlphaNumericBeforeOffset(sourceText, removeOffset) &&
        _isAlphaNumericAtOffset(sourceText, _keepOffset)) {
      if (sourceText[removeOffset] == ' ') {
        // We can just keep this space.
        removeOffset++;
      } else {
        prependSpace = true;
      }
    }
    if (_isAlphaNumericBeforeOffset(sourceText, _keepEnd) &&
        _isAlphaNumericAtOffset(sourceText, removeEnd)) {
      if (sourceText[removeEnd - 1] == ' ') {
        // We can just keep this space.
        removeEnd--;
      } else {
        appendSpace = true;
      }
    }

    return {
      removeOffset: [
        if (prependSpace) AtomicEdit.insert(' '),
        AtomicEdit.delete(_keepOffset - removeOffset, info: info)
      ],
      _keepEnd: [AtomicEdit.delete(removeEnd - _keepEnd, info: info)],
      if (appendSpace) removeEnd: [AtomicEdit.insert(' ')]
    };
  }

  /// Creates the changes necessary to remove the given hint (and fix up
  /// whitespace).
  Map<int, List<AtomicEdit>> changesToRemove(String sourceText,
      {AtomicEditInfo info}) {
    bool appendSpace = false;
    var removeOffset = this._removeOffset;
    if (_isAlphaNumericBeforeOffset(sourceText, removeOffset) &&
        _isAlphaNumericAtOffset(sourceText, _removeEnd)) {
      if (sourceText[removeOffset] == ' ') {
        // We can just keep this space.
        removeOffset++;
      } else {
        appendSpace = true;
      }
    }
    return {
      removeOffset: [
        AtomicEdit.delete(_removeEnd - removeOffset, info: info),
        if (appendSpace) AtomicEdit.insert(' ')
      ]
    };
  }

  /// Creates the changes necessary to replace the given hint with a different
  /// hint.
  Map<int, List<AtomicEdit>> changesToReplace(
      String sourceText, String replacement,
      {AtomicEditInfo info}) {
    return {
      _commentOffset: [
        AtomicEdit.replace(_commentEnd - _commentOffset, replacement,
            info: info)
      ]
    };
  }

  static bool _isAlphaNumericAtOffset(String sourceText, int offset) {
    return offset < sourceText.length &&
        _alphaNumericRegexp.hasMatch(sourceText[offset]);
  }

  static bool _isAlphaNumericBeforeOffset(String sourceText, int offset) {
    return offset > 0 && _alphaNumericRegexp.hasMatch(sourceText[offset - 1]);
  }
}

/// Types of hint comments
enum HintCommentKind {
  /// The comment `/*!*/`, which indicates that the type should not have a `?`
  /// appended.
  bang,

  /// The comment `/*?*/`, which indicates that the type should have a `?`
  /// appended.
  question,

  /// The comment `/*late*/`, which indicates that the variable declaration
  /// should be late.
  late_,
}
