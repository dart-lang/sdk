// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.scanner.scanner;

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A state in a state machine used to scan keywords.
 */
class KeywordState {
  /**
   * An empty transition table used by leaf states.
   */
  static List<KeywordState> _EMPTY_TABLE = new List<KeywordState>(26);

  /**
   * The initial state in the state machine.
   */
  static final KeywordState KEYWORD_STATE = _createKeywordStateTable();

  /**
   * A table mapping characters to the states to which those characters will
   * transition. (The index into the array is the offset from the character
   * `'a'` to the transitioning character.)
   */
  final List<KeywordState> _table;

  /**
   * The keyword that is recognized by this state, or `null` if this state is
   * not a terminal state.
   */
  Keyword _keyword;

  /**
   * Initialize a newly created state to have the given transitions and to
   * recognize the keyword with the given [syntax].
   */
  KeywordState(this._table, String syntax) {
    this._keyword = (syntax == null) ? null : Keyword.keywords[syntax];
  }

  /**
   * Return the keyword that was recognized by this state, or `null` if this
   * state does not recognized a keyword.
   */
  Keyword keyword() => _keyword;

  /**
   * Return the state that follows this state on a transition of the given
   * [character], or `null` if there is no valid state reachable from this state
   * with such a transition.
   */
  KeywordState next(int character) => _table[character - 0x61];

  /**
   * Create the next state in the state machine where we have already recognized
   * the subset of strings in the given array of [strings] starting at the given
   * [offset] and having the given [length]. All of these strings have a common
   * prefix and the next character is at the given [start] index.
   */
  static KeywordState _computeKeywordStateTable(
      int start, List<String> strings, int offset, int length) {
    List<KeywordState> result = new List<KeywordState>(26);
    assert(length != 0);
    int chunk = 0x0;
    int chunkStart = -1;
    bool isLeaf = false;
    for (int i = offset; i < offset + length; i++) {
      if (strings[i].length == start) {
        isLeaf = true;
      }
      if (strings[i].length > start) {
        int c = strings[i].codeUnitAt(start);
        if (chunk != c) {
          if (chunkStart != -1) {
            result[chunk - 0x61] = _computeKeywordStateTable(
                start + 1, strings, chunkStart, i - chunkStart);
          }
          chunkStart = i;
          chunk = c;
        }
      }
    }
    if (chunkStart != -1) {
      assert(result[chunk - 0x61] == null);
      result[chunk - 0x61] = _computeKeywordStateTable(
          start + 1, strings, chunkStart, offset + length - chunkStart);
    } else {
      assert(length == 1);
      return new KeywordState(_EMPTY_TABLE, strings[offset]);
    }
    if (isLeaf) {
      return new KeywordState(result, strings[offset]);
    } else {
      return new KeywordState(result, null);
    }
  }

  /**
   * Create and return the initial state in the state machine.
   */
  static KeywordState _createKeywordStateTable() {
    List<Keyword> values = Keyword.values;
    List<String> strings = new List<String>(values.length);
    for (int i = 0; i < values.length; i++) {
      strings[i] = values[i].syntax;
    }
    strings.sort();
    return _computeKeywordStateTable(0, strings, 0, strings.length);
  }
}

/**
 * The class `Scanner` implements a scanner for Dart code.
 *
 * The lexical structure of Dart is ambiguous without knowledge of the context
 * in which a token is being scanned. For example, without context we cannot
 * determine whether source of the form "<<" should be scanned as a single
 * left-shift operator or as two left angle brackets. This scanner does not have
 * any context, so it always resolves such conflicts by scanning the longest
 * possible token.
 */
class Scanner {
  /**
   * The source being scanned.
   */
  final Source source;

  /**
   * The reader used to access the characters in the source.
   */
  final CharacterReader _reader;

  /**
   * The error listener that will be informed of any errors that are found
   * during the scan.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The flag specifying whether documentation comments should be parsed.
   */
  bool _preserveComments = true;

  /**
   * The token pointing to the head of the linked list of tokens.
   */
  Token _tokens;

  /**
   * The last token that was scanned.
   */
  Token _tail;

  /**
   * The first token in the list of comment tokens found since the last
   * non-comment token.
   */
  Token _firstComment;

  /**
   * The last token in the list of comment tokens found since the last
   * non-comment token.
   */
  Token _lastComment;

  /**
   * The index of the first character of the current token.
   */
  int _tokenStart = 0;

  /**
   * A list containing the offsets of the first character of each line in the
   * source code.
   */
  List<int> _lineStarts = new List<int>();

  /**
   * A list, treated something like a stack, of tokens representing the
   * beginning of a matched pair. It is used to pair the end tokens with the
   * begin tokens.
   */
  List<BeginToken> _groupingStack = new List<BeginToken>();

  /**
   * The index of the last item in the [_groupingStack], or `-1` if the stack is
   * empty.
   */
  int _stackEnd = -1;

