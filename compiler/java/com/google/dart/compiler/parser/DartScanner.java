// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.metrics.DartEventType;
import com.google.dart.compiler.metrics.Tracer;
import com.google.dart.compiler.metrics.Tracer.TraceEvent;

import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

/**
 * The Dart scanner. Should normally be used only by {@link DartParser}.
 */
public class DartScanner {

  /**
   * Represents a position in a source file, including absolute character position,
   * line, and column.
   */
  public static class Position {
    private int pos;
    private int line;
    private int col;

    public Position(int pos, int line, int col) {
      this.pos = pos;
      this.line = line;
      this.col = col;
    }

    public Position copy() {
      return new Position(pos, line, col);
    }

    public int getPos() {
      return pos;
    }

    public int getLine() {
      return line;
    }

    public int getCol() {
      return col;
    }

    public void advance(boolean isNewline) {
      ++pos;
      if (isNewline) {
        col = 1;
        ++line;
      } else {
        ++col;
      }
    }

    /**
     * @return the {@link Position} which is advanced on the given number of columns, on the same
     *         line.
     */
    public Position getAdvancedColumns(int cols) {
      return new Position(pos + cols, line, col + cols);
    }

    @Override
    public String toString() {
      return line + "," + col + "@" + pos;
    }
  }

  /**
   * Represents a span of characters in a source file.
   */
  public static class Location {
    public static final Location NONE = null;
    private Position begin, end;

    public Location(Position begin, Position end) {
      this.begin = begin;
      this.end = end;
    }

    public Location(Position begin) {
      this.begin = this.end = begin;
    }

    public Position getBegin() {
      return begin;
    }

    public Position getEnd() {
      return end;
    }

    @Override
    public String toString() {
      return begin.toString() + "::" + end.toString();
    }
  }

  public static class State {
    State(int baseOffset) {
      this.baseOffset = baseOffset;
    }

    static class RollbackToken {
      public final int absoluteOffset;
      final Token replacedToken;

      public RollbackToken(int tokenOffset, Token token) {
        absoluteOffset = tokenOffset;
        replacedToken = token;
      }
    }

    /* Stack of tokens present before setPeek() */
    Stack<RollbackToken> rollbackTokens = null;
    final int baseOffset;

    @Override
    public String toString() {
      return "ofs=" + baseOffset;
    }
  }

  /**
   * Stores the entire state for the scanner.
   */
  protected static class InternalState {
    enum Mode {
      DEFAULT,

      IN_STRING,

      /**
       * Inside a string, scanning a string-interpolation expression.
       * Ex: "${foo}".
       */
      IN_STRING_EMBEDDED_EXPRESSION,

      /**
       * Inside a string, scanning a string-interpolation identifier.
       * <pre>
       * Ex: "$foo bc".
       *        ^
       * </pre>
       */
      IN_STRING_EMBEDDED_EXPRESSION_IDENTIFIER,

      /**
       * Inside a string, just after having scanned a string-interpolation identifier.
       * <pre>
       * Ex: "$foo bc".
       *          ^
       * </pre>
       */
      IN_STRING_EMBEDDED_EXPRESSION_END
    }

    /**
     * Maintains the state of scanning strings, including interpolated
     * expressions/identifiers, nested braces for terminating an interpolated
     * expression, the quote character used to start/end the string, and whether
     * it is a multiline string.
     */
    public static class StringState {
      private int bracesCount;
      private Mode mode;
      private final boolean multiLine;
      private final int quote;

      /**
       * Push a new mode on state stack.  If the new mode is
       * {@link Mode#IN_STRING_EMBEDDED_EXPRESSION}, mark that we have seen an
       * opening brace.
       *
       * @param mode
       * @param quote
       * @param multiLine
       */
      public StringState(Mode mode, int quote, boolean multiLine) {
        this.bracesCount = mode == Mode.IN_STRING_EMBEDDED_EXPRESSION ? 1 : 0;
        this.mode = mode;
        this.quote = quote;
        this.multiLine = multiLine;
      }

      /**
       * Mark that we have seen an opening brace.
       */
      public void openBrace() {
        if (mode == Mode.IN_STRING_EMBEDDED_EXPRESSION) {
          bracesCount++;
        }
      }

      /**
       * Mark that we have seen a closing brace.
       *
       * @return true if the current mode is now complete and should be popped
       * off the stack
       */
      public boolean closeBrace() {
        if (mode == Mode.IN_STRING_EMBEDDED_EXPRESSION) {
          return --bracesCount == 0;
        }
        return false;
      }

      /**
       * @return the string scanning mode.
       */
      public Mode getMode() {
        return mode;
      }

      /**
       * @return the codepoint of the quote character used to bound the current
       * string.
       */
      public int getQuote() {
        return quote;
      }

