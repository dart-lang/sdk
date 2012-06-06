// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.parser.DartScanner.Location;

/**
 * Abstracts parser and permits marking lexical ranges via event driven methods. Certain IDEs need
 * more location information than just the source line/column/position of an AST node, such as the
 * complete set of lexemes that encompass a given node, e.g. function foo() {}} =>
 * [FUNCTION, SPACE, IDENTIFIER, LPAREN, RPAREN, SPACE, LBRACE, RBRACE].This interface allows a
 * parser to mark the begin and end of each non-terminal AST node in a lexical stream.
 */
public interface ParserContext {

  /**
   * Consume the current token, and advance to the next one, skipping whitespace and comment
   * tokens.
   */
  void advance();

  /**
   * Called at the beginning of a non-terminal rule. The purpose for this method
   * is to record any information that might be needed at the end of the rule
   * (such as the current source position) as well as any state necessary to be
   * able to roll back to the state just prior to the invocation of this method.
   *
   * @see #done(T)
   * @see #doneWithoutConsuming(T)
   * @see #rollback()
   */
  void begin();

  /**
   * Called at the end of a non-terminal rule to mark the end of the non-terminal
   * node. This method consumes any information saved by the {@link #begin()}
   * method, updating the node with any saved information (such as its position
   * in the source) as appropriate.
   *
   * @param result the non-terminal node being ended
   *
   * @return the non-terminal node that should be included in the AST structure,
   *         which is typically the same as the argument
   *
   * @see #begin()
   * @see #doneWithoutConsuming(T)
   * @see #rollback()
   */
  <T> T done(T result);

  /**
   * Called at the end of a non-terminal rule to mark the end of the non-terminal
   * node. Unlike {@link #done()}, this method does not consume any information
   * saved by the {@link #begin()} method, but does update the node with any
   * saved information (such as its position in the source) as appropriate.
   *
   * @param result the non-terminal node being ended
   *
   * @return the non-terminal node that should be included in the AST structure,
   *         which is typically the same as the argument
   *
   * @see #begin()
   * @see #doneWithoutConsuming(T)
   * @see #rollback()
   */
  <T> T doneWithoutConsuming(T result);

  /**
   * Log a parse error for the current lexical range.
   * @param dartError helpful error messaging describing what the expected tokens were
   */
  void error(DartCompilationError dartError);

  /**
   * Called by the {@link DartParser} before parsing given {@link DartSource}.
   */
  void unitAboutToCompile(DartSource source, boolean diet);

  /**
   * Return the current token.
   */
  Token getCurrentToken();

  /**
   * Return Source if present.
   */
  Source getSource();

  /**
   * Return location information for the current token.
   */
  DartScanner.Location getTokenLocation();

  /**
   * Return the string value, if any, of the current token (e.g. IDENTIFIER)
   */
  String getTokenString();

  /**
   * Peek ahead without advancing the lexer.
   */
  Token peek(int steps);

  /**
   * Return location information for the token that is 'n' tokens ahead of the current token.
   */
  Location peekTokenLocation(int n);

  /**
   * Set the next token to be returned.
   */
  void replaceNextToken(Token token);

  /**
   * Rolls back the current token to the position when {@link begin()} was
   * called.
   *
   * @see #begin()
   * @see #done(T)
   * @see #doneWithoutConsuming(T)
   */
  void rollback();

  /**
   * Peek ahead, for the value, without advancing the lexer.
   */
  String peekTokenString(int steps);

}
