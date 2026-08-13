// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';

/// Instances of the class `ToDoFinder` find to-do comments in Dart code.
class TodoFinder {
  /// The diagnostic reporter by which to-do comments will be reported.
  final DiagnosticReporter _diagnosticReporter;

  /// A regex for whitespace and comment markers to be removed from the text
  /// of multiline TODOs in multiline comments.
  final RegExp _commentNewlineAndMarker = RegExp('\\s*\\n\\s*\\*\\s*');

  /// A regex for any character that is not a comment marker `/` or whitespace
  /// used for finding the first "real" character of a comment to compare its
  /// indentation for wrapped todos.
  final RegExp _nonWhitespaceOrCommentMarker = RegExp('[^/ ]');

  /// Initialize a newly created to-do finder to report to-do comments to the
  /// given reporter.
  ///
  /// @param errorReporter the error reporter by which to-do comments will be
  ///        reported
  TodoFinder(this._diagnosticReporter);

  /// Search the comments in the given compilation unit for to-do comments and
  /// report an error for each.
  ///
  /// @param unit the compilation unit containing the to-do comments
  void findIn(CompilationUnit unit) {
    _gatherTodoComments(unit.beginToken, unit.lineInfo);
  }

  /// Search the comment tokens reachable from the given token and create errors
  /// for each to-do comment.
  ///
  /// @param token the head of the list of tokens being searched
  void _gatherTodoComments(Token? token, LineInfo lineInfo) {
    while (token != null && (!token.isEof || token.precedingComments != null)) {
      Token? commentToken = token.precedingComments;
      while (commentToken != null) {
        if (commentToken.type == TokenType.SINGLE_LINE_COMMENT ||
            commentToken.type == TokenType.MULTI_LINE_COMMENT) {
          commentToken = _scrapeTodoComment(commentToken, lineInfo);
        } else {
          commentToken = commentToken.next;
        }
      }
      if (token.next == token) {
        break;
      }
      token = token.next;
    }
  }

  /// Look for user defined tasks in comments starting [commentToken] and convert
  /// them into info level analysis issues.
  ///
  /// Subsequent comments that are indented with an additional space are
  /// considered continuations and will be included in a single analysis issue.
  ///
  /// Returns the next comment token to begin searching from (skipping over
  /// any continuations).
  Token? _scrapeTodoComment(Token commentToken, LineInfo lineInfo) {
    // Track the comment that will be returned for looking for the next `todo`.
    // This will be moved along if additional comments are consumed by multiline
    // TODOs.
    var nextComment = commentToken.next;
    CharacterLocation? commentLocation;

    _TodoFinder todoFinder = _TodoFinder(commentToken.lexeme);
    while (todoFinder.moveNext()) {
      int matchOffset = todoFinder.offset;
      String todoKind = todoFinder.todoKind;
      String todoText = todoFinder.todoText;

      commentLocation ??= lineInfo.getLocation(commentToken.offset);
      int offset = commentToken.offset + matchOffset;
      int column = commentLocation.columnNumber + matchOffset;
      int end = offset + todoText.length;

      if (commentToken.type == TokenType.MULTI_LINE_COMMENT) {
        // Remove any `*/` and trim any trailing whitespace.
        if (todoText.endsWith('*/')) {
          todoText = todoText.substring(0, todoText.length - 2).trimRight();
          end = offset + todoText.length;
        }

        // Replace out whitespace/comment markers to unwrap multiple lines.
        // Do not reset length after this, as length must include all characters.
        todoText = todoText.replaceAll(_commentNewlineAndMarker, ' ');
      } else if (commentToken.type == TokenType.SINGLE_LINE_COMMENT) {
        // Append any indented lines onto the end.
        var line = commentLocation.lineNumber;
        while (nextComment != null) {
          var nextCommentLocation = lineInfo.getLocation(nextComment.offset);
          var columnOfFirstNoneMarkerOrWhitespace =
              nextCommentLocation.columnNumber +
              nextComment.lexeme.indexOf(_nonWhitespaceOrCommentMarker);

          var isContinuation =
              nextComment.type == TokenType.SINGLE_LINE_COMMENT &&
              // Don't consider Dartdocs that follow.
              !nextComment.lexeme.startsWith('///') &&
              // Only consider TODOs on the very next line.
              nextCommentLocation.lineNumber == line++ + 1 &&
              // Only consider comment tokens starting at the same column.
              nextCommentLocation.columnNumber ==
                  commentLocation.columnNumber &&
              // And indented more than the original 'todo' text.
              columnOfFirstNoneMarkerOrWhitespace == column + 1 &&
              // And not their own todos.
              !_TodoFinder(nextComment.lexeme).moveNext();
          if (!isContinuation) {
            break;
          }

          // Track the end of the continuation for the diagnostic range.
          end = nextComment.end;
          var lexemeTextOffset =
              columnOfFirstNoneMarkerOrWhitespace -
              nextCommentLocation.columnNumber;
          var continuationText = nextComment.lexeme
              .substring(lexemeTextOffset)
              .trimRight();
          todoText = '$todoText $continuationText';
          nextComment = nextComment.next;
        }
      }

      _diagnosticReporter.report(
        Todo.forKind(todoKind)
            .withArguments(message: todoText)
            .atOffset(offset: offset, length: end - offset),
      );
    }

    return nextComment;
  }
}

