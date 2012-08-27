// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.common.HasSourceInfo;

/**
 * This class exists to enforce constraints on begin calls so code
 * completion works.
 * <p>
 * In particular, it prevents {@link #begin()} from being called directly,
 * ensuring that callers must use appropriate {@code beginFoo} methods.
 * <p>
 * These hooks serve two purposes:
 * <ol>
 * <li>remember start positions to set source location information on AST
 * nodes
 * <li>provide an event mechanism that is useful for an IDE operating on code
 * being edited - for example, for error recovery or code completion
 * </ol>
 * <p>
 * Every call to {@code beginFoo} must be balanced with exactly one call
 * to either {@link #rollback()} or {@link #done(Object)}.  Between those
 * calls, there may be an arbitrary number of calls to
 * {@link #doneWithoutConsuming(Object)} to set AST node positions based on
 * the current position on the stack.
 */
public abstract class CompletionHooksParserBase extends AbstractParser {

  /*
   * Guards the parser from infinite loops and recursion.
   * THIS CLASS IS FOR DEBUG/INTERNAL USE ONLY.
   * TODO (fabiomfv) - remove before release.
   */
  private class TerminationGuard {

    /*
     * Loosely, determines the maximum number of non-terminals 'visited' without
     * advancing on input. It does not need to be a precise number, just to have
     * an upper bound on the 'space' the parser can consume before declaring
     * it is not making progress.
     */
    private static final int THRESHOLD = 1000;

    private int maxPositionRange = Integer.MIN_VALUE;
    private int minPositionRange = Integer.MAX_VALUE;
    private int threshold = THRESHOLD;

    /*
     * Guard against parser termination bugs. Called from begin().
     * If the parser does not consume tokens it is an indication that it is not
     * making progress. Look at the stack in the exception for hints of
     * productions at fault. Called from begin()
     */
    public boolean assertProgress() {
      int currentPosition = position();
      if (currentPosition > maxPositionRange) {
        minPositionRange = maxPositionRange;
        maxPositionRange = currentPosition;
        threshold = THRESHOLD;
      } else if (currentPosition < minPositionRange) {
        minPositionRange = currentPosition;
        threshold = THRESHOLD;
      }
      if (threshold-- <= 0) {
        StringBuilder sb = new StringBuilder();
        sb.append("Parser failed to make progress after many tries. File a " +
          "bug and attach this callstack and error output.\n");
        sb.append("Scanner State: ");
        sb.append(ctx.toString());
        sb.append("\n");
        sb.append("Input range [");
        sb.append(minPositionRange);
        sb.append(",");
        sb.append(maxPositionRange);
        sb.append("]\n");
        throw new AssertionError(sb.toString());
      }
      return true;
    }
  }

  /**
   * Guards against termination bugs. For debugging purposes only.
   * See {@link TerminationGuard} for details.
   */
  private TerminationGuard guard = new TerminationGuard();

  /**
   * Set the context the parser will use.
   *
   * @param ctx the {@link ParserContext} to use
   */
  public CompletionHooksParserBase(ParserContext ctx) {
    super(ctx);
  }

  protected void beginArgumentDefinitionTest() {
    begin();
  }

  protected void beginArrayLiteral() {
    begin();
  }

  protected void beginBinaryExpression() {
    begin();
  }

  protected void beginBlock() {
    begin();
  }

  protected void beginBreakStatement() {
    begin();
  }

  protected void beginCatchClause() {
    begin();
  }

  protected void beginCatchParameter() {
    begin();
  }

  protected void beginClassBody() {
    begin();
  }

  protected void beginClassMember() {
    begin();
  }

  protected void beginCompilationUnit() {
    begin();
  }

  protected void beginConditionalExpression() {
    begin();
  }

  protected void beginConstExpression() {
    begin();
  }

  protected void beginConstructor() {
    begin();
  }

  protected void beginConstructorNamePart() {
    begin();
  }

  protected void beginContinueStatement() {
    begin();
  }

  protected void beginDoStatement() {
    begin();
  }

  protected void beginEmptyStatement() {
    begin();
  }

  protected void beginEntryPoint() {
    begin();
  }

  protected void beginExpression() {
    begin();
  }

  protected void beginExpressionList() {
    begin();
  }

  protected void beginExpressionStatement() {
    begin();
  }

  protected void beginFieldInitializerOrRedirectedConstructor() {
    begin();
  }

  protected void beginFinalDeclaration() {
    begin();
  }

  protected void beginForInitialization() {
    begin();
  }

  protected void beginFormalParameter() {
    begin();
  }

  protected void beginFormalParameterList() {
    begin();
  }

  protected void beginForStatement() {
    begin();
  }

