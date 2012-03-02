// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The cached lookup-table to associate doc comments with spans. The outer map
 * is from filenames to doc comments in that file. The inner map maps from the
 * token positions to doc comments. Each position is the starting offset of the
 * next non-comment token *following* the doc comment. For example, the position
 * for this comment would be the position of the "class" token below.
 */
class CommentMap {
  /**
   * Maps from (filename, pos) to doc comment preceding the token at that
   * position.
   */
  Map<String, Map<int, String>> _comments;

  /** Doc comments before #library() directives. */
  Map<String, String> _libraryComments;

  CommentMap()
    : _comments = <Map<int, String>>{},
      _libraryComments = <String>{};

  /** Finds the doc comment preceding the given source span, if there is one. */
  String find(SourceSpan span) {
    if (span == null) return null;

    _ensureFileParsed(span.file);
    final comment = _comments[span.file.filename][span.start];
    if (comment == null) return '';
    return comment;
  }

  /**
   * Finds the doc comment associated with the `#library` directive for the
   * given file.
   */
  String findLibrary(SourceFile file) {
    _ensureFileParsed(file);
    final comment = _libraryComments[file.filename];
    if (comment == null) return '';
    return comment;
  }

  _ensureFileParsed(SourceFile file) {
    _comments.putIfAbsent(file.filename, () => _parseComments(file));
  }

  _parseComments(SourceFile file) {
    final comments = new Map<int, String>();

    final tokenizer = new Tokenizer(file, false);
    var lastComment = null;

    while (true) {
      final token = tokenizer.next();
      if (token.kind == TokenKind.END_OF_FILE) break;

      if (token.kind == TokenKind.COMMENT) {
        final text = token.text;
        if (text.startsWith('/**')) {
          // Remember that we've encountered a doc comment.
          lastComment = stripComment(token.text);
        } else if (text.startsWith('///')) {
          var line = text.substring(3);
          // Allow a leading space.
          if (line.startsWith(' ')) line = line.substring(1);
          if (lastComment == null) {
            lastComment = line;
          } else {
            lastComment = '$lastComment$line';
          }
        }
      } else if (token.kind == TokenKind.WHITESPACE) {
        // Ignore whitespace tokens.
      } else if (token.kind == TokenKind.HASH) {
        // Look for #library() to find the library comment.
        final next = tokenizer.next();
        if ((lastComment != null) && (next.kind == TokenKind.LIBRARY)) {
          _libraryComments[file.filename] = lastComment;
          lastComment = null;
        }
      } else {
        if (lastComment != null) {
          // We haven't attached the last doc comment to something yet, so stick
          // it to this token.
          comments[token.start] = lastComment;
          lastComment = null;
        }
      }
    }

    return comments;
  }

  /**
   * Pulls the raw text out of a doc comment (i.e. removes the comment
   * characters).
   */
  stripComment(String comment) {
    StringBuffer buf = new StringBuffer();

    for (var line in comment.split('\n')) {
      line = line.trim();
      if (line.startsWith('/**')) line = line.substring(3);
      if (line.endsWith('*/')) line = line.substring(0, line.length - 2);
      line = line.trim();
      if (line.startsWith('* ')) {
        line = line.substring(2);
      } else if (line.startsWith('*')) {
        line = line.substring(1);
      }

      buf.add(line);
      buf.add('\n');
    }

    return buf.toString();
  }
}
