// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.ast.token;

import 'package:front_end/src/scanner/token.dart';

export 'package:front_end/src/scanner/token.dart'
    show
        BeginToken,
        BeginTokenWithComment,
        CommentToken,
        DocumentationCommentToken,
        KeywordToken,
        KeywordTokenWithComment,
        SimpleToken,
        StringToken,
        StringTokenWithComment,
        TokenClass,
        TokenWithComment;

/**
 * A token whose value is independent of it's type.
 */
class SyntheticStringToken extends StringToken {
  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  SyntheticStringToken(TokenType type, String value, int offset)
      : super(type, value, offset);

  @override
  bool get isSynthetic => true;
}