  protected void beginFunctionDeclaration() {
    begin();
  }

  protected void beginFunctionLiteral() {
    begin();
  }

  protected void beginFunctionStatementBody() {
    begin();
  }

  protected void beginFunctionTypeInterface() {
    begin();
  }

  protected void beginIdentifier() {
    begin();
  }

  protected void beginIfStatement() {
    begin();
  }

  protected void beginImportDirective() {
    begin();
  }

  protected void beginInitializer() {
    begin();
  }

  protected void beginTypeExpression() {
    begin();
  }

  protected void beginLabel() {
    begin();
  }

  protected void beginLibraryDirective() {
    begin();
  }

  protected void beginLiteral() {
    begin();
  }

  protected void beginMapLiteral() {
    begin();
  }

  protected void beginMapLiteralEntry() {
    begin();
  }

  protected void beginMetadata() {
    begin();
  }

  protected void beginMethodName() {
    begin();
  }

  protected void beginNativeBody() {
    begin();
  }

  protected void beginNativeDirective() {
    begin();
  }

  protected void beginNewExpression() {
    begin();
  }

  protected void beginOperatorName() {
    begin();
  }

  protected void beginParameter() {
    begin();
  }

  protected void beginParameterName() {
    begin();
  }

  protected void beginParenthesizedExpression() {
    begin();
  }

  protected void beginPartDirective() {
    begin();
  }

  protected void beginPartOfDirective() {
    begin();
  }

  protected void beginPostfixExpression() {
    begin();
  }

  protected void beginQualifiedIdentifier() {
    begin();
  }

  protected void beginReturnStatement() {
    begin();
  }

  protected void beginReturnType() {
    begin();
  }

  protected void beginSelectorExpression() {
    begin();
  }

  protected void beginSourceDirective() {
    begin();
  }

  protected void beginSpreadExpression() {
    begin();
  }

  protected void beginStringInterpolation() {
    begin();
  }

  protected void beginStringSegment() {
    begin();
  }

  protected void beginSuperExpression() {
    begin();
  }

  protected void beginSuperInitializer() {
    begin();
  }

  protected void beginSwitchMember() {
    begin();
  }

  protected void beginSwitchStatement() {
    begin();
  }

  protected void beginThisExpression() {
    begin();
  }

  protected void beginThrowStatement() {
    begin();
  }

  protected void beginTopLevelElement() {
    begin();
  }

  protected void beginTryStatement() {
    begin();
  }

  protected void beginTypeAnnotation() {
    begin();
  }

  protected void beginTypeArguments() {
    begin();
  }

  protected void beginTypeFunctionOrVariable() {
    begin();
  }

  protected void beginTypeParameter() {
    begin();
  }

  protected void beginUnaryExpression() {
    begin();
  }

  protected void beginVarDeclaration() {
    begin();
  }

  protected void beginVariableDeclaration() {
    begin();
  }

  protected void beginWhileStatement() {
    begin();
  }

  /**
   * Terminates a grammatical structure, saving the source location in the
   * supplied AST node.
   *
   * @param <T> type of the AST node
   * @param result the AST node to return, if any - if it implements
   *     {@link HasSourceInfo}, the source location is set based on the
   *     current position and the start of this grammatical structure
   * @return the supplied AST node (may be null)
   */
  protected <T> T done(T result) {
    return ctx.done(result);
  }

  /**
   * Saves the current source location in the supplied AST node, used for
   * subcomponents of the AST. This may only be called within an active
   * {@link #begin()} call, which must still be terminated with either
   * {@link #done(Object)} or {@link #rollback()}.
   *
   * @param <T> type of the AST node
   * @param result the AST node to return - if it implements
   *    {@link HasSourceInfo}, the source location is set based on the
   *    current position and the start of this grammatical structure
   * @return the supplied AST node
   */
  protected <T> T doneWithoutConsuming(T result) {
    return ctx.doneWithoutConsuming(result);
  }

  /**
   * Terminates an attempt to parse a grammatical structure, rolling back to the
   * state as of the previous {@link #begin()} call and removing the saved
   * state.
   */
  protected void rollback() {
    ctx.rollback();
  }

  /**
   * This should only be called when the parser is looking ahead to decide how
   * to parse something, and this will always be rolled back without any other {@link #begin()}
   * statements being called.
   */
  protected void startLookahead() {
    begin();
  }

  /**
   * Begin a grammatical structure, saving the current location to later set in
   * an AST node. This may be followed by zero or more
   * {@link #doneWithoutConsuming(Object)} calls, and is terminated by exactly
   * one {@link #done(Object)} or {@link #rollback()} call.
   */
  private void begin() {
    assert guard.assertProgress();
    ctx.begin();
  }
}
