// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.HasSourceInfoSetter;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.parser.DartScanner.State;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Stack;

/**
 * A ParserContext backed by a DartScanner.
 */
class DartScannerParserContext implements ParserContext {
  private DartScanner scanner;
  private Deque<DartScanner.State> stateStack = new ArrayDeque<DartScanner.State>();
  private Deque<Integer> positionStack = new ArrayDeque<Integer>();
  private Source source;
  private DartCompilerListener listener;
  private final CompilerMetrics compilerMetrics;

  public DartScannerParserContext(Source source, String sourceCode,
      DartCompilerListener listener) {
    this(source, sourceCode, listener, null);
  }

  public DartScannerParserContext(Source source, String sourceCode,
      DartCompilerListener listener, CompilerMetrics compilerMetrics) {
    this.source = source;
    this.scanner = createScanner(sourceCode, source, listener);
    this.listener = listener;
    this.compilerMetrics = compilerMetrics;
  }

  @Override
  public void begin() {
    stateStack.push(scanner.getState());
    positionStack.push(getBeginLocation(0));
  }

  private int getBeginLocation(int n) {
    DartScanner.Location tokenLocation = scanner.peekTokenLocation(n);
    return tokenLocation != null ? tokenLocation.getBegin() : 0;
  }

  private int getEndLocation() {
    DartScanner.Location tokenLocation = scanner.getTokenLocation();
    return tokenLocation != null ? tokenLocation.getEnd() : 0;
  }

  @Override
  public <T> T done(T result) {
    DartScanner.State oldState = stateStack.pop();
    DartScanner.State newState = stateStack.peek();

    // If there is more state left, push the newer token changes to them.
    if (newState != null) {
      if (oldState.rollbackTokens != null) {
        if (newState.rollbackTokens != null) {
          oldState.rollbackTokens.addAll(newState.rollbackTokens);
        }
        newState.rollbackTokens = oldState.rollbackTokens;
      }
    }

    setSourcePosition(result, positionStack.pop());

    if (result instanceof DartUnit) {
      if (compilerMetrics != null) {
        compilerMetrics.unitParsed(scanner.getCharCount(), scanner.getNonCommentCharCount(),
            0, 0);
      }
    }

    // want next begin() call to seek to the next token and skip whitespace after previous done()
    return result;
  }

  /**
   * Set the source position on a result, if it is a {@link HasSourceInfo}.
   *
   * @param <T> result type
   * @param result
   * @param startPos
   */
  private <T> void setSourcePosition(T result, int startPos) {
    if (result instanceof HasSourceInfoSetter) {
      HasSourceInfoSetter hasSourceInfoSetter = (HasSourceInfoSetter) result;
      int start = startPos;
      int end = getEndLocation();
      if (start != -1 && end < start) {
        // handle 0-length tokens, including where there is trailing whitespace
        end = start;
      }
      hasSourceInfoSetter.setSourceInfo(new SourceInfo(source, start, end - start));
    }
  }

  @Override
  public <T> T doneWithoutConsuming(T result) {
    // do not throw away state
    setSourcePosition(result, positionStack.peek());

    // want next begin() call to seek to the next token and skip whitespace after previous done()
    return result;
  }

  @Override
  public void error(DartCompilationError dartError) {
    listener.onError(dartError);
  }
  
  @Override
  public void unitAboutToCompile(DartSource source, boolean diet) {
    listener.unitAboutToCompile(source, diet);
  }

  @Override
  public void advance() {
    scanner.next();
  }

  @Override
  public Token getCurrentToken() {
    return scanner.getToken();
  }

  @Override
  public Token peek(int steps) {
    return scanner.peek(steps);
  }

  @Override
  public void rollback() {
    // undo changes made to scanner tokens
    DartScanner.State oldState = stateStack.pop();
    scanner.restoreState(oldState);

    // Restore the replaced tokens to their state.
    if (oldState.rollbackTokens != null) {
      while (!oldState.rollbackTokens.isEmpty()) {
        State.RollbackToken token = oldState.rollbackTokens.pop();
        scanner.setAbsolutePeek(token.absoluteOffset, token.replacedToken);
      }
    }
    positionStack.pop();
  }

  @Override
  public String getTokenString() {
    return scanner.getTokenValue();
  }

  @Override
  public Location peekTokenLocation(int n) {
    return scanner.peekTokenLocation(n);
  }

  @Override
  public String peekTokenString(int steps) {
    return scanner.peekTokenValue(steps);
  }

  @Override
  public void replaceNextToken(Token token) {
    DartScanner.State state = stateStack.peek();
    DartScanner.State.RollbackToken oldToken
      = new DartScanner.State.RollbackToken(scanner.getOffset() + 1, scanner.peek(0));
    if (state.rollbackTokens == null) {
      state.rollbackTokens = new Stack<State.RollbackToken>();
    }
    state.rollbackTokens.push(oldToken);
    scanner.setPeek(0, token);
  }

  @Override
  public DartScanner.Location getTokenLocation() {
    return scanner.getTokenLocation();
  }

  protected DartScanner createScanner(String sourceCode, Source source, DartCompilerListener listener) {
    return new DartScanner(sourceCode, 0, source, listener);
  }

  @Override
  public Source getSource() {
    return source;
  }
}