      /**
       * @return true if the current string is a multi-line string.
       */
      public boolean isMultiLine() {
        return multiLine;
      }

      /**
       * @param mode the string scanning mode.
       */
      public void setMode(Mode mode) {
        this.mode = mode;
      }

      @Override
      public String toString() {
        StringBuilder buf = new StringBuilder();
        buf.append(mode).append("/quote=").appendCodePoint(quote);
        if (multiLine) {
          buf.append("/multiline");
        }
        return buf.toString();
      }
    }

    private int lookahead[] = new int[NUM_LOOKAHEAD];
    private Position lookaheadPos[] = new Position[NUM_LOOKAHEAD];
    private Position nextLookaheadPos;
    private ArrayList<TokenData> tokens;
    private TokenData lastToken;

    // Current offset in the token list
    int currentOffset;

    // The following fields store data used for parsing string interpolation.
    // The scanner splits the interpolated string in segments, alternating
    // strings and expressions so that the parser can construct the embedded
    // expressions as it goes. The following information is used to ensure that
    // the string is closed with matching quotes, and to deal with parsing
    // ambiguity of "}" (which closes both embedded expressions and braces
    // within embedded expressions).

    /** The string scanning state stack. */
    private List<StringState> stringStateStack = new ArrayList<StringState>();

    public InternalState() {
      currentOffset = 0;
    }

    @Override
    public String toString() {
      StringBuilder ret = new StringBuilder();

      ret.append("currentOffset(");
      ret.append(currentOffset);
      ret.append(")");
      if ( currentOffset > -1 ) {
        TokenData tok = tokens.get(currentOffset);
        ret.append(" = [");
        ret.append(tok.token);
        if (tok.value != null) {
          ret.append(" (" + tok.value + ")");
        }
        ret.append("], ");
      }

      ret.append("[");
      for (int i = 0; i < tokens.size(); i++) {
        TokenData tok = tokens.get(i);
        ret.append(tok.token);
        if (tok.value != null) {
          ret.append(" (" + tok.value + ")");
        }
        if (i < tokens.size() - 1) {
          ret.append(", ");
        }
      }
      ret.append("]");
      if (getMode() != InternalState.Mode.DEFAULT) {
        ret.append("(within string starting with ");
        ret.appendCodePoint(getQuote());
        if (isMultiLine()) {
          ret.appendCodePoint(getQuote());
          ret.appendCodePoint(getQuote());
        }
        ret.append(')');
      }
      return ret.toString();
    }

    /**
     * @return the current scanning mode
     */
    protected Mode getMode() {
      return stringStateStack.isEmpty() ? Mode.DEFAULT : getCurrentState().getMode();
    }

    /**
     * Mark that we have seen an open brace.
     */
    protected void openBrace() {
      if (!stringStateStack.isEmpty()) {
        getCurrentState().openBrace();
      }
    }

    /**
     * Mark that we have seen a close brace.
     *
     * @return true if the current mode is now complete and should be popped
     */
    protected boolean closeBrace() {
      if (!stringStateStack.isEmpty()) {
        return getCurrentState().closeBrace();
      }
      return false;
    }

    /**
     * Pop the current mode.
     */
    protected void popMode() {
      if (!stringStateStack.isEmpty()) {
        stringStateStack.remove(stringStateStack.size() - 1);
      }
    }

    /**
     * @param mode the mode to push
     */
    protected void pushMode(Mode mode, int quote, boolean multiLine) {
      stringStateStack.add(new StringState(mode, quote, multiLine));
    }

    /**
     * @param mode the mode to push
     */
    protected void replaceMode(Mode mode) {
      getCurrentState().setMode(mode);
    }

    /**
     * Remove all modes, returning to the default state.
     */
    public void resetModes() {
      stringStateStack.clear();
    }

    /**
     * @return the quote
     */
    private int getQuote() {
      return getCurrentState().getQuote();
    }

    /**
     * @return the current string scanning state
     */
    private StringState getCurrentState() {
      assert !stringStateStack.isEmpty() : "called with empty state stack";
      return stringStateStack.get(stringStateStack.size() - 1);
    }

    /**
     * @return the multiLine
     */
    private boolean isMultiLine() {
      return getCurrentState().isMultiLine();
    }
  }

  private static class TokenData {
    Token token;
    Location location;
    String value;

    @Override
    public String toString() {
      String str = token.toString();
      return (value != null) ? str + "(" + value + ")" : str;
    }
  }

  private static final int NUM_LOOKAHEAD = 2;

  private static boolean isDecimalDigit(int c) {
    return c >= '0' && c <= '9';
  }

  private static boolean isHexDigit(int c) {
    return isDecimalDigit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
  }

  private static boolean isIdentifierPart(int c) {
    return isIdentifierStart(c) || isDecimalDigit(c);
  }

