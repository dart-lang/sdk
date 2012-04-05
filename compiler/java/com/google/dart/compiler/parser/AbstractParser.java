// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.parser.DartScanner.Location;

/**
 * Abstract base class for sharing common utility methods between implementation
 * classes, like {@link DartParser}.
 */
abstract class AbstractParser {

  protected final ParserContext ctx;
  private int lastErrorPosition = Integer.MIN_VALUE;

  protected AbstractParser(ParserContext ctx) {
    this.ctx = ctx;
  }

  protected boolean EOS() {
    return match(Token.EOS) || match(Token.ILLEGAL);
  }

  protected boolean expect(Token expectedToken) {
    if (!optional(expectedToken)) {
      /*
       * Save the current token, then advance to make sure that we have the
       * right position.
       */
      Token actualToken = peek(0);
      ctx.advance();
      reportUnexpectedToken(position(), expectedToken, actualToken);
      // Recover from the middle of string interpolation
      if (actualToken.equals(Token.STRING_EMBED_EXP_START) ||
          actualToken.equals(Token.STRING_EMBED_EXP_END)) {
        while(!EOS()) {
          Token nextToken = next();
          if (nextToken.equals(Token.STRING_LAST_SEGMENT)) {
            break;
          }
          next();
        }
      }
      return false;
    }
    return true;
  }

  protected String getPeekTokenValue(int n) {
    assert (n >= 0);
    String value = ctx.peekTokenString(n);
    return value;
  }

  protected boolean match(Token token) {
    return peek(0) == token;
  }

  protected Token next() {
    ctx.advance();
    return ctx.getCurrentToken();
  }

  protected boolean optionalPseudoKeyword(String keyword) {
    if (!peekPseudoKeyword(0, keyword)) {
      return false;
    }
    next();
    return true;
  }

  protected boolean optional(Token token) {
    if (peek(0) != token) {
      return false;
    }
    next();
    return true;
  }

  protected Token peek(int n) {
    return ctx.peek(n);
  }

  protected boolean peekPseudoKeyword(int n, String keyword) {
    return (peek(n) == Token.IDENTIFIER) && keyword.equals(getPeekTokenValue(n));
  }

  protected DartScanner.Position position() {
    DartScanner.Location tokenLocation = ctx.getTokenLocation();
    return tokenLocation != null ? tokenLocation.getBegin() : new DartScanner.Position(0, 1, 1);
  }

  /**
   * Report a syntax error, unless an error has already been reported at the given or a later
   * position.
   */
  protected void reportError(DartScanner.Position position, ErrorCode errorCode,
      Object... arguments) {
    DartScanner.Location location = ctx.getTokenLocation();
    if (location.getBegin().getPos() <= lastErrorPosition) {
      return;
    }
    DartCompilationError dartError = new DartCompilationError(ctx.getSource(), location, errorCode,
        arguments);
    lastErrorPosition = position.getPos();
    ctx.error(dartError);
  }
  
  /**
   * Even though you pass a 'Position' to {@link #reportError} above, it only uses that to 
   * prevent logging more than one error at that position.  This method actually uses the passed
   * position to create the error event.
   */
  protected void reportErrorAtPosition(DartScanner.Position startPosition,
                                       DartScanner.Position endPosition,
                                       ErrorCode errorCode, Object... arguments) {
    DartScanner.Location location = ctx.getTokenLocation();
    if (location.getBegin().getPos() <= lastErrorPosition) {
      return;
    }
    DartCompilationError dartError = new DartCompilationError(ctx.getSource(),
        new Location(startPosition, endPosition), errorCode, arguments);
    ctx.error(dartError);
  }

  protected void reportUnexpectedToken(DartScanner.Position position, Token expected,
      Token actual) {
    if (expected == Token.EOS) {
      reportError(position, ParserErrorCode.EXPECTED_EOS, actual);
    } else if (expected == null) {
      reportError(position, ParserErrorCode.UNEXPECTED_TOKEN, actual);
    } else {
      reportError(position, ParserErrorCode.EXPECTED_TOKEN, actual, expected);
    }
  }

  protected void setPeek(int n, Token token) {
    assert n == 0; // so far, n is always zero
    ctx.replaceNextToken(token);
  }

  protected boolean consume(Token token) {
    boolean result = (peek(0) == token);
    assert (result);
    next();
    return result;
  }
}
