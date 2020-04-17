// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';

/// Determine if the given token is a nullability hint, and if so, return the
/// type of nullability hint it is.
NullabilityComment classifyComment(Token token) {
  if (token is CommentToken) {
    if (token.lexeme == '/*!*/') return NullabilityComment.bang;
    if (token.lexeme == '/*?*/') return NullabilityComment.question;
  }
  return NullabilityComment.none;
}

/// Determine if the given [token] is followed by a nullability hint, and if so,
/// return the type of nullability hint it is followed by.
NullabilityComment getPostfixHint(Token token) {
  var commentToken = token.next.precedingComments;
  var commentType = classifyComment(commentToken);
  return commentType;
}

PrefixHintComment getPrefixHint(Token token) {
  Token commentToken = token.precedingComments;
  if (commentToken != null) {
    while (true) {
      var nextComment = commentToken.next;
      if (nextComment == null) break;
      commentToken = nextComment;
    }
    var lexeme = commentToken.lexeme;
    if (lexeme.startsWith('/*') && lexeme.endsWith('*/') && lexeme.length > 4) {
      var commentText = lexeme.substring(2, lexeme.length - 2).trim();
      if (commentText == 'late') return PrefixHintComment.late_;
    }
  }
  return PrefixHintComment.none;
}

/// Types of comments that can influence nullability
enum NullabilityComment {
  /// The comment `/*!*/`, which indicates that the type should not have a `?`
  /// appended.
  bang,

  /// The comment `/*?*/`, which indicates that the type should have a `?`
  /// appended.
  question,

  /// No special comment.
  none,
}

/// Types of comments that can appear before a token
enum PrefixHintComment {
  /// The comment `/*late*/`, which indicates that the variable declaration
  /// should be late.
  late_,

  /// No special comment
  none,
}
