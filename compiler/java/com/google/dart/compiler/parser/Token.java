// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import java.util.HashMap;
import java.util.Map;

/**
 * Dart tokens and associated data.
 *
 * Note: Token ordinals matter for some accessors, so don't change the order of these without
 * knowing what you're doing.
 */
public enum Token {
  /* End-of-stream. */
  EOS(null, 0),

  /* Punctuators. */
  LPAREN("(", 0),
  RPAREN(")", 0),
  LBRACK("[", 0),
  RBRACK("]", 0),
  LBRACE("{", 0),
  RBRACE("}", 0),
  COLON(":", 0),
  SEMICOLON(";", 0),
  PERIOD(".", 0),
  ELLIPSIS("...", 0),
  COMMA(",", 0),
  CONDITIONAL("?", 3),
  ARROW("=>", 0),

  /* Assignment operators. */
  ASSIGN("=", 2),
  ASSIGN_BIT_OR("|=", 2),
  ASSIGN_BIT_XOR("^=", 2),
  ASSIGN_BIT_AND("&=", 2),
  ASSIGN_SHL("<<=", 2),
  ASSIGN_SAR(">>=", 2),
  ASSIGN_ADD("+=", 2),
  ASSIGN_SUB("-=", 2),
  ASSIGN_MUL("*=", 2),
  ASSIGN_DIV("/=", 2),
  ASSIGN_MOD("%=", 2),
  ASSIGN_TRUNC("~/=", 2),

  /* Binary operators sorted by precedence. */
  OR("||", 4),
  AND("&&", 5),
  BIT_OR("|", 6),
  BIT_XOR("^", 7),
  BIT_AND("&", 8),
  SHL("<<", 11),
  SAR(">>", 11),
  ADD("+", 12),
  SUB("-", 12),
  MUL("*", 13),
  DIV("/", 13),
  TRUNC("~/", 13),
  MOD("%", 13),

  /* Compare operators sorted by precedence. */
  EQ("==", 9),
  NE("!=", 9),
  EQ_STRICT("===", 9),
  NE_STRICT("!==", 9),
  LT("<", 10),
  GT(">", 10),
  LTE("<=", 10),
  GTE(">=", 10),
  AS("as", 10),
  IS("is", 10),

  /* Unary operators. */
  NOT("!", 0),
  BIT_NOT("~", 0),

  /* Count operators (also unary). */
  INC("++", 0),
  DEC("--", 0),

  /* [] operator overloading. */
  INDEX("[]", 0),
  ASSIGN_INDEX("[]=", 0),

  /* Keywords. */
  BREAK("break", 0),
  CASE("case", 0),
  CATCH("catch", 0),
  CLASS("class",0),
  CONST("const", 0),
  CONTINUE("continue", 0),
  DEFAULT("default", 0),
  DO("do", 0),
  ELSE("else", 0),
  FINAL("final", 0),
  FINALLY("finally", 0),
  FOR("for", 0),
  IF("if", 0),
  IN("in", 0),
  NEW("new", 0),
  RETURN("return", 0),
  SUPER("super", 0),
  SWITCH("switch", 0),
  THIS("this", 0),
  THROW("throw", 0),
  TRY("try", 0),
  VAR("var", 0),
  VOID("void", 0),
  WHILE("while", 0),

  /* Literals. */
  NULL_LITERAL("null", 0),
  TRUE_LITERAL("true", 0),
  FALSE_LITERAL("false", 0),
  HEX_LITERAL(null, 0),
  INTEGER_LITERAL(null, 0),
  DOUBLE_LITERAL(null, 0),
  STRING(null, 0),

  /** String interpolation and string templates. */
  STRING_SEGMENT(null, 0),
  STRING_LAST_SEGMENT(null, 0),
  // STRING_EMBED_EXP_START does not have a unique string representation in the code:
  //   "$id" yields the token STRING_EMBED_EXP_START after the '$', and similarly
  //   "${id}" yield the same token for '${'.
  STRING_EMBED_EXP_START(null, 0),
  STRING_EMBED_EXP_END(null, 0),