  /**
   * A flag indicating whether any unmatched groups were found during the parse.
   */
  bool _hasUnmatchedGroups = false;

  /**
   * A flag indicating whether to parse generic method comments, of the form
   * `/*=T*/` and `/*<T>*/`.
   */
  bool scanGenericMethodComments = false;

  /**
   * Initialize a newly created scanner to scan characters from the given
   * [source]. The given character [_reader] will be used to read the characters
   * in the source. The given [_errorListener] will be informed of any errors
   * that are found.
   */
  Scanner(this.source, this._reader, this._errorListener) {
    _tokens = new Token(TokenType.EOF, -1);
    _tokens.setNext(_tokens);
    _tail = _tokens;
    _tokenStart = -1;
    _lineStarts.add(0);
  }

  /**
   * Return the first token in the token stream that was scanned.
   */
  Token get firstToken => _tokens.next;

  /**
   * Return `true` if any unmatched groups were found during the parse.
   */
  bool get hasUnmatchedGroups => _hasUnmatchedGroups;

  /**
   * Return an array containing the offsets of the first character of each line
   * in the source code.
   */
  List<int> get lineStarts => _lineStarts;

  /**
   * Set whether documentation tokens should be preserved.
   */
  void set preserveComments(bool preserveComments) {
    this._preserveComments = preserveComments;
  }

  /**
   * Return the last token that was scanned.
   */
  Token get tail => _tail;

  /**
   * Append the given [token] to the end of the token stream being scanned. This
   * method is intended to be used by subclasses that copy existing tokens and
   * should not normally be used because it will fail to correctly associate any
   * comments with the token being passed in.
   */
  void appendToken(Token token) {
    _tail = _tail.setNext(token);
  }

  int bigSwitch(int next) {
    _beginToken();
    if (next == 0xD) {
      // '\r'
      next = _reader.advance();
      if (next == 0xA) {
        // '\n'
        next = _reader.advance();
      }
      recordStartOfLine();
      return next;
    } else if (next == 0xA) {
      // '\n'
      next = _reader.advance();
      recordStartOfLine();
      return next;
    } else if (next == 0x9 || next == 0x20) {
      // '\t' || ' '
      return _reader.advance();
    }
    if (next == 0x72) {
      // 'r'
      int peek = _reader.peek();
      if (peek == 0x22 || peek == 0x27) {
        // '"' || "'"
        int start = _reader.offset;
        return _tokenizeString(_reader.advance(), start, true);
      }
    }
    if (0x61 <= next && next <= 0x7A) {
      // 'a'-'z'
      return _tokenizeKeywordOrIdentifier(next, true);
    }
    if ((0x41 <= next && next <= 0x5A) || next == 0x5F || next == 0x24) {
      // 'A'-'Z' || '_' || '$'
      return _tokenizeIdentifier(next, _reader.offset, true);
    }
    if (next == 0x3C) {
      // '<'
      return _tokenizeLessThan(next);
    }
    if (next == 0x3E) {
      // '>'
      return _tokenizeGreaterThan(next);
    }
    if (next == 0x3D) {
      // '='
      return _tokenizeEquals(next);
    }
    if (next == 0x21) {
      // '!'
      return _tokenizeExclamation(next);
    }
    if (next == 0x2B) {
      // '+'
      return _tokenizePlus(next);
    }
    if (next == 0x2D) {
      // '-'
      return _tokenizeMinus(next);
    }
    if (next == 0x2A) {
      // '*'
      return _tokenizeMultiply(next);
    }
    if (next == 0x25) {
      // '%'
      return _tokenizePercent(next);
    }
    if (next == 0x26) {
      // '&'
      return _tokenizeAmpersand(next);
    }
    if (next == 0x7C) {
      // '|'
      return _tokenizeBar(next);
    }
    if (next == 0x5E) {
      // '^'
      return _tokenizeCaret(next);
    }
    if (next == 0x5B) {
      // '['
      return _tokenizeOpenSquareBracket(next);
    }
    if (next == 0x7E) {
      // '~'
      return _tokenizeTilde(next);
    }
    if (next == 0x5C) {
      // '\\'
      _appendTokenOfType(TokenType.BACKSLASH);
      return _reader.advance();
    }
    if (next == 0x23) {
      // '#'
      return _tokenizeTag(next);
    }
    if (next == 0x28) {
      // '('
      _appendBeginToken(TokenType.OPEN_PAREN);
      return _reader.advance();
    }
    if (next == 0x29) {
      // ')'
      _appendEndToken(TokenType.CLOSE_PAREN, TokenType.OPEN_PAREN);
      return _reader.advance();
    }
    if (next == 0x2C) {
      // ','
      _appendTokenOfType(TokenType.COMMA);
      return _reader.advance();
    }
    if (next == 0x3A) {
      // ':'
      _appendTokenOfType(TokenType.COLON);
      return _reader.advance();
    }
    if (next == 0x3B) {
      // ';'
      _appendTokenOfType(TokenType.SEMICOLON);
      return _reader.advance();
    }
    if (next == 0x3F) {
      // '?'
      return _tokenizeQuestion();
    }
    if (next == 0x5D) {
      // ']'
      _appendEndToken(
          TokenType.CLOSE_SQUARE_BRACKET, TokenType.OPEN_SQUARE_BRACKET);
      return _reader.advance();
    }
    if (next == 0x60) {
      // '`'
      _appendTokenOfType(TokenType.BACKPING);
      return _reader.advance();
    }
    if (next == 0x7B) {
      // '{'
      _appendBeginToken(TokenType.OPEN_CURLY_BRACKET);
      return _reader.advance();
    }
    if (next == 0x7D) {
      // '}'
      _appendEndToken(
          TokenType.CLOSE_CURLY_BRACKET, TokenType.OPEN_CURLY_BRACKET);
      return _reader.advance();
    }
    if (next == 0x2F) {
      // '/'
      return _tokenizeSlashOrComment(next);
    }
    if (next == 0x40) {
      // '@'
      _appendTokenOfType(TokenType.AT);
      return _reader.advance();
    }
    if (next == 0x22 || next == 0x27) {
      // '"' || "'"
      return _tokenizeString(next, _reader.offset, false);
    }
    if (next == 0x2E) {
      // '.'
      return _tokenizeDotOrNumber(next);
    }
    if (next == 0x30) {
      // '0'
      return _tokenizeHexOrNumber(next);
    }
    if (0x31 <= next && next <= 0x39) {
      // '1'-'9'
      return _tokenizeNumber(next);
    }
    if (next == -1) {
      // EOF
      return -1;
    }
    _reportError(ScannerErrorCode.ILLEGAL_CHARACTER, [next]);
    return _reader.advance();
  }

  /**
   * Record the fact that we are at the beginning of a new line in the source.
   */
  void recordStartOfLine() {
    _lineStarts.add(_reader.offset);
  }

  /**
   * Record that the source begins on the given [line] and [column] at the
   * current offset as given by the reader. Both the line and the column are
   * one-based indexes. The line starts for lines before the given line will not
   * be correct.
   *
   * This method must be invoked at most one time and must be invoked before
   * scanning begins. The values provided must be sensible. The results are
   * undefined if these conditions are violated.
   */
  void setSourceStart(int line, int column) {
    int offset = _reader.offset;
    if (line < 1 || column < 1 || offset < 0 || (line + column - 2) >= offset) {
      return;
    }
    for (int i = 2; i < line; i++) {
      _lineStarts.add(1);
    }
    _lineStarts.add(offset - column + 1);
  }

  /**
   * Scan the source code to produce a list of tokens representing the source,
   * and return the first token in the list of tokens that were produced.
   */
  Token tokenize() {
    int next = _reader.advance();
    while (next != -1) {
      next = bigSwitch(next);
    }
    _appendEofToken();
    return firstToken;
  }

  void _appendBeginToken(TokenType type) {
    BeginToken token;
    if (_firstComment == null) {
      token = new BeginToken(type, _tokenStart);
    } else {
      token = new BeginTokenWithComment(type, _tokenStart, _firstComment);
      _firstComment = null;
      _lastComment = null;
    }
    _tail = _tail.setNext(token);
    _groupingStack.add(token);
    _stackEnd++;
  }

  void _appendCommentToken(TokenType type, String value) {
    CommentToken token = null;
    TokenType genericComment = _matchGenericMethodCommentType(value);
    if (genericComment != null) {
      token = new CommentToken(genericComment, value, _tokenStart);
    } else if (!_preserveComments) {
      // Ignore comment tokens if client specified that it doesn't need them.
      return;
    } else {
      // OK, remember comment tokens.
      if (_isDocumentationComment(value)) {
        token = new DocumentationCommentToken(type, value, _tokenStart);
      } else {
        token = new CommentToken(type, value, _tokenStart);
      }
    }
    if (_firstComment == null) {
      _firstComment = token;
      _lastComment = _firstComment;
    } else {
      _lastComment = _lastComment.setNext(token);
    }
  }

  void _appendEndToken(TokenType type, TokenType beginType) {
    Token token;
    if (_firstComment == null) {
      token = new Token(type, _tokenStart);
    } else {
      token = new TokenWithComment(type, _tokenStart, _firstComment);
      _firstComment = null;
      _lastComment = null;
    }
    _tail = _tail.setNext(token);
    if (_stackEnd >= 0) {
      BeginToken begin = _groupingStack[_stackEnd];
      if (begin.type == beginType) {
        begin.endToken = token;
        _groupingStack.removeAt(_stackEnd--);
      }
    }
  }

  void _appendEofToken() {
    Token eofToken;
    if (_firstComment == null) {
      eofToken = new Token(TokenType.EOF, _reader.offset + 1);
    } else {
      eofToken = new TokenWithComment(
          TokenType.EOF, _reader.offset + 1, _firstComment);
      _firstComment = null;
      _lastComment = null;
    }
    // The EOF token points to itself so that there is always infinite
    // look-ahead.
    eofToken.setNext(eofToken);
    _tail = _tail.setNext(eofToken);
    if (_stackEnd >= 0) {
      _hasUnmatchedGroups = true;
      // TODO(brianwilkerson) Fix the ungrouped tokens?
    }
  }

  void _appendKeywordToken(Keyword keyword) {
    if (_firstComment == null) {
      _tail = _tail.setNext(new KeywordToken(keyword, _tokenStart));
    } else {
      _tail = _tail.setNext(
          new KeywordTokenWithComment(keyword, _tokenStart, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void _appendStringToken(TokenType type, String value) {
    if (_firstComment == null) {
      _tail = _tail.setNext(new StringToken(type, value, _tokenStart));
    } else {
      _tail = _tail.setNext(
          new StringTokenWithComment(type, value, _tokenStart, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void _appendStringTokenWithOffset(TokenType type, String value, int offset) {
    if (_firstComment == null) {
      _tail = _tail.setNext(new StringToken(type, value, _tokenStart + offset));
    } else {
      _tail = _tail.setNext(new StringTokenWithComment(
          type, value, _tokenStart + offset, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void _appendTokenOfType(TokenType type) {
    if (_firstComment == null) {
      _tail = _tail.setNext(new Token(type, _tokenStart));
    } else {
      _tail =
          _tail.setNext(new TokenWithComment(type, _tokenStart, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void _appendTokenOfTypeWithOffset(TokenType type, int offset) {
    if (_firstComment == null) {
      _tail = _tail.setNext(new Token(type, offset));
    } else {
      _tail = _tail.setNext(new TokenWithComment(type, offset, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void _beginToken() {
    _tokenStart = _reader.offset;
  }

  /**
   * Return the beginning token corresponding to a closing brace that was found
   * while scanning inside a string interpolation expression. Tokens that cannot
   * be matched with the closing brace will be dropped from the stack.
   */
  BeginToken _findTokenMatchingClosingBraceInInterpolationExpression() {
    while (_stackEnd >= 0) {
      BeginToken begin = _groupingStack[_stackEnd];
      if (begin.type == TokenType.OPEN_CURLY_BRACKET ||
          begin.type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
        return begin;
      }
      _hasUnmatchedGroups = true;
      _groupingStack.removeAt(_stackEnd--);
    }
    //
    // We should never get to this point because we wouldn't be inside a string
    // interpolation expression unless we had previously found the start of the
    // expression.
    //
    return null;
  }

  /**
   * Checks if [value] is the start of a generic method type annotation comment.
   *
   * This can either be of the form `/*<T>*/` or `/*=T*/`. The token type is
   * returned, or null if it was not a generic method comment.
   */
  TokenType _matchGenericMethodCommentType(String value) {
    if (scanGenericMethodComments) {
      // Match /*< and >*/
      if (StringUtilities.startsWith3(value, 0, 0x2F, 0x2A, 0x3C) &&
          StringUtilities.endsWith3(value, 0x3E, 0x2A, 0x2F)) {
        return TokenType.GENERIC_METHOD_TYPE_LIST;
      }
      // Match /*=
      if (StringUtilities.startsWith3(value, 0, 0x2F, 0x2A, 0x3D)) {
        return TokenType.GENERIC_METHOD_TYPE_ASSIGN;
      }
    }
    return null;
  }

  /**
   * Report an error at the current offset. The [errorCode] is the error code
   * indicating the nature of the error. The [arguments] are any arguments
   * needed to complete the error message
   */
  void _reportError(ScannerErrorCode errorCode, [List<Object> arguments]) {
    _errorListener.onError(
        new AnalysisError(source, _reader.offset, 1, errorCode, arguments));
  }

  int _select(int choice, TokenType yesType, TokenType noType) {
    int next = _reader.advance();
    if (next == choice) {
      _appendTokenOfType(yesType);
      return _reader.advance();
    } else {
      _appendTokenOfType(noType);
      return next;
    }
  }

  int _selectWithOffset(
      int choice, TokenType yesType, TokenType noType, int offset) {
    int next = _reader.advance();
    if (next == choice) {
      _appendTokenOfTypeWithOffset(yesType, offset);
      return _reader.advance();
    } else {
      _appendTokenOfTypeWithOffset(noType, offset);
      return next;
    }
  }

  int _tokenizeAmpersand(int next) {
    // && &= &
    next = _reader.advance();
    if (next == 0x26) {
      _appendTokenOfType(TokenType.AMPERSAND_AMPERSAND);
      return _reader.advance();
    } else if (next == 0x3D) {
      _appendTokenOfType(TokenType.AMPERSAND_EQ);
      return _reader.advance();
    } else {
      _appendTokenOfType(TokenType.AMPERSAND);
      return next;
    }
  }

  int _tokenizeBar(int next) {
    // | || |=
    next = _reader.advance();
    if (next == 0x7C) {
      _appendTokenOfType(TokenType.BAR_BAR);
      return _reader.advance();
    } else if (next == 0x3D) {
      _appendTokenOfType(TokenType.BAR_EQ);
      return _reader.advance();
    } else {
      _appendTokenOfType(TokenType.BAR);
      return next;
    }
  }

  int _tokenizeCaret(int next) =>
      _select(0x3D, TokenType.CARET_EQ, TokenType.CARET);

  int _tokenizeDotOrNumber(int next) {
    int start = _reader.offset;
    next = _reader.advance();
    if (0x30 <= next && next <= 0x39) {
      return _tokenizeFractionPart(next, start);
    } else if (0x2E == next) {
      return _select(
          0x2E, TokenType.PERIOD_PERIOD_PERIOD, TokenType.PERIOD_PERIOD);
    } else {
      _appendTokenOfType(TokenType.PERIOD);
      return next;
    }
  }

  int _tokenizeEquals(int next) {
    // = == =>
    next = _reader.advance();
    if (next == 0x3D) {
      _appendTokenOfType(TokenType.EQ_EQ);
      return _reader.advance();
    } else if (next == 0x3E) {
      _appendTokenOfType(TokenType.FUNCTION);
      return _reader.advance();
    }
    _appendTokenOfType(TokenType.EQ);
    return next;
  }

  int _tokenizeExclamation(int next) {
    // ! !=
    next = _reader.advance();
    if (next == 0x3D) {
      _appendTokenOfType(TokenType.BANG_EQ);
      return _reader.advance();
    }
    _appendTokenOfType(TokenType.BANG);
    return next;
  }

  int _tokenizeExponent(int next) {
    if (next == 0x2B || next == 0x2D) {
      next = _reader.advance();
    }
    bool hasDigits = false;
    while (true) {
      if (0x30 <= next && next <= 0x39) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          _reportError(ScannerErrorCode.MISSING_DIGIT);
        }
        return next;
      }
      next = _reader.advance();
    }
  }

  int _tokenizeFractionPart(int next, int start) {
    bool done = false;
    bool hasDigit = false;
    LOOP: while (!done) {
      if (0x30 <= next && next <= 0x39) {
        hasDigit = true;
      } else if (0x65 == next || 0x45 == next) {
        hasDigit = true;
        next = _tokenizeExponent(_reader.advance());
        done = true;
        continue LOOP;
      } else {
        done = true;
        continue LOOP;
      }
      next = _reader.advance();
    }
    if (!hasDigit) {
      _appendStringToken(TokenType.INT, _reader.getString(start, -2));
      if (0x2E == next) {
        return _selectWithOffset(0x2E, TokenType.PERIOD_PERIOD_PERIOD,
            TokenType.PERIOD_PERIOD, _reader.offset - 1);
      }
      _appendTokenOfTypeWithOffset(TokenType.PERIOD, _reader.offset - 1);
      return bigSwitch(next);
    }
    _appendStringToken(
        TokenType.DOUBLE, _reader.getString(start, next < 0 ? 0 : -1));
    return next;
  }

  int _tokenizeGreaterThan(int next) {
    // > >= >> >>=
    next = _reader.advance();
    if (0x3D == next) {
      _appendTokenOfType(TokenType.GT_EQ);
      return _reader.advance();
    } else if (0x3E == next) {
      next = _reader.advance();
      if (0x3D == next) {
        _appendTokenOfType(TokenType.GT_GT_EQ);
        return _reader.advance();
      } else {
        _appendTokenOfType(TokenType.GT_GT);
        return next;
      }
    } else {
      _appendTokenOfType(TokenType.GT);
      return next;
    }
  }

  int _tokenizeHex(int next) {
    int start = _reader.offset - 1;
    bool hasDigits = false;
    while (true) {
      next = _reader.advance();
      if ((0x30 <= next && next <= 0x39) ||
          (0x41 <= next && next <= 0x46) ||
          (0x61 <= next && next <= 0x66)) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          _reportError(ScannerErrorCode.MISSING_HEX_DIGIT);
        }
        _appendStringToken(
            TokenType.HEXADECIMAL, _reader.getString(start, next < 0 ? 0 : -1));
        return next;
      }
    }
  }

  int _tokenizeHexOrNumber(int next) {
    int x = _reader.peek();
    if (x == 0x78 || x == 0x58) {
      _reader.advance();
      return _tokenizeHex(x);
    }
    return _tokenizeNumber(next);
  }

  int _tokenizeIdentifier(int next, int start, bool allowDollar) {
    while ((0x61 <= next && next <= 0x7A) ||
        (0x41 <= next && next <= 0x5A) ||
        (0x30 <= next && next <= 0x39) ||
        next == 0x5F ||
        (next == 0x24 && allowDollar)) {
      next = _reader.advance();
    }
    _appendStringToken(
        TokenType.IDENTIFIER, _reader.getString(start, next < 0 ? 0 : -1));
    return next;
  }

  int _tokenizeInterpolatedExpression(int next, int start) {
    _appendBeginToken(TokenType.STRING_INTERPOLATION_EXPRESSION);
    next = _reader.advance();
    while (next != -1) {
      if (next == 0x7D) {
        BeginToken begin =
            _findTokenMatchingClosingBraceInInterpolationExpression();
        if (begin == null) {
          _beginToken();
          _appendTokenOfType(TokenType.CLOSE_CURLY_BRACKET);
          next = _reader.advance();
          _beginToken();
          return next;
        } else if (begin.type == TokenType.OPEN_CURLY_BRACKET) {
          _beginToken();
          _appendEndToken(
              TokenType.CLOSE_CURLY_BRACKET, TokenType.OPEN_CURLY_BRACKET);
          next = _reader.advance();
          _beginToken();
        } else if (begin.type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
          _beginToken();
          _appendEndToken(TokenType.CLOSE_CURLY_BRACKET,
              TokenType.STRING_INTERPOLATION_EXPRESSION);
          next = _reader.advance();
          _beginToken();
          return next;
        }
      } else {
        next = bigSwitch(next);
      }
    }
    return next;
  }

  int _tokenizeInterpolatedIdentifier(int next, int start) {
    _appendStringTokenWithOffset(
        TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 0);
    if ((0x41 <= next && next <= 0x5A) ||
        (0x61 <= next && next <= 0x7A) ||
        next == 0x5F) {
      _beginToken();
      next = _tokenizeKeywordOrIdentifier(next, false);
    }
    _beginToken();
    return next;
  }

  int _tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    KeywordState state = KeywordState.KEYWORD_STATE;
    int start = _reader.offset;
    while (state != null && 0x61 <= next && next <= 0x7A) {
      state = state.next(next);
      next = _reader.advance();
    }
    if (state == null || state.keyword() == null) {
      return _tokenizeIdentifier(next, start, allowDollar);
    }
    if ((0x41 <= next && next <= 0x5A) ||
        (0x30 <= next && next <= 0x39) ||
        next == 0x5F ||
        next == 0x24) {
      return _tokenizeIdentifier(next, start, allowDollar);
    } else if (next < 128) {
      _appendKeywordToken(state.keyword());
      return next;
    } else {
      return _tokenizeIdentifier(next, start, allowDollar);
    }
  }

  int _tokenizeLessThan(int next) {
    // < <= << <<=
    next = _reader.advance();
    if (0x3D == next) {
      _appendTokenOfType(TokenType.LT_EQ);
      return _reader.advance();
    } else if (0x3C == next) {
      return _select(0x3D, TokenType.LT_LT_EQ, TokenType.LT_LT);
    } else {
      _appendTokenOfType(TokenType.LT);
      return next;
    }
  }

  int _tokenizeMinus(int next) {
    // - -- -=
    next = _reader.advance();
    if (next == 0x2D) {
      _appendTokenOfType(TokenType.MINUS_MINUS);
      return _reader.advance();
    } else if (next == 0x3D) {
      _appendTokenOfType(TokenType.MINUS_EQ);
      return _reader.advance();
    } else {
      _appendTokenOfType(TokenType.MINUS);
      return next;
    }
  }

  int _tokenizeMultiLineComment(int next) {
    int nesting = 1;
    next = _reader.advance();
    while (true) {
      if (-1 == next) {
        _reportError(ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT);
        _appendCommentToken(
            TokenType.MULTI_LINE_COMMENT, _reader.getString(_tokenStart, 0));
        return next;
      } else if (0x2A == next) {
        next = _reader.advance();
        if (0x2F == next) {
          --nesting;
          if (0 == nesting) {
            _appendCommentToken(TokenType.MULTI_LINE_COMMENT,
                _reader.getString(_tokenStart, 0));
            return _reader.advance();
          } else {
            next = _reader.advance();
          }
        }
      } else if (0x2F == next) {
        next = _reader.advance();
        if (0x2A == next) {
          next = _reader.advance();
          ++nesting;
        }
      } else if (next == 0xD) {
        next = _reader.advance();
        if (next == 0xA) {
          next = _reader.advance();
        }
        recordStartOfLine();
      } else if (next == 0xA) {
        next = _reader.advance();
        recordStartOfLine();
      } else {
        next = _reader.advance();
      }
    }
  }

  int _tokenizeMultiLineRawString(int quoteChar, int start) {
    int next = _reader.advance();
    outer: while (next != -1) {
      while (next != quoteChar) {
        if (next == -1) {
          break outer;
        } else if (next == 0xD) {
          next = _reader.advance();
          if (next == 0xA) {
            next = _reader.advance();
          }
          recordStartOfLine();
        } else if (next == 0xA) {
          next = _reader.advance();
          recordStartOfLine();
        } else {
          next = _reader.advance();
        }
      }
      next = _reader.advance();
      if (next == quoteChar) {
        next = _reader.advance();
        if (next == quoteChar) {
          _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
          return _reader.advance();
        }
      }
    }
    _reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
    _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    return _reader.advance();
  }

  int _tokenizeMultiLineString(int quoteChar, int start, bool raw) {
    if (raw) {
      return _tokenizeMultiLineRawString(quoteChar, start);
    }
    int next = _reader.advance();
    while (next != -1) {
      if (next == 0x24) {
        _appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        next = _tokenizeStringInterpolation(start);
        _beginToken();
        start = _reader.offset;
        continue;
      }
      if (next == quoteChar) {
        next = _reader.advance();
        if (next == quoteChar) {
          next = _reader.advance();
          if (next == quoteChar) {
            _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
            return _reader.advance();
          }
        }
        continue;
      }
      if (next == 0x5C) {
        next = _reader.advance();
        if (next == -1) {
          break;
        }
        if (next == 0xD) {
          next = _reader.advance();
          if (next == 0xA) {
            next = _reader.advance();
          }
          recordStartOfLine();
        } else if (next == 0xA) {
          recordStartOfLine();
          next = _reader.advance();
        } else {
          next = _reader.advance();
        }
      } else if (next == 0xD) {
        next = _reader.advance();
        if (next == 0xA) {
          next = _reader.advance();
        }
        recordStartOfLine();
      } else if (next == 0xA) {
        recordStartOfLine();
        next = _reader.advance();
      } else {
        next = _reader.advance();
      }
    }
    _reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
    if (start == _reader.offset) {
      _appendStringTokenWithOffset(TokenType.STRING, "", 1);
    } else {
      _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    }
    return _reader.advance();
  }

  int _tokenizeMultiply(int next) =>
      _select(0x3D, TokenType.STAR_EQ, TokenType.STAR);

  int _tokenizeNumber(int next) {
    int start = _reader.offset;
    while (true) {
      next = _reader.advance();
      if (0x30 <= next && next <= 0x39) {
        continue;
      } else if (next == 0x2E) {
        return _tokenizeFractionPart(_reader.advance(), start);
      } else if (next == 0x65 || next == 0x45) {
        return _tokenizeFractionPart(next, start);
      } else {
        _appendStringToken(
            TokenType.INT, _reader.getString(start, next < 0 ? 0 : -1));
        return next;
      }
    }
  }

  int _tokenizeOpenSquareBracket(int next) {
    // [ []  []=
    next = _reader.advance();
    if (next == 0x5D) {
      return _select(0x3D, TokenType.INDEX_EQ, TokenType.INDEX);
    } else {
      _appendBeginToken(TokenType.OPEN_SQUARE_BRACKET);
      return next;
    }
  }

  int _tokenizePercent(int next) =>
      _select(0x3D, TokenType.PERCENT_EQ, TokenType.PERCENT);

  int _tokenizePlus(int next) {
    // + ++ +=
    next = _reader.advance();
    if (0x2B == next) {
      _appendTokenOfType(TokenType.PLUS_PLUS);
      return _reader.advance();
    } else if (0x3D == next) {
      _appendTokenOfType(TokenType.PLUS_EQ);
      return _reader.advance();
    } else {
      _appendTokenOfType(TokenType.PLUS);
      return next;
    }
  }

  int _tokenizeQuestion() {
    // ? ?. ?? ??=
    int next = _reader.advance();
    if (next == 0x2E) {
      // '.'
      _appendTokenOfType(TokenType.QUESTION_PERIOD);
      return _reader.advance();
    } else if (next == 0x3F) {
      // '?'
      next = _reader.advance();
      if (next == 0x3D) {
        // '='
        _appendTokenOfType(TokenType.QUESTION_QUESTION_EQ);
        return _reader.advance();
      } else {
        _appendTokenOfType(TokenType.QUESTION_QUESTION);
        return next;
      }
    } else {
      _appendTokenOfType(TokenType.QUESTION);
      return next;
    }
  }

  int _tokenizeSingleLineComment(int next) {
    while (true) {
      next = _reader.advance();
      if (-1 == next) {
        _appendCommentToken(
            TokenType.SINGLE_LINE_COMMENT, _reader.getString(_tokenStart, 0));
        return next;
      } else if (0xA == next || 0xD == next) {
        _appendCommentToken(
            TokenType.SINGLE_LINE_COMMENT, _reader.getString(_tokenStart, -1));
        return next;
      }
    }
  }

  int _tokenizeSingleLineRawString(int next, int quoteChar, int start) {
    next = _reader.advance();
    while (next != -1) {
      if (next == quoteChar) {
        _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
        return _reader.advance();
      } else if (next == 0xD || next == 0xA) {
        _reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
        _appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        return _reader.advance();
      }
      next = _reader.advance();
    }
    _reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
    _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    return _reader.advance();
  }

  int _tokenizeSingleLineString(int next, int quoteChar, int start) {
    while (next != quoteChar) {
      if (next == 0x5C) {
        next = _reader.advance();
      } else if (next == 0x24) {
        _appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        next = _tokenizeStringInterpolation(start);
        _beginToken();
        start = _reader.offset;
        continue;
      }
      if (next <= 0xD && (next == 0xA || next == 0xD || next == -1)) {
        _reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
        if (start == _reader.offset) {
          _appendStringTokenWithOffset(TokenType.STRING, "", 1);
        } else if (next == -1) {
          _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
        } else {
          _appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        }
        return _reader.advance();
      }
      next = _reader.advance();
    }
    _appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    return _reader.advance();
  }

  int _tokenizeSlashOrComment(int next) {
    next = _reader.advance();
    if (0x2A == next) {
      return _tokenizeMultiLineComment(next);
    } else if (0x2F == next) {
      return _tokenizeSingleLineComment(next);
    } else if (0x3D == next) {
      _appendTokenOfType(TokenType.SLASH_EQ);
      return _reader.advance();
    } else {
      _appendTokenOfType(TokenType.SLASH);
      return next;
    }
  }

  int _tokenizeString(int next, int start, bool raw) {
    int quoteChar = next;
    next = _reader.advance();
    if (quoteChar == next) {
      next = _reader.advance();
      if (quoteChar == next) {
        // Multiline string.
        return _tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        // Empty string.
        _appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        return next;
      }
    }
    if (raw) {
      return _tokenizeSingleLineRawString(next, quoteChar, start);
    } else {
      return _tokenizeSingleLineString(next, quoteChar, start);
    }
  }

  int _tokenizeStringInterpolation(int start) {
    _beginToken();
    int next = _reader.advance();
    if (next == 0x7B) {
      return _tokenizeInterpolatedExpression(next, start);
    } else {
      return _tokenizeInterpolatedIdentifier(next, start);
    }
  }

  int _tokenizeTag(int next) {
    // # or #!.*[\n\r]
    if (_reader.offset == 0) {
      if (_reader.peek() == 0x21) {
        do {
          next = _reader.advance();
        } while (next != 0xA && next != 0xD && next > 0);
        _appendStringToken(
            TokenType.SCRIPT_TAG, _reader.getString(_tokenStart, 0));
        return next;
      }
    }
    _appendTokenOfType(TokenType.HASH);
    return _reader.advance();
  }

  int _tokenizeTilde(int next) {
    // ~ ~/ ~/=
    next = _reader.advance();
    if (next == 0x2F) {
      return _select(0x3D, TokenType.TILDE_SLASH_EQ, TokenType.TILDE_SLASH);
    } else {
      _appendTokenOfType(TokenType.TILDE);
      return next;
    }
  }

  /**
   * Checks if [value] is a single-line or multi-line comment.
   */
  static bool _isDocumentationComment(String value) {
    return StringUtilities.startsWith3(value, 0, 0x2F, 0x2F, 0x2F) ||
        StringUtilities.startsWith3(value, 0, 0x2F, 0x2A, 0x2A);
  }
}

/**
 * The error codes used for errors detected by the scanner.
 */
class ScannerErrorCode extends ErrorCode {
  static const ScannerErrorCode ILLEGAL_CHARACTER =
      const ScannerErrorCode('ILLEGAL_CHARACTER', "Illegal character {0}");

  static const ScannerErrorCode MISSING_DIGIT =
      const ScannerErrorCode('MISSING_DIGIT', "Decimal digit expected");

  static const ScannerErrorCode MISSING_HEX_DIGIT =
      const ScannerErrorCode('MISSING_HEX_DIGIT', "Hexidecimal digit expected");

  static const ScannerErrorCode MISSING_QUOTE =
      const ScannerErrorCode('MISSING_QUOTE', "Expected quote (' or \")");

  static const ScannerErrorCode UNABLE_GET_CONTENT = const ScannerErrorCode(
      'UNABLE_GET_CONTENT', "Unable to get content: {0}");

  static const ScannerErrorCode UNTERMINATED_MULTI_LINE_COMMENT =
      const ScannerErrorCode(
          'UNTERMINATED_MULTI_LINE_COMMENT', "Unterminated multi-line comment");

  static const ScannerErrorCode UNTERMINATED_STRING_LITERAL =
      const ScannerErrorCode(
          'UNTERMINATED_STRING_LITERAL', "Unterminated string literal");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const ScannerErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}