class _TodoFinder {
  final String s;
  // We start at 1 to allow for the char before the first find to be \s, / or *.
  int _startAt = 1;
  int? _offset;
  String? _todoText;
  String? _todoKind;

  _TodoFinder(this.s);

  int get offset => _offset!;
  String get todoKind => _todoKind!;
  String get todoText => _todoText!;

  /// This matches the two common Dart task styles
  ///
  /// * `TODO`:
  /// * `TODO`(username):
  ///
  /// As well as
  /// * `TODO`
  ///
  /// But not
  /// * `todo`
  /// * `TODOS`
  ///
  /// It also supports wrapped TODOs where the next line is indented by a space:
  ///
  ///   /**
  ///    * `TODO`(username): This line is
  ///    *  wrapped onto the next line
  ///    */
  bool moveNext() {
    // We stop 3 before so we can check the next 3 chars without checking
    // lengths.
    var end = s.length - 3;
    for (int i = _startAt; i < end; i++) {
      int char = s.codeUnitAt(i);
      if (char >= $A && char <= $Z) {
        if (char == $T &&
            s.codeUnitAt(i + 1) == $O &&
            s.codeUnitAt(i + 2) == $D &&
            s.codeUnitAt(i + 3) == $O) {
          /// Found `TODO`
          if (_check(i, i + 4)) return true;
        } else if (char == $H &&
            s.codeUnitAt(i + 1) == $A &&
            s.codeUnitAt(i + 2) == $C &&
            s.codeUnitAt(i + 3) == $K) {
          /// Found `HACK`
          if (_check(i, i + 4)) return true;
        } else if (char == $F &&
            s.length > i + 4 &&
            s.codeUnitAt(i + 1) == $I &&
            s.codeUnitAt(i + 2) == $X &&
            s.codeUnitAt(i + 3) == $M &&
            s.codeUnitAt(i + 4) == $E) {
          /// Found `FIXME`
          if (_check(i, i + 5)) return true;
        } else if (char == $U &&
            s.length > i + 5 &&
            s.codeUnitAt(i + 1) == $N &&
            s.codeUnitAt(i + 2) == $D &&
            s.codeUnitAt(i + 3) == $O &&
            s.codeUnitAt(i + 4) == $N &&
            s.codeUnitAt(i + 5) == $E) {
          /// Found `UNDONE`
          if (_check(i, i + 6)) return true;
        }
      }
    }

    return false;
  }

  bool _check(int from, int to) {
    int charBefore = s.codeUnitAt(from - 1);
    if (charBefore != $SPACE &&
        charBefore != $TAB &&
        charBefore != $LF &&
        charBefore != $CR &&
        charBefore != $STAR &&
        charBefore != $SLASH) {
      // Doesn't start with \s, / or *.
      return false;
    }
    if (s.length == to) {
      // Line ends with this.
      _match(from, to, to);
      return true;
    }

    int charAfter = s.codeUnitAt(to);
    // Not allowed to match [A-Za-z0-9_].
    if (charAfter >= $0 && charAfter <= $9) return false;
    if (charAfter >= $a && charAfter <= $z) return false;
    if (charAfter >= $A && charAfter <= $Z) return false;
    if (charAfter == $_) return false;

    int scanFrom = to + 1;
    while (true) {
      int? foundLinebreakAt;
      for (int i = scanFrom; i < s.length; i++) {
        int char = s.codeUnitAt(i);
        if (char == $CR || char == $LF) {
          foundLinebreakAt = i;
          break;
        }
      }

      if (foundLinebreakAt == null) {
        // No line breaks - we match until the end.
        _match(from, to, s.length);
        return true;
      }

      // Possibly match the next line too.
      int includeUntil = foundLinebreakAt;
      int nextLineAt = foundLinebreakAt;
      if (s.codeUnitAt(nextLineAt) == $CR && s.length > nextLineAt + 1) {
        // Allow \n after \r.
        if (s.codeUnitAt(nextLineAt + 1) == $LF) {
          nextLineAt++;
        }
      }

      int i = nextLineAt + 1;
      while (i < s.length) {
        int char = s.codeUnitAt(i);
        if (char != $SPACE && char != $TAB && char != $LF && char != $CR) {
          break;
        }
        i++;
      }
      if (!(s.length > i + 2 &&
          s.codeUnitAt(i) == $STAR &&
          s.codeUnitAt(i + 1) == $SPACE &&
          s.codeUnitAt(i + 2) == $SPACE)) {
        // This line isn't some number of whitespace, then a * then 2 spaces.
        // We don't include it.
        _match(from, to, includeUntil);
        return true;
      }
      // Include this line too.
      scanFrom = i + 3;
    }
  }

  void _match(int from, int kindTo, int finalTo) {
    _offset = from;
    _todoText = s.substring(from, finalTo);
    _todoKind = s.substring(from, kindTo);
    _startAt = finalTo;
  }
}