  // Note: STRING_EMBED_EXP_END uses the same symbol as RBRACE, but it is
  // recognized by the scanner when closing embedded expressions in string
  // interpolation and string templates.

  /* Directives */
  LIBRARY("#library", 0),
  IMPORT("#import", 0),
  SOURCE("#source", 0),
  RESOURCE("#resource", 0),
  NATIVE("#native", 0),

  /* Identifiers (not keywords). */
  IDENTIFIER(null, 0),
  WHITESPACE(null, 0),

  /* Pseudo tokens. */
  // If you add another pseudo token, don't forget to update the predicate below.
  ILLEGAL(null, 0),
  COMMENT(null, 0),

  /**
   * Non-token to be used by tools where a value outside the range of anything
   * returned by the scanner is needed. This is the equivalent of -1 in a C
   * tokenizer.
   *
   * This token is never returned by the scanner. It must have an ordinal
   * value outside the range of all tokens returned by the scanner.
   */
  NON_TOKEN(null, 0);

  private static Map<String, Token> tokens = new HashMap<String, Token>();

  static {
    for (Token tok : Token.values()) {
      if (tok.syntax_ != null) {
        tokens.put(tok.syntax_, tok);
      }
    }
  }

  /**
   * Given a string finds the corresponding token. Pseudo tokens (EOS, ILLEGAL and COMMENT) are
   * ignored.
   */
  public static Token lookup(String syntax) {
    Token token = tokens.get(syntax);
    if (token == null) {
      return IDENTIFIER;
    }
    return token;
  }

  private final String syntax_;
  private final int precedence_;

  /**
   * The <CODE>syntax</CODE> parameter serves two purposes: 1. map tokens that
   * look like identifiers ("null", "true", etc.) to their correct token.
   * 2. Find the string-representation of operators.</BR>
   * When it is <CODE>null</CODE> then the token either doesn't have a unique
   * representation, or it is a pseudo token (which doesn't physically appear
   * in the source).
   */
  Token(String syntax, int precedence) {
    syntax_ = syntax;
    precedence_ = precedence;
  }

  public Token asBinaryOperator() {
    int ordinal = ordinal() - ASSIGN_BIT_OR.ordinal() + BIT_OR.ordinal();
    return values()[ordinal];
  }

  public int getPrecedence() {
    return precedence_;
  }

  public String getSyntax() {
    return syntax_;
  }

  public boolean isEqualityOperator() {
    int ordinal = ordinal();
    return EQ.ordinal() <= ordinal && ordinal <= NE_STRICT.ordinal();
  }

  public boolean isRelationalOperator() {
    int ordinal = ordinal();
    return LT.ordinal() <= ordinal && ordinal <= GTE.ordinal();
  }

  public boolean isAssignmentOperator() {
    int ordinal = ordinal();
    return ASSIGN.ordinal() <= ordinal && ordinal <= ASSIGN_TRUNC.ordinal();
  }

  public boolean isBinaryOperator() {
    int ordinal = ordinal();
    return (ASSIGN.ordinal() <= ordinal && ordinal <= IS.ordinal())
        || (ordinal == COMMA.ordinal());
  }

  public boolean isCountOperator() {
    int ordinal = ordinal();
    return INC.ordinal() <= ordinal && ordinal <= DEC.ordinal();
  }

  public boolean isUnaryOperator() {
    int ordinal = ordinal();
    return NOT.ordinal() <= ordinal && ordinal <= DEC.ordinal();
  }

  public boolean isUserDefinableOperator() {
    int ordinal = ordinal();
    return ((BIT_OR.ordinal() <= ordinal && ordinal <= GTE.ordinal())
        || this == BIT_NOT || this == INDEX || this == ASSIGN_INDEX)
        && this != NE && this != EQ_STRICT && this != NE_STRICT;
  }

  @Override
  public String toString() {
    String result = getSyntax();
    if (result == null) {
      return name();
    }
    return result;
  }
}
