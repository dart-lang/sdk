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
    : _comments = <String, Map<int, String>>{},
      _libraryComments = <String, String>{};

  /**
   * Finds the doc comment preceding the given source span, if there is one.
   *
   * If a comment is returned, it is guaranteed to be non-empty.
   */
  String find(Location span) {
    if (span == null) return null;

    _ensureFileParsed(span.source);
    String comment = _comments[span.source.uri.toString()][span.start];
    assert(comment == null || !comment.trim().isEmpty());
    return comment;
  }

  /**
   * Finds the doc comment associated with the `#library` directive for the
   * given file.
   *
   * If a comment is returned, it is guaranteed to be non-empty.
   */
  String findLibrary(Source source) {
    _ensureFileParsed(source);
    String comment = _libraryComments[source.uri.toString()];
    assert(comment == null || !comment.trim().isEmpty());
    return comment;
  }

  _ensureFileParsed(Source source) {
    _comments.putIfAbsent(source.uri.toString(), () =>
        _parseComments(source));
  }

  _parseComments(Source source) {
    final comments = new Map<int, String>();

    final scanner = new dart2js.StringScanner(source.text, true);
    var lastComment = null;

    var token = scanner.tokenize();
    while (token.kind != dart2js.EOF_TOKEN) {
      if (token.kind == dart2js.COMMENT_TOKEN) {
        final text = token.slowToString();
        if (text.startsWith('/**')) {
          // Remember that we've encountered a doc comment.
          lastComment = stripComment(token.slowToString());
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
      } else if (token.kind == dart2js.HASH_TOKEN) {
        // Look for #library() to find the library comment.
        final next = token.next;
        if ((lastComment != null) && (next.stringValue == 'library')) {
          _libraryComments[source.uri.toString()] = lastComment;
          lastComment = null;
        }
      } else if (lastComment != null) {
        if (!lastComment.trim().isEmpty()) {
          // We haven't attached the last doc comment to something yet, so stick
          // it to this token.
          comments[token.charOffset] = lastComment;
        }
        lastComment = null;
      }
      token = token.next;
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
