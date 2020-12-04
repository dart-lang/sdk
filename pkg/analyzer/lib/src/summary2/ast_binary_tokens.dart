// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/summary2/tokens_context.dart';
import 'package:analyzer/src/summary2/unlinked_token_type.dart';

class Tokens {
  static final ABSTRACT = TokenFactory.tokenFromKeyword(Keyword.ABSTRACT);
  static final ARROW = TokenFactory.tokenFromType(TokenType.FUNCTION);
  static final AS = TokenFactory.tokenFromKeyword(Keyword.AS);
  static final ASSERT = TokenFactory.tokenFromKeyword(Keyword.ASSERT);
  static final AT = TokenFactory.tokenFromType(TokenType.AT);
  static final ASYNC = TokenFactory.tokenFromKeyword(Keyword.ASYNC);
  static final AWAIT = TokenFactory.tokenFromKeyword(Keyword.AWAIT);
  static final BANG = TokenFactory.tokenFromType(TokenType.BANG);
  static final BREAK = TokenFactory.tokenFromKeyword(Keyword.BREAK);
  static final CASE = TokenFactory.tokenFromKeyword(Keyword.CASE);
  static final CATCH = TokenFactory.tokenFromKeyword(Keyword.CATCH);
  static final CLASS = TokenFactory.tokenFromKeyword(Keyword.CLASS);
  static final CLOSE_CURLY_BRACKET =
      TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET);
  static final CLOSE_PAREN = TokenFactory.tokenFromType(TokenType.CLOSE_PAREN);
  static final CLOSE_SQUARE_BRACKET =
      TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET);
  static final COLON = TokenFactory.tokenFromType(TokenType.COLON);
  static final COMMA = TokenFactory.tokenFromType(TokenType.COMMA);
  static final CONST = TokenFactory.tokenFromKeyword(Keyword.CONST);
  static final CONTINUE = TokenFactory.tokenFromKeyword(Keyword.CONTINUE);
  static final COVARIANT = TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
  static final DEFERRED = TokenFactory.tokenFromKeyword(Keyword.DEFERRED);
  static final ELSE = TokenFactory.tokenFromKeyword(Keyword.ELSE);
  static final EXTERNAL = TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
  static final FACTORY = TokenFactory.tokenFromKeyword(Keyword.FACTORY);
  static final DEFAULT = TokenFactory.tokenFromKeyword(Keyword.DEFAULT);
  static final DO = TokenFactory.tokenFromKeyword(Keyword.DO);
  static final ENUM = TokenFactory.tokenFromKeyword(Keyword.ENUM);
  static final EQ = TokenFactory.tokenFromType(TokenType.EQ);
  static final EXPORT = TokenFactory.tokenFromKeyword(Keyword.EXPORT);
  static final EXTENDS = TokenFactory.tokenFromKeyword(Keyword.EXTENDS);
  static final EXTENSION = TokenFactory.tokenFromKeyword(Keyword.EXTENSION);
  static final FINAL = TokenFactory.tokenFromKeyword(Keyword.FINAL);
  static final FINALLY = TokenFactory.tokenFromKeyword(Keyword.FINALLY);
  static final FOR = TokenFactory.tokenFromKeyword(Keyword.FOR);
  static final FUNCTION = TokenFactory.tokenFromKeyword(Keyword.FUNCTION);
  static final GET = TokenFactory.tokenFromKeyword(Keyword.GET);
  static final GT = TokenFactory.tokenFromType(TokenType.GT);
  static final HASH = TokenFactory.tokenFromType(TokenType.HASH);
  static final HIDE = TokenFactory.tokenFromKeyword(Keyword.HIDE);
  static final IF = TokenFactory.tokenFromKeyword(Keyword.IF);
  static final IMPLEMENTS = TokenFactory.tokenFromKeyword(Keyword.IMPORT);
  static final IMPORT = TokenFactory.tokenFromKeyword(Keyword.IMPLEMENTS);
  static final IN = TokenFactory.tokenFromKeyword(Keyword.IN);
  static final IS = TokenFactory.tokenFromKeyword(Keyword.IS);
  static final LATE = TokenFactory.tokenFromKeyword(Keyword.LATE);
  static final LIBRARY = TokenFactory.tokenFromKeyword(Keyword.LIBRARY);
  static final LT = TokenFactory.tokenFromType(TokenType.LT);
  static final MIXIN = TokenFactory.tokenFromKeyword(Keyword.MIXIN);
  static final NATIVE = TokenFactory.tokenFromKeyword(Keyword.NATIVE);
  static final NEW = TokenFactory.tokenFromKeyword(Keyword.NEW);
  static final NULL = TokenFactory.tokenFromKeyword(Keyword.NULL);
  static final OF = TokenFactory.tokenFromKeyword(Keyword.OF);
  static final ON = TokenFactory.tokenFromKeyword(Keyword.ON);
  static final OPEN_CURLY_BRACKET =
      TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET);
  static final OPEN_PAREN = TokenFactory.tokenFromType(TokenType.OPEN_PAREN);
  static final OPEN_SQUARE_BRACKET =
      TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET);
  static final OPERATOR = TokenFactory.tokenFromKeyword(Keyword.OPERATOR);
  static final PART = TokenFactory.tokenFromKeyword(Keyword.PART);
  static final PERIOD = TokenFactory.tokenFromType(TokenType.PERIOD);
  static final PERIOD_PERIOD =
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD);
  static final PERIOD_PERIOD_PERIOD =
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD);
  static final PERIOD_PERIOD_PERIOD_QUESTION =
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD_QUESTION);
  static final QUESTION = TokenFactory.tokenFromType(TokenType.QUESTION);
  static final REQUIRED = TokenFactory.tokenFromKeyword(Keyword.REQUIRED);
  static final RETHROW = TokenFactory.tokenFromKeyword(Keyword.RETHROW);
  static final RETURN = TokenFactory.tokenFromKeyword(Keyword.RETURN);
  static final SEMICOLON = TokenFactory.tokenFromType(TokenType.SEMICOLON);
  static final SET = TokenFactory.tokenFromKeyword(Keyword.SET);
  static final SHOW = TokenFactory.tokenFromKeyword(Keyword.SHOW);
  static final STAR = TokenFactory.tokenFromType(TokenType.STAR);
  static final STATIC = TokenFactory.tokenFromKeyword(Keyword.STATIC);
  static final STRING_INTERPOLATION_EXPRESSION =
      TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION);
  static final SUPER = TokenFactory.tokenFromKeyword(Keyword.SUPER);
  static final SWITCH = TokenFactory.tokenFromKeyword(Keyword.SWITCH);
  static final SYNC = TokenFactory.tokenFromKeyword(Keyword.SYNC);
  static final THIS = TokenFactory.tokenFromKeyword(Keyword.THIS);
  static final THROW = TokenFactory.tokenFromKeyword(Keyword.THROW);
  static final TRY = TokenFactory.tokenFromKeyword(Keyword.TRY);
  static final TYPEDEF = TokenFactory.tokenFromKeyword(Keyword.TYPEDEF);
  static final VAR = TokenFactory.tokenFromKeyword(Keyword.VAR);
  static final WITH = TokenFactory.tokenFromKeyword(Keyword.WITH);
  static final WHILE = TokenFactory.tokenFromKeyword(Keyword.WHILE);
  static final YIELD = TokenFactory.tokenFromKeyword(Keyword.YIELD);

  static Token choose(bool if1, Token then1, bool if2, Token then2,
      [bool if3, Token then3]) {
    if (if1) return then1;
    if (if2) return then2;
    if (if2 == true) return then3;
    return null;
  }

  static Token fromType(UnlinkedTokenType type) {
    return TokenFactory.tokenFromType(
      TokensContext.binaryToAstTokenType(type),
    );
  }
}
