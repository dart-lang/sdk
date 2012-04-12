// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.parser.DartScanner.Location;

import java.util.List;
import java.util.Map;
import java.util.Set;

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

  private static class TerminalAnnotationsCache {
    private static Map<String, Class<?>> classes;
    private static Map<String, List<Token>> methods;

    private static void init(StackTraceElement[] stackTrace) {
      if (classes == null) {
        classes = Maps.newHashMap();
        methods = Maps.newHashMap();
      }

      for (StackTraceElement frame : stackTrace) {
        Class<?> thisClass = classes.get(frame.getClassName());
        if (thisClass == null) {
          try {
            thisClass = Class.forName(frame.getClassName());

            for (java.lang.reflect.Method method : thisClass
                .getDeclaredMethods()) {
              List<Token> tokens = methods.get(method.getName());
              if (tokens == null) {
                tokens = Lists.newArrayList();
                methods.put(thisClass.getName() + "." + method.getName(), tokens);
              }
              // look for annotations
              Terminals terminalsAnnotation = method
                  .getAnnotation(Terminals.class);
              if (terminalsAnnotation != null) {
                for (Token token : terminalsAnnotation.tokens()) {
                  tokens.add(token);
                }
              }
            }
          } catch (ClassNotFoundException e) {
            // ignored
          }
          classes.put(frame.getClassName(), null);
        }
      }
    }

    public static Set<Token> terminalsForStack(StackTraceElement[] stackTrace) {
      Set<Token> results = Sets.newHashSet();
      for (StackTraceElement frame: stackTrace) {
        List<Token> found = methods.get(frame.getClassName() + "." + frame.getMethodName());
        if (found !=  null) {
          results.addAll(found);
        }
      }
      return results;
    }
  }

  /**
   * Uses reflection to walk up the stack and look for @Terminals method
   * annotations. It gathers up the tokens in these annotations and returns them
   * to the caller. This is intended for use in parser recovery, so that we
   * don't accidentally consume a token that could be used to complete a
   * non-terminal higher up in the stack.
   */
  protected Set<Token> collectTerminalAnnotations() {
    StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
    // Get methods for every class and associated Terminals annotations & stick them in a hash
    TerminalAnnotationsCache.init(stackTrace);
    // Create the set of terminals to return
    return TerminalAnnotationsCache.terminalsForStack(stackTrace);
  }

  protected boolean expect(Token expectedToken) {
    if (!optional(expectedToken)) {

      /*
       * Save the current token, then advance to make sure that we have the
       * right position.
       */
      Token actualToken = peek(0);

      Set<Token> possibleTerminals = collectTerminalAnnotations();

      ctx.begin();
      ctx.advance();
      reportUnexpectedToken(position(), expectedToken, actualToken);
      // Don't consume tokens someone else could use to cleanly terminate the
      // statement.
      if (possibleTerminals.contains(actualToken)) {
        ctx.rollback();
        return false;
      }
      ctx.done(null);

      // Recover from the middle of string interpolation
      if (actualToken.equals(Token.STRING_EMBED_EXP_START)
          || actualToken.equals(Token.STRING_EMBED_EXP_END)) {
        while (!EOS()) {
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
    return (peek(n) == Token.IDENTIFIER)
        && keyword.equals(getPeekTokenValue(n));
  }

  protected DartScanner.Position position() {
    DartScanner.Location tokenLocation = ctx.getTokenLocation();
    return tokenLocation != null ? tokenLocation.getBegin()
        : new DartScanner.Position(0, 1, 1);
  }

  /**
   * Report a syntax error, unless an error has already been reported at the
   * given or a later position.
   */
  protected void reportError(DartScanner.Position position,
                             ErrorCode errorCode, Object... arguments) {
    DartScanner.Location location = ctx.getTokenLocation();
    if (location.getBegin().getPos() <= lastErrorPosition) {
      return;
    }
    DartCompilationError dartError = new DartCompilationError(ctx.getSource(),
        location, errorCode, arguments);
    lastErrorPosition = position.getPos();
    ctx.error(dartError);
  }

  /**
   * Even though you pass a 'Position' to {@link #reportError} above, it only
   * uses that to prevent logging more than one error at that position. This
   * method actually uses the passed position to create the error event.
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

  protected void reportUnexpectedToken(DartScanner.Position position,
                                       Token expected, Token actual) {
    if (expected == Token.EOS) {
      reportError(position, ParserErrorCode.EXPECTED_EOS, actual);
    } else if (expected == Token.IDENTIFIER) {
      reportError(position, ParserErrorCode.INVALID_IDENTIFIER, actual);
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
