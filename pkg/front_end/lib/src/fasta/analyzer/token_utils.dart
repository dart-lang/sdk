// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.token_utils;

import 'package:front_end/src/fasta/scanner/token.dart' show
    Token;

import 'package:front_end/src/fasta/scanner/token_constants.dart';

import 'package:analyzer/dart/ast/token.dart' as analyzer show
    Token;

import 'package:analyzer/dart/ast/token.dart' show
    TokenType;

import 'package:analyzer/src/dart/ast/token.dart' as analyzer show
    StringToken;

import '../errors.dart' show
    internalError;

analyzer.Token toAnalyzerToken(Token token) {
  if (token == null) return null;
  switch (token.kind) {
    case STRING_TOKEN:
      return new analyzer.StringToken(
          TokenType.STRING, token.value, token.charOffset);

    case IDENTIFIER_TOKEN:
      return new analyzer.StringToken(
          TokenType.IDENTIFIER, token.value, token.charOffset);

    case INT_TOKEN:
      return new analyzer.StringToken(
          TokenType.INT, token.value, token.charOffset);

    default:
      return new analyzer.Token(getTokenType(token), token.charOffset);
  }
}

TokenType getTokenType(Token token) {
  switch (token.kind) {
    case EOF_TOKEN: return TokenType.EOF;
    case DOUBLE_TOKEN: return TokenType.DOUBLE;
    case HEXADECIMAL_TOKEN: return TokenType.HEXADECIMAL;
    case IDENTIFIER_TOKEN: return TokenType.IDENTIFIER;
    case INT_TOKEN: return TokenType.INT;
    case KEYWORD_TOKEN: return TokenType.KEYWORD;
    // case MULTI_LINE_COMMENT_TOKEN: return TokenType.MULTI_LINE_COMMENT;
    // case SCRIPT_TAG_TOKEN: return TokenType.SCRIPT_TAG;
    // case SINGLE_LINE_COMMENT_TOKEN: return TokenType.SINGLE_LINE_COMMENT;
    case STRING_TOKEN: return TokenType.STRING;
    case AMPERSAND_TOKEN: return TokenType.AMPERSAND;
    case AMPERSAND_AMPERSAND_TOKEN: return TokenType.AMPERSAND_AMPERSAND;
    // case AMPERSAND_AMPERSAND_EQ_TOKEN:
    //   return TokenType.AMPERSAND_AMPERSAND_EQ;
    case AMPERSAND_EQ_TOKEN: return TokenType.AMPERSAND_EQ;
    case AT_TOKEN: return TokenType.AT;
    case BANG_TOKEN: return TokenType.BANG;
    case BANG_EQ_TOKEN: return TokenType.BANG_EQ;
    case BAR_TOKEN: return TokenType.BAR;
    case BAR_BAR_TOKEN: return TokenType.BAR_BAR;
    // case BAR_BAR_EQ_TOKEN: return TokenType.BAR_BAR_EQ;
    case BAR_EQ_TOKEN: return TokenType.BAR_EQ;
    case COLON_TOKEN: return TokenType.COLON;
    case COMMA_TOKEN: return TokenType.COMMA;
    case CARET_TOKEN: return TokenType.CARET;
    case CARET_EQ_TOKEN: return TokenType.CARET_EQ;
    case CLOSE_CURLY_BRACKET_TOKEN: return TokenType.CLOSE_CURLY_BRACKET;
    case CLOSE_PAREN_TOKEN: return TokenType.CLOSE_PAREN;
    case CLOSE_SQUARE_BRACKET_TOKEN: return TokenType.CLOSE_SQUARE_BRACKET;
    case EQ_TOKEN: return TokenType.EQ;
    case EQ_EQ_TOKEN: return TokenType.EQ_EQ;
    case FUNCTION_TOKEN: return TokenType.FUNCTION;
    case GT_TOKEN: return TokenType.GT;
    case GT_EQ_TOKEN: return TokenType.GT_EQ;
    case GT_GT_TOKEN: return TokenType.GT_GT;
    case GT_GT_EQ_TOKEN: return TokenType.GT_GT_EQ;
    case HASH_TOKEN: return TokenType.HASH;
    case INDEX_TOKEN: return TokenType.INDEX;
    case INDEX_EQ_TOKEN: return TokenType.INDEX_EQ;
    // case IS_TOKEN: return TokenType.IS;
    case LT_TOKEN: return TokenType.LT;
    case LT_EQ_TOKEN: return TokenType.LT_EQ;
    case LT_LT_TOKEN: return TokenType.LT_LT;
    case LT_LT_EQ_TOKEN: return TokenType.LT_LT_EQ;
    case MINUS_TOKEN: return TokenType.MINUS;
    case MINUS_EQ_TOKEN: return TokenType.MINUS_EQ;
    case MINUS_MINUS_TOKEN: return TokenType.MINUS_MINUS;
    case OPEN_CURLY_BRACKET_TOKEN: return TokenType.OPEN_CURLY_BRACKET;
    case OPEN_PAREN_TOKEN: return TokenType.OPEN_PAREN;
    case OPEN_SQUARE_BRACKET_TOKEN: return TokenType.OPEN_SQUARE_BRACKET;
    case PERCENT_TOKEN: return TokenType.PERCENT;
    case PERCENT_EQ_TOKEN: return TokenType.PERCENT_EQ;
    case PERIOD_TOKEN: return TokenType.PERIOD;
    case PERIOD_PERIOD_TOKEN: return TokenType.PERIOD_PERIOD;
    case PLUS_TOKEN: return TokenType.PLUS;
    case PLUS_EQ_TOKEN: return TokenType.PLUS_EQ;
    case PLUS_PLUS_TOKEN: return TokenType.PLUS_PLUS;
    case QUESTION_TOKEN: return TokenType.QUESTION;
    case QUESTION_PERIOD_TOKEN: return TokenType.QUESTION_PERIOD;
    case QUESTION_QUESTION_TOKEN: return TokenType.QUESTION_QUESTION;
    case QUESTION_QUESTION_EQ_TOKEN: return TokenType.QUESTION_QUESTION_EQ;
    case SEMICOLON_TOKEN: return TokenType.SEMICOLON;
    case SLASH_TOKEN: return TokenType.SLASH;
    case SLASH_EQ_TOKEN: return TokenType.SLASH_EQ;
    case STAR_TOKEN: return TokenType.STAR;
    case STAR_EQ_TOKEN: return TokenType.STAR_EQ;
    // case STRING_INTERPOLATION_EXPRESSION_TOKEN:
    //   return TokenType.STRING_INTERPOLATION_EXPRESSION;
    case STRING_INTERPOLATION_IDENTIFIER_TOKEN:
      return TokenType.STRING_INTERPOLATION_IDENTIFIER;
    case TILDE_TOKEN: return TokenType.TILDE;
    case TILDE_SLASH_TOKEN: return TokenType.TILDE_SLASH;
    case TILDE_SLASH_EQ_TOKEN: return TokenType.TILDE_SLASH_EQ;
    case BACKPING_TOKEN: return TokenType.BACKPING;
    case BACKSLASH_TOKEN: return TokenType.BACKSLASH;
    case PERIOD_PERIOD_PERIOD_TOKEN: return TokenType.PERIOD_PERIOD_PERIOD;
    // case GENERIC_METHOD_TYPE_LIST_TOKEN:
    //   return TokenType.GENERIC_METHOD_TYPE_LIST;
    // case GENERIC_METHOD_TYPE_ASSIGN_TOKEN:
    //   return TokenType.GENERIC_METHOD_TYPE_ASSIGN;
    default:
      return internalError("Unhandled token ${token.info}");
  }
}