  private static boolean isIdentifierStart(int c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c == '_') || (c == '$');
  }

  private static boolean isLineTerminator(int c) {
    return c == '\r' || c == '\n';
  }

  private static boolean isWhiteSpace(int c) {
    return c == ' ' || c == '\t';
  }

  private int commentLineCount;
  private int commentCharCount;
  private int lastCommentStart;
  private int lastCommentStop;
  private String source;
  private InternalState internalState;

  public DartScanner(String source) {
    this(source, 0);
  }

  public DartScanner(String source, int start) {
    final TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.SCANNER) : null;
    try {
      this.source = source;
      internalState = new InternalState();
      internalState.tokens = new ArrayList<TokenData>(source.length()/2);

      // Initialize lookahead positions.
      // TODO Determine if line & column should be relative to 0 or 'start'
      internalState.nextLookaheadPos = new Position(start, 1, 1);
      for (int i = 0; i < internalState.lookaheadPos.length; ++i) {
        internalState.lookaheadPos[i] = new Position(start, 1, 1);
      }

      // Fill all the characters in the look-ahead and all the peek
      // elements in the tokens buffer.
      for (int i = 0; i < NUM_LOOKAHEAD; i++) {
        advance();
      }

      // Scan all the tokens up front
      scanFile();
    } finally {
      Tracer.end(logEvent);
    }
  }

  /**
   * Returns the number of lines of source that were scanned, excluding the number of lines
   * consumed by comments.
   */
  public int getNonCommentLineCount() {
    return getLineCount() - commentLineCount;
  }

  /**
   * Returns the number of lines of source that were scanned.
   */
  public int getLineCount() {
    int lineCount = internalState.nextLookaheadPos.line;
    if (isEos()) {
      // At the end of the file the next line has advanced one past the end
      lineCount -= 1;
    }
    return lineCount;
  }

  /**
   * Returns the number of characters of source code that were scanned.
   */
  public int getCharCount() {
    return internalState.nextLookaheadPos.pos;
  }

  /**
   * Returns the number of characters of source code that were scanned excluding the number of
   * characters consumed by comments.
   */
  public int getNonCommentCharCount() {
    return getCharCount() - commentCharCount;
  }

  /**
   * Get the token value for one of the look-ahead tokens.
   */
  public String getPeekTokenValue(int n) {
    assert (0 <= n && (internalState.currentOffset + n + 1) < internalState.tokens.size());
    return internalState.tokens.get(internalState.currentOffset + n + 1).value;
  }

  /**
   * Gets a copy of the current scanner state. This state can be passed to {@link
   * #restoreState(State)}.
   */
  public State getState() {
//    System.out.println("get state: " + internalState.currentOffset + " hash: 0x" + Integer.toHexString(this.hashCode()));
    return new State(internalState.currentOffset);
  }

  /**
   * Gets the current offset of the scanner.
   */
  public int getOffset() {
    return internalState.currentOffset;
  }

  /**
   * Gets the current token.
   */
  public Token getToken() {
    return internalState.tokens.get(internalState.currentOffset).token;
  }

  /**
   * Gets the location of the current token.
   */
  public Location getTokenLocation() {
    return internalState.tokens.get(internalState.currentOffset).location;
  }

  public Location peekTokenLocation(int n) {
    if ((internalState.currentOffset + n + 1) < internalState.tokens.size()) {
      return internalState.tokens.get(internalState.currentOffset + n + 1).location;
    } else {
      // It is not valid to read beyond the end of the token stream, so we
      // return the Location of the EOS token.
      return internalState.tokens.get(internalState.tokens.size() - 1).location;
    }

  }

  /**
   * Get the token value or location for the current token previously returned
   * by a call to next().
   */
  public String getTokenValue() {
    return internalState.tokens.get(internalState.currentOffset).value;
  }

  public String peekTokenValue(int n) {
    if ((internalState.currentOffset + n + 1) < internalState.tokens.size()) {
      return internalState.tokens.get(internalState.currentOffset + n + 1).value;
    } else {
      // It is not valid to read beyond the end of the token stream, so we
      // return the null, the default value of an EOS token.
      return null;
    }
  }

  /**
   * Returns the next token.
   */
  public Token next() {
    // Do not advance the current offset beyond the end of the stoken stream
    if (internalState.currentOffset + 1 < internalState.tokens.size()) {
      internalState.currentOffset++;
    }
    return getToken();
  }

  /**
   * Token look-ahead - past the token returned by next().
   */
  public Token peek(int n) {
    if ((internalState.currentOffset + n + 1) < internalState.tokens.size()) {
      return internalState.tokens.get(internalState.currentOffset + n + 1).token;
    } else {
      // It is not valid to read beyond the end of the token stream, so we
      // return the EOS token
      return Token.EOS;
    }
  }

  /**
   * Sets the scanner's state, using a state object returned from {@link #getState()}.
   */
  public void restoreState(State oldState) {
//    System.out.println("restore state " + oldState.baseOffset + " hash: 0x" + Integer.toHexString(this.hashCode()));
    // reset offset
    internalState.currentOffset = oldState.baseOffset;
  }

  /**
   * Sets the token at the specified slot in the lookahead buffer.
   */
  public void setPeek(int n, Token token) {
    assert (0 <= n && (internalState.currentOffset + n + 1) < internalState.tokens.size());
    internalState.tokens.get(internalState.currentOffset + n + 1).token = token;
  }

  /**
   * Sets the token at the specified slot in the lookahead buffer.
   */
  public void setAbsolutePeek(int n, Token token) {
    assert (0 <= n && n < internalState.tokens.size());
    internalState.tokens.get(n).token = token;
  }

  @Override
  public String toString() {
    if (internalState == null) {
      return super.toString();
    }
    return internalState.toString();
  }

  /**
   * A hook into low-level scanning machinery. Use with care and only as directed.<p>
   * Record the location of a comment. Given a source string <code>source,</code>
   * the actual comment string is <code>source.substring(start - 1, stop)</code>
   * because the comment cannot be recognized until its second character is
   * scanned.<p>
   * Note: A single comment may be scanned multiple times. If the scanner has
   * to backtrack it will re-scan comments until it no longer has to backtrack.
   * Clients are responsible for filtering duplicate comment locations.<p>
   * Warning: This method may be called during initialization of the scanner in
   * the <code>DartScanner</code> constructor. Fields defined in the subclass
   * that implements this method may not have been initialized before the first
   * invocation.
   * @param start the character position of the second character in the comment
   * @param stop the character position of the final character in the comment
   * @param line the line number at <code>start</code>
   * @param col the column number at <code>start</code>
   */
  protected void recordCommentLocation(int start, int stop, int line, int col) {
  }

  private void advance() {
    for (int i = 0; i < NUM_LOOKAHEAD - 1; ++i) {
      internalState.lookahead[i] = internalState.lookahead[i + 1];
      internalState.lookaheadPos[i] = internalState.lookaheadPos[i + 1].copy();
    }
    if (internalState.nextLookaheadPos.pos < source.length()) {
      int ch = source.codePointAt(internalState.nextLookaheadPos.pos);
      internalState.lookahead[NUM_LOOKAHEAD - 1] = ch;
      internalState.lookaheadPos[NUM_LOOKAHEAD - 1] = internalState.nextLookaheadPos.copy();
      internalState.nextLookaheadPos.advance(ch == '\n');
    } else {
      // Let the last look-ahead position be past the source. This makes
      // the position information for the last token correct.
      internalState.lookahead[NUM_LOOKAHEAD - 1] = -1;
      internalState.lookaheadPos[NUM_LOOKAHEAD - 1] = new Position(source.length(),
        internalState.nextLookaheadPos.line, internalState.nextLookaheadPos.col);

      // Leave the nextLookahead position pointing to the line after the last line
      internalState.nextLookaheadPos = new Position(source.length(),
          internalState.nextLookaheadPos.line + 1, 1);
    }
  }

  /**
   * Called when comments are identified to aggregate the total number of comment lines and comment
   * characters then delegate to {@link #recordCommentLocation(int, int, int, int)}.  This provides
   * a light weight way to track how much of the code is made up of comments without having to keep
   * all comments.
   *
   * @param start the character position of the second character in the comment
   * @param stop the character position of the final character in the comment
   * @param startLine the line number at <code>start</code>
   * @param endLine the line number of the last line of the comment
   * @param col the column number at <code>start</code>
   */
  private void commentLocation(int start, int stop, int startLine, int endLine, int col) {
    if (start <= lastCommentStart && stop <= lastCommentStop) {
      return;
    }

    lastCommentStart = start;
    lastCommentStop = stop;
    commentLineCount += endLine - startLine + 1;
    commentCharCount += stop - start + 1;

    recordCommentLocation(start, stop, startLine, col);
  }

  private boolean is(int c) {
    return internalState.lookahead[0] == c;
  }

  private boolean isEos() {
    return internalState.lookahead[0] < 0;
  }

  private int lookahead(int n) {
    assert (0 <= n && n < NUM_LOOKAHEAD);
    return internalState.lookahead[n];
  }

  // Get the current source code position.
  private Position position() {
    return internalState.lookaheadPos[0];
  }

  private void scanFile() {
    // First node inserted as a dummy.
    internalState.lastToken = new TokenData();
    internalState.tokens.add(internalState.lastToken);

    while (true) {
      internalState.lastToken = new TokenData();
      Token token;
      Position begin, end;
      do {
        skipWhiteSpace();
        begin = position();
        token = scanToken();
      } while (token == Token.COMMENT);
      end = position();

      internalState.lastToken.token = token;
      internalState.lastToken.location = new Location(begin, end);
      internalState.tokens.add(internalState.lastToken);
      if (token == Token.EOS) {
//        System.out.print("tokens: ");
//        for(TokenData t : internalState.tokens) {
//          if (t != null) {
//            if (t.token != null) {
//              System.out.print(t + ", ");
//            } else {
//              System.out.print("Null, ");
//            }
//          }
//        }
//        System.out.println();
        return;
      }
    }
  }

  private Token scanIdentifier(boolean allowDollars) {
    assert (isIdentifierStart(lookahead(0)));
    Position begin = position();
    while (true) {
      int nextChar = lookahead(0);
      if (!isIdentifierPart(nextChar) || (!allowDollars && nextChar == '$')) {
        break;
      }
      advance();
    }
    int size = position().pos - begin.pos;

    // Use a substring of the source string instead of copying all the
    // characters to the token value buffer.
    String result = source.substring(begin.pos, begin.pos + size);
    internalState.lastToken.value = result;
    return Token.lookup(result);
  }

  private Token scanNumber() {
    boolean isDouble = false;
    assert (isDecimalDigit(lookahead(0)) || is('.'));
    Position begin = position();
    while (isDecimalDigit(lookahead(0)))
      advance();
    if (is('.') && isDecimalDigit(lookahead(1))) {
      isDouble = true;
      advance();  // Consume .
      while (isDecimalDigit(lookahead(0)))
        advance();
    }
    if (isE()) {
      isDouble = true;
      advance();
      if (is('+') || is('-')) {
        advance();
      }
      if (!isDecimalDigit(lookahead(0))) {
        return Token.ILLEGAL;
      }
      while (isDecimalDigit(lookahead(0)))
        advance();
    } else if (isIdentifierStart(lookahead(0))) {
      // Number literals must not be followed directly by an identifier.
      return Token.ILLEGAL;
    }
    int size = position().pos - begin.pos;
    internalState.lastToken.value = source.substring(begin.pos, begin.pos + size);
    return isDouble ? Token.DOUBLE_LITERAL : Token.INTEGER_LITERAL;
  }

  private boolean isE() {
    return is('e') || is('E');
  }

  private Token scanHexNumber() {
    assert (isDecimalDigit(lookahead(0)) && (lookahead(1) == 'x' || lookahead(1) == 'X'));
    // Skip 0x/0X.
    advance();
    advance();

    Position begin = position();
    if (!isHexDigit(lookahead(0))) {
      return Token.ILLEGAL;
    }
    advance();
    while (isHexDigit(lookahead(0))) {
      advance();
    }
    if (isIdentifierStart(lookahead(0))) {
      return Token.ILLEGAL;
    }
    internalState.lastToken.value = source.substring(begin.pos, position().pos);
    return Token.HEX_LITERAL;
  }

  private Token scanString(boolean isRaw) {
    int quote = lookahead(0);
    assert (is('\'') || is('"'));
    boolean multiLine = false;
    advance();

    // detect whether this is a multi-line string:
    if (lookahead(0) == quote && lookahead(1) == quote) {
      multiLine = true;
      advance();
      advance();
      // according to the dart guide, when multi-line strings start immediatelly
      // with a \n, the \n is not part of the string:
      if (is('\n')) {
        advance();
      }
    }
    internalState.pushMode(InternalState.Mode.IN_STRING, quote, multiLine);
    if (isRaw) {
      return scanRawString();
    } else {
      return scanWithinString(true);
    }
  }

  private Token scanRawString() {
    assert (internalState.getMode() == InternalState.Mode.IN_STRING);
    int quote = internalState.getQuote();
    boolean multiLine = internalState.isMultiLine();
    // TODO(floitsch): Do we really need a StringBuffer to accumulate the characters?
    StringBuilder tokenValueBuffer = new StringBuilder();
    while (true) {
      if (isEos()) {
        // Unterminated string (either multi-line or not).
        internalState.popMode();
        return Token.ILLEGAL;
      }
      int c = lookahead(0);
      advance();
      if (c == quote) {
        if (!multiLine) {
          // Done parsing the string literal.
          break;
        } else if (lookahead(0) == quote && lookahead(1) == quote) {
          // Done parsing the multi-line string literal.
          advance();
          advance();
          break;
        }
      } else if (c == '\n' && !multiLine) {
        advance();
        internalState.popMode();
        // unterminated (non multi-line) string
        return Token.ILLEGAL;
      }
      tokenValueBuffer.appendCodePoint(c);
    }
    internalState.lastToken.value = tokenValueBuffer.toString();
    internalState.popMode();
    return Token.STRING;
  }

  /**
   * Scan within a string watching for embedded expressions (string
   * interpolation). This function returns 4 kinds of tokens:
   * <ul>
   *   <li> {@link Token#STRING} when {@code start} is true and no embedded
   *   expressions are found (default to string literals when no interpolation
   *   was used).
   *   <li> {@link Token#STRING_SEGMENT} when the string is interrupted with an
   *   embedded expression.
   *   <li> {@link Token#STRING_EMBED_EXP_START} when an embedded expression is
   *   found right away (the lookahead is "${").
   *   <li> {@link Token#STRING_LAST_SEGMENT} when {@code start} is false and no
   *   more embedded expressions are found.
   * </ul>
   */
  private Token scanWithinString(boolean start) {
    assert (internalState.getMode() == InternalState.Mode.IN_STRING);
    int quote = internalState.getQuote();
    boolean multiLine = internalState.isMultiLine();
    StringBuffer tokenValueBuffer = new StringBuffer();
    while (true) {
      if (isEos()) {
        // Unterminated string (either multi-line or not).
        internalState.resetModes();
        return Token.EOS;
      }
      int c = lookahead(0);
      if (c == quote) {
        advance();
        if (!multiLine) {
          // Done parsing string constant.
          break;
        } else if (lookahead(0) == quote && lookahead(1) == quote) {
          // Done parsing multi-line string constant.
          advance();
          advance();
          break;
        }
      } else if (c == '\n' && !multiLine) {
        advance();
        internalState.popMode();
        // unterminated (non multi-line) string
        return Token.ILLEGAL;
      } else if (c == '\\') {
        advance();
        if (isEos()) {
          // Unterminated string (either multi-line or not).
          internalState.resetModes();
          return Token.EOS;
        }
        c = lookahead(0);
        advance();
        switch (c) {
          case '\n':
            if (!multiLine) {
              // TODO(zundel): better way to report error?
              internalState.resetModes();
              return Token.ILLEGAL;
            }
            c = '\n';
            break;
          case 'b':
            c = 0x08;
            break;
          case 'f':
            c = 0x0C;
            break;
          case 'n':
            c = '\n';
            break;
          case 'r':
            c = '\r';
            break;
          case 't':
            c = '\t';
            break;
          case 'v':
            c = 0x0B;
            break;
          case 'x':
          case 'u':
            // Parse Unicode escape sequences, which are of the form (backslash) xXX, (backslash)
            // uXXXX or (backslash) u{X*} where X is a hexadecimal digit - the delimited form must
            // be between 1 and 6 digits.
            int len = (c == 'u') ? 4 : 2;
            if (isEos()) {
              // Unterminated string (either multi-line or not).
              internalState.resetModes();
              return Token.EOS;
            }
            c = lookahead(0);
            int unicodeCodePoint = 0;
            // count of characters remaining or negative if delimited
            if (c == '{') {
              len = -1;
              advance();
              if (isEos()) {
                // Unterminated string (either multi-line or not).
                internalState.resetModes();
                return Token.EOS;
              }
              c = lookahead(0);
            }
            while (len != 0) {
              advance();
              int digit = Character.getNumericValue(c);
              if (digit < 0 || digit > 15) {
                // TODO(jat): how to handle an error?  We would prefer to give a better error
                // message about an invalid Unicode escape sequence
                return Token.ILLEGAL;
              }
              unicodeCodePoint = unicodeCodePoint * 16 + digit;
              c = lookahead(0);
              if (len-- < 0 && c == '}') {
                advance();
                break;
              }
              if (isEos()) {
                // Unterminated string (either multi-line or not).
                internalState.resetModes();
                return Token.EOS;
              }
              if (len < -6) {
                // TODO(jat): better way to indicate error
                // too many characters for a delimited character
                return Token.ILLEGAL;
              }
            }
            c = unicodeCodePoint;
            // Unicode escapes must specify a valid Unicode scalar value, and may not specify
            // UTF16 surrogates.
            if (!Character.isValidCodePoint(c) || (c < 0x10000
                && (Character.isHighSurrogate((char) c) || Character.isLowSurrogate((char) c)))) {
              // TODO(jat): better way to indicate error
              return Token.ILLEGAL;
            }
            // TODO(jat): any other checks?  We could use Character.isDefined, but then we risk
            // version skew with the JRE's Unicode data.  For now, assume anything in the Unicode
            // range besides surrogates are fine.
            break;

          default:
            // any other character following a backslash is just itself
            // see Dart guide 3.3
            break;
        }
      } else if (c == '$') {
        // TODO(sigmund): add support for named embedded expressions and
        // function embedded expressions for string templates.
        if (tokenValueBuffer.length() == 0) {
          advance();
          int nextChar = lookahead(0);
          if (nextChar == '{') {
            advance();
            internalState.pushMode(InternalState.Mode.IN_STRING_EMBEDDED_EXPRESSION, quote,
                multiLine);
          } else {
            internalState.pushMode(InternalState.Mode.IN_STRING_EMBEDDED_EXPRESSION_IDENTIFIER,
                quote, multiLine);
          }
          return Token.STRING_EMBED_EXP_START;
        } else {
          // Encountered the beginning of an embedded expression (string
          // interpolation), return the current segment, and keep the "$" for
          // the next token.
          internalState.lastToken.value = tokenValueBuffer.toString();
          return Token.STRING_SEGMENT;
        }
      } else {
        advance();
      }
      tokenValueBuffer.appendCodePoint(c);
    }

    internalState.lastToken.value = tokenValueBuffer.toString();
    internalState.popMode();
    if (start) {
      return Token.STRING;
    } else {
      return Token.STRING_LAST_SEGMENT;
    }
  }

  private Token scanToken() {
    switch (internalState.getMode()) {
      case IN_STRING:
        return scanWithinString(false);
      case IN_STRING_EMBEDDED_EXPRESSION_IDENTIFIER:
        // We are inside a string looking for an identifier. Ex: "$foo".
        internalState.replaceMode(InternalState.Mode.IN_STRING_EMBEDDED_EXPRESSION_END);
        int c = lookahead(0);
        if (isIdentifierStart(c) && c != '$') {
          boolean allowDollars = false;
          return scanIdentifier(allowDollars);
        } else {
          internalState.popMode();
          if (!isEos()) {
            internalState.lastToken.value = String.valueOf(c);
          }
          return Token.ILLEGAL;
        }
      case IN_STRING_EMBEDDED_EXPRESSION_END:
        // We scanned the identifier of a string-interpolation. New we return the
        // end-of-embedded-expression token.
        internalState.popMode();
        return Token.STRING_EMBED_EXP_END;
      default:
        // fall through
    }

    switch (lookahead(0)) {
      case '"':
      case '\'': {
        boolean isRaw = false;
        return scanString(isRaw);
      }

      case '<':
        // < <= << <<=
        advance();
        if (is('='))
          return select(Token.LTE);
        if (is('<'))
          return select('=', Token.ASSIGN_SHL, Token.SHL);
        return Token.LT;

      case '>':
        // > >= >> >>=
        advance();
        if (is('='))
          return select(Token.GTE);
        if (is('>')) {
          // >> >>=
          advance();
          if (is('='))
            return select(Token.ASSIGN_SAR);
          return Token.SAR;
        }
        return Token.GT;

      case '=':
        // = == === =>
        advance();
        if (is('>')) {
          return select(Token.ARROW);
        }
        if (is('='))
          return select('=', Token.EQ_STRICT, Token.EQ);
        return Token.ASSIGN;

      case '!':
        // ! != !==
        advance();
        if (is('='))
          return select('=', Token.NE_STRICT, Token.NE);
        return Token.NOT;

      case '+':
        // + ++ +=
        advance();
        if (is('+'))
          return select(Token.INC);
        if (is('='))
          return select(Token.ASSIGN_ADD);
        return Token.ADD;

      case '-':
        // - -- -=
        advance();
        if (is('-'))
          return select(Token.DEC);
        if (is('='))
          return select(Token.ASSIGN_SUB);
        return Token.SUB;

      case '*':
        // * *=
        return select('=', Token.ASSIGN_MUL, Token.MUL);

      case '%':
        // % %=
        return select('=', Token.ASSIGN_MOD, Token.MOD);

      case '/':
        // / // /* /=
        advance();
        if (is('/'))
          return skipSingleLineComment();
        if (is('*'))
          return skipMultiLineComment();
        if (is('='))
          return select(Token.ASSIGN_DIV);
        return Token.DIV;

      case '&':
        // & && &=
        advance();
        if (is('&'))
          return select(Token.AND);
        if (is('='))
          return select(Token.ASSIGN_BIT_AND);
        return Token.BIT_AND;

      case '|':
        // | || |=
        advance();
        if (is('|'))
          return select(Token.OR);
        if (is('='))
          return select(Token.ASSIGN_BIT_OR);
        return Token.BIT_OR;

      case '^':
        // ^ ^=
        return select('=', Token.ASSIGN_BIT_XOR, Token.BIT_XOR);

      case '.':
        // . <number>
        if (isDecimalDigit(lookahead(1))) {
          return scanNumber();
        } else {
          advance();
          if (lookahead(0) == '.' && lookahead(1) == '.') {
            advance();
            advance();
            return Token.ELLIPSIS;
          }
          return Token.PERIOD;
        }

      case ':':
        return select(Token.COLON);

      case ';':
        return select(Token.SEMICOLON);

      case ',':
        return select(Token.COMMA);

      case '(':
        return select(Token.LPAREN);

      case ')':
        return select(Token.RPAREN);

      case '[':
        advance();
        if (is(']')) {
          return select('=', Token.ASSIGN_INDEX, Token.INDEX);
        }
        return Token.LBRACK;

      case ']':
        return select(Token.RBRACK);

      case '{':
        internalState.openBrace();
        return select(Token.LBRACE);

      case '}':
        if (internalState.closeBrace()) {
          internalState.popMode();
          return select(Token.STRING_EMBED_EXP_END);
        }
        return select(Token.RBRACE);

      case '?':
        return select(Token.CONDITIONAL);

      case '~':
        // ~ ~/ ~/=
        advance();
        if (is('/')) {
          if (lookahead(1) == '=') {
            advance();
            return select(Token.ASSIGN_TRUNC);
          } else {
            return select(Token.TRUNC);
          }
        } else {
          return Token.BIT_NOT;
        }

      case '@':
        // Raw strings.
        advance();
        if (is('\'') || is('"')) {
          boolean isRaw = true;
          return scanString(isRaw);
        } else {
          return select(Token.ILLEGAL);
        }

      case '#':
        return scanDirective();

      default:
        if (isIdentifierStart(lookahead(0))) {
          boolean allowDollars = true;
          return scanIdentifier(allowDollars);
        }
        if (isDecimalDigit(lookahead(0))) {
          if (lookahead(0) == '0' && (lookahead(1) == 'x' || lookahead(1) == 'X')) {
            return scanHexNumber();
          } else {
            return scanNumber();
          }
        }
        if (isEos())
          return Token.EOS;
        return select(Token.ILLEGAL);
    }
  }

  /**
   * Scan for #library, #import, #source, and #resource directives
   */
  private Token scanDirective() {
    assert (is('#'));
    Position currPos = position();
    int start = currPos.pos;
    int line = currPos.line;
    int col = currPos.col;

    // Skip over the #! if it exists and consider it a comment
    if (start == 0) {
      if (lookahead(1) == '!') {
        while (!isEos() && !isLineTerminator(lookahead(0)))
          advance();
        int stop = internalState.lookaheadPos[0].pos;
        commentLocation(start, stop, line, internalState.lookaheadPos[0].line, col);
        return Token.COMMENT;
      }
    }

    // Directives must start at the beginning of a line
    if (start > 0 && !isLineTerminator(source.codePointBefore(start)))
      return select(Token.ILLEGAL);

    // Determine which directive is being specified
    advance();
    while (true) {
      int ch = lookahead(0);
      if (ch < 'a' || ch > 'z') {
        break;
      }
      advance();
    }
    String syntax = source.substring(start, position().pos);
    Token token = Token.lookup(syntax);
    return token == Token.IDENTIFIER ? Token.ILLEGAL : token;
  }

  private Token select(int next, Token yes, Token no) {
    advance();
    if (lookahead(0) != next)
      return no;
    advance();
    return yes;
  }

  private Token select(Token token) {
    advance();
    return token;
  }

  private Token skipMultiLineComment() {
    assert (is('*'));
    Position currPos = internalState.lookaheadPos[0];
    int start = currPos.pos - 1;
    int line = currPos.line;
    int col = currPos.col;
    int commentDepth = 1;
    advance();
    while (!isEos()) {
      int first = lookahead(0);
      advance();
      if (first == '*' && is('/')) {
        if(--commentDepth == 0) {
          Token result = select(Token.COMMENT);
          int stop = internalState.lookaheadPos[0].pos;
          commentLocation(start, stop, line, internalState.lookaheadPos[0].line, col);
          return result;
        }
        advance();
      } else if (first == '/' && is('*')) {
        commentDepth++;
        advance();
      }
    }
    int stop = internalState.lookaheadPos[0].pos;
    commentLocation(start, stop, line, internalState.lookaheadPos[0].line, col);
    // Unterminated multi-line comment.
    return Token.ILLEGAL;
  }

  private Token skipSingleLineComment() {
    assert (is('/'));
    Position currPos = internalState.lookaheadPos[0];
    int start = currPos.pos - 1;
    int line = currPos.line;
    int col = currPos.col;
    advance();
    while (!isEos() && !isLineTerminator(lookahead(0)))
      advance();
    int stop = internalState.lookaheadPos[0].pos;
    commentLocation(start, stop, line, internalState.lookaheadPos[0].line, col);
    return Token.COMMENT;
  }

  private void skipWhiteSpace() {
    if ((internalState.getMode() != InternalState.Mode.DEFAULT)
        && (internalState.getMode() != InternalState.Mode.IN_STRING_EMBEDDED_EXPRESSION)) {
      return;
    }
    while (true) {
      if (isLineTerminator(lookahead(0))) {
      } else if (!isWhiteSpace(lookahead(0))) {
        break;
      }
      advance();
    }
  }
}
