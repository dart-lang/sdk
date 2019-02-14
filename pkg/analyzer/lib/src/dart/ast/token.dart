// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';

export 'package:front_end/src/scanner/token.dart'
    show
        BeginToken,
        CommentToken,
        DocumentationCommentToken,
        KeywordToken,
        SimpleToken,
        StringToken,
        SyntheticBeginToken,
        SyntheticKeywordToken,
        SyntheticStringToken,
        SyntheticToken,
        TokenClass;

/**
 * Return the binary operator that is invoked by the given compound assignment
 * [operator]. Throw [StateError] if the assignment [operator] does not
 * correspond to a binary operator.
 */
TokenType operatorFromCompoundAssignment(TokenType operator) {
  if (operator == TokenType.AMPERSAND_EQ) {
    return TokenType.AMPERSAND;
  } else if (operator == TokenType.BAR_EQ) {
    return TokenType.BAR;
  } else if (operator == TokenType.CARET_EQ) {
    return TokenType.CARET;
  } else if (operator == TokenType.GT_GT_EQ) {
    return TokenType.GT_GT;
  } else if (operator == TokenType.LT_LT_EQ) {
    return TokenType.LT_LT;
  } else if (operator == TokenType.MINUS_EQ) {
    return TokenType.MINUS;
  } else if (operator == TokenType.PERCENT_EQ) {
    return TokenType.PERCENT;
  } else if (operator == TokenType.PLUS_EQ) {
    return TokenType.PLUS;
  } else if (operator == TokenType.SLASH_EQ) {
    return TokenType.SLASH;
  } else if (operator == TokenType.STAR_EQ) {
    return TokenType.STAR;
  } else if (operator == TokenType.TILDE_SLASH_EQ) {
    return TokenType.TILDE_SLASH;
  } else {
    throw StateError('Unknown assignment operator: $operator');
  }
}
