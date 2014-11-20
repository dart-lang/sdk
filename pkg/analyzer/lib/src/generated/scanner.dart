// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.scanner;

import "dart:math" as math;
import 'dart:collection';

import 'error.dart';
import 'instrumentation.dart';
import 'java_engine.dart';
import 'source.dart';
import 'utilities_collection.dart' show TokenMap;

/**
 * A `BeginToken` is the opening half of a grouping pair of tokens. This is used
 * for curly brackets ('{'), parentheses ('('), and square brackets ('[').
 */
class BeginToken extends Token {
  /**
   * The token that corresponds to this token.
   */
  Token endToken;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset].
   */
  BeginToken(TokenType type, int offset) : super(type, offset) {
    assert(type == TokenType.OPEN_CURLY_BRACKET ||
        type == TokenType.OPEN_PAREN ||
        type == TokenType.OPEN_SQUARE_BRACKET ||
        type == TokenType.STRING_INTERPOLATION_EXPRESSION);
  }

  @override
  Token copy() => new BeginToken(type, offset);
}

/**
 * A `BeginTokenWithComment` is a begin token that is preceded by comments.
 */
class BeginTokenWithComment extends BeginToken {
  /**
   * The first comment in the list of comments that precede this token.
   */
  final Token _precedingComment;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset] and to be preceded by the comments reachable from the given
   * [comment].
   */
  BeginTokenWithComment(TokenType type, int offset, this._precedingComment)
      : super(type, offset);

  @override
  Token get precedingComments => _precedingComment;

  @override
  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = _precedingComment;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }

  @override
  Token copy() =>
      new BeginTokenWithComment(type, offset, copyComments(_precedingComment));
}

/**
 * A `CharSequenceReader` is a [CharacterReader] that reads characters from a
 * character sequence.
 */
class CharSequenceReader implements CharacterReader {
  /**
   * The sequence from which characters will be read.
   */
  final String _sequence;

  /**
   * The number of characters in the string.
   */
  int _stringLength = 0;

  /**
   * The index, relative to the string, of the last character that was read.
   */
  int _charOffset = 0;

  /**
   * Initialize a newly created reader to read the characters in the given
   * [_sequence].
   */
  CharSequenceReader(this._sequence) {
    this._stringLength = _sequence.length;
    this._charOffset = -1;
  }

  @override
  int get offset => _charOffset;

  @override
  void set offset(int offset) {
    _charOffset = offset;
  }

  @override
  int advance() {
    if (_charOffset + 1 >= _stringLength) {
      return -1;
    }
    return _sequence.codeUnitAt(++_charOffset);
  }

  @override
  String getString(int start, int endDelta) =>
      _sequence.substring(start, _charOffset + 1 + endDelta).toString();

  @override
  int peek() {
    if (_charOffset + 1 >= _stringLength) {
      return -1;
    }
    return _sequence.codeUnitAt(_charOffset + 1);
  }
}

/**
 * A `CharacterRangeReader` is a [CharacterReader] that reads a range of
 * characters from another character reader.
 */
class CharacterRangeReader extends CharacterReader {
  /**
   * The reader from which the characters are actually being read.
   */
  final CharacterReader baseReader;

  /**
   * The last character to be read.
   */
  final int endIndex;

  /**
   * Initialize a newly created reader to read the characters from the given
   * [baseReader] between the [startIndex] inclusive to [endIndex] exclusive.
   */
  CharacterRangeReader(this.baseReader, int startIndex, this.endIndex) {
    baseReader.offset = startIndex - 1;
  }

  @override
  int get offset => baseReader.offset;

  @override
  void set offset(int offset) {
    baseReader.offset = offset;
  }

  @override
  int advance() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.advance();
  }

  @override
  String getString(int start, int endDelta) =>
      baseReader.getString(start, endDelta);

  @override
  int peek() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.peek();
  }
}

/**
 * A `CharacterReader` is used by the scanner to read the characters to be
 * scanned.
 */
abstract class CharacterReader {
  /**
   * The current offset relative to the beginning of the source. Return the
   * initial offset if the scanner has not yet scanned the source code, and one
   * (1) past the end of the source code if the entire source code has been
   * scanned.
   */
  int get offset;

  /**
   * Set the current offset relative to the beginning of the source to the given
   * [offset]. The new offset must be between the initial offset and one (1)
   * past the end of the source code.
   */
  void set offset(int offset);

  /**
   * Advance the current position and return the character at the new current
   * position.
   */
  int advance();

  /**
   * Return the substring of the source code between the [start] offset and the
   * modified current position. The current position is modified by adding the
   * [endDelta], which is the number of characters after the current location to
   * be included in the string, or the number of characters before the current
   * location to be excluded if the offset is negative.
   */
  String getString(int start, int endDelta);

  /**
   * Return the character at the current position without changing the current
   * position.
   */
  int peek();
}

/**
 * Instances of the class `IncrementalScanner` implement a scanner that scans a subset of a
 * string and inserts the resulting tokens into the middle of an existing token stream.
 */
class IncrementalScanner extends Scanner {
  /**
   * The reader used to access the characters in the source.
   */
  CharacterReader _reader;

  /**
   * A map from tokens that were copied to the copies of the tokens.
   */
  TokenMap _tokenMap = new TokenMap();

  /**
   * The token in the new token stream immediately to the left of the range of tokens that were
   * inserted, or the token immediately to the left of the modified region if there were no new
   * tokens.
   */
  Token _leftToken;

  /**
   * The token in the new token stream immediately to the right of the range of tokens that were
   * inserted, or the token immediately to the right of the modified region if there were no new
   * tokens.
   */
  Token _rightToken;

  /**
   * A flag indicating whether there were any tokens changed as a result of the modification.
   */
  bool _hasNonWhitespaceChange = false;

  /**
   * Initialize a newly created scanner.
   *
   * @param source the source being scanned
   * @param reader the character reader used to read the characters in the source
   * @param errorListener the error listener that will be informed of any errors that are found
   */
  IncrementalScanner(Source source, CharacterReader reader,
      AnalysisErrorListener errorListener)
      : super(source, reader, errorListener) {
    this._reader = reader;
  }

  /**
   * Return `true` if there were any tokens either added or removed (or both) as a result of
   * the modification.
   *
   * @return `true` if there were any tokens changed as a result of the modification
   */
  bool get hasNonWhitespaceChange => _hasNonWhitespaceChange;

  /**
   * Return the token in the new token stream immediately to the left of the range of tokens that
   * were inserted, or the token immediately to the left of the modified region if there were no new
   * tokens.
   *
   * @return the token to the left of the inserted tokens
   */
  Token get leftToken => _leftToken;

  /**
   * Return the token in the new token stream immediately to the right of the range of tokens that
   * were inserted, or the token immediately to the right of the modified region if there were no
   * new tokens.
   *
   * @return the token to the right of the inserted tokens
   */
  Token get rightToken => _rightToken;

  /**
   * Return a map from tokens that were copied to the copies of the tokens.
   *
   * @return a map from tokens that were copied to the copies of the tokens
   */
  TokenMap get tokenMap => _tokenMap;

  /**
   * Given the stream of tokens scanned from the original source, the modified source (the result of
   * replacing one contiguous range of characters with another string of characters), and a
   * specification of the modification that was made, return a stream of tokens scanned from the
   * modified source. The original stream of tokens will not be modified.
   *
   * @param originalStream the stream of tokens scanned from the original source
   * @param index the index of the first character in both the original and modified source that was
   *          affected by the modification
   * @param removedLength the number of characters removed from the original source
   * @param insertedLength the number of characters added to the modified source
   */
  Token rescan(Token originalStream, int index, int removedLength,
      int insertedLength) {
    //
    // Copy all of the tokens in the originalStream whose end is less than the
    // replacement start. (If the replacement start is equal to the end of an
    // existing token, then it means that the existing token might have been
    // modified, so we need to rescan it.)
    //
    while (originalStream.type != TokenType.EOF && originalStream.end < index) {
      originalStream = _copyAndAdvance(originalStream, 0);
    }
    Token oldFirst = originalStream;
    Token oldLeftToken = originalStream.previous;
    _leftToken = tail;
    //
    // Skip tokens in the original stream until we find a token whose offset is
    // greater than the end of the removed region. (If the end of the removed
    // region is equal to the beginning of an existing token, then it means that
    // the existing token might have been modified, so we need to rescan it.)
    //
    int removedEnd = index + (removedLength == 0 ? 0 : removedLength - 1);
    while (originalStream.type != TokenType.EOF &&
        originalStream.offset <= removedEnd) {
      originalStream = originalStream.next;
    }
    Token oldLast;
    Token oldRightToken;
    if (originalStream.type != TokenType.EOF &&
        removedEnd + 1 == originalStream.offset) {
      oldLast = originalStream;
      originalStream = originalStream.next;
      oldRightToken = originalStream;
    } else {
      oldLast = originalStream.previous;
      oldRightToken = originalStream;
    }
    //
    // Compute the delta between the character index of characters after the
    // modified region in the original source and the index of the corresponding
    // character in the modified source.
    //
    int delta = insertedLength - removedLength;
    //
    // Compute the range of characters that are known to need to be rescanned.
    // If the index is within an existing token, then we need to start at the
    // beginning of the token.
    //
    int scanStart = math.min(oldFirst.offset, index);
    int oldEnd = oldLast.end + delta - 1;
    int newEnd = index + insertedLength - 1;
    int scanEnd = math.max(newEnd, oldEnd);
    //
    // Starting at the start of the scan region, scan tokens from the
    // modifiedSource until the end of the just scanned token is greater than or
    // equal to end of the scan region in the modified source. Include trailing
    // characters of any token that was split as a result of inserted text,
    // as in "ab" --> "a.b".
    //
    _reader.offset = scanStart - 1;
    int next = _reader.advance();
    while (next != -1 && _reader.offset <= scanEnd) {
      next = bigSwitch(next);
    }
    //
    // Copy the remaining tokens in the original stream, but apply the delta to
    // the token's offset.
    //
    if (originalStream.type == TokenType.EOF) {
      _copyAndAdvance(originalStream, delta);
      _rightToken = tail;
      _rightToken.setNextWithoutSettingPrevious(_rightToken);
    } else {
      originalStream = _copyAndAdvance(originalStream, delta);
      _rightToken = tail;
      while (originalStream.type != TokenType.EOF) {
        originalStream = _copyAndAdvance(originalStream, delta);
      }
      Token eof = _copyAndAdvance(originalStream, delta);
      eof.setNextWithoutSettingPrevious(eof);
    }
    //
    // If the index is immediately after an existing token and the inserted
    // characters did not change that original token, then adjust the leftToken
    // to be the next token. For example, in "a; c;" --> "a;b c;", the leftToken
    // was ";", but this code advances it to "b" since "b" is the first new
    // token.
    //
    Token newFirst = _leftToken.next;
    while (!identical(newFirst, _rightToken) &&
        !identical(oldFirst, oldRightToken) &&
        newFirst.type != TokenType.EOF &&
        _equalTokens(oldFirst, newFirst)) {
      _tokenMap.put(oldFirst, newFirst);
      oldLeftToken = oldFirst;
      oldFirst = oldFirst.next;
      _leftToken = newFirst;
      newFirst = newFirst.next;
    }
    Token newLast = _rightToken.previous;
    while (!identical(newLast, _leftToken) &&
        !identical(oldLast, oldLeftToken) &&
        newLast.type != TokenType.EOF &&
        _equalTokens(oldLast, newLast)) {
      _tokenMap.put(oldLast, newLast);
      oldRightToken = oldLast;
      oldLast = oldLast.previous;
      _rightToken = newLast;
      newLast = newLast.previous;
    }
    _hasNonWhitespaceChange = !identical(_leftToken.next, _rightToken) ||
        !identical(oldLeftToken.next, oldRightToken);
    //
    // TODO(brianwilkerson) Begin tokens are not getting associated with the
    // corresponding end tokens (because the end tokens have not been copied
    // when we're copying the begin tokens). This could have implications for
    // parsing.
    // TODO(brianwilkerson) Update the lineInfo.
    //
    return firstToken;
  }

  Token _copyAndAdvance(Token originalToken, int delta) {
    Token copiedToken = originalToken.copy();
    _tokenMap.put(originalToken, copiedToken);
    copiedToken.offset += delta;
    appendToken(copiedToken);
    Token originalComment = originalToken.precedingComments;
    Token copiedComment = originalToken.precedingComments;
    while (originalComment != null) {
      _tokenMap.put(originalComment, copiedComment);
      originalComment = originalComment.next;
      copiedComment = copiedComment.next;
    }
    return originalToken.next;
  }

  /**
   * Return `true` if the two tokens are equal to each other. For the purposes of the
   * incremental scanner, two tokens are equal if they have the same type and lexeme.
   *
   * @param oldToken the token from the old stream that is being compared
   * @param newToken the token from the new stream that is being compared
   * @return `true` if the two tokens are equal to each other
   */
  bool _equalTokens(Token oldToken, Token newToken) =>
      oldToken.type == newToken.type &&
          oldToken.length == newToken.length &&
          oldToken.lexeme == newToken.lexeme;
}

/**
 * The enumeration `Keyword` defines the keywords in the Dart programming
 * language.
 */
class Keyword {
  static const Keyword ASSERT = const Keyword('ASSERT', "assert");

  static const Keyword BREAK = const Keyword('BREAK', "break");

  static const Keyword CASE = const Keyword('CASE', "case");

  static const Keyword CATCH = const Keyword('CATCH', "catch");

  static const Keyword CLASS = const Keyword('CLASS', "class");

  static const Keyword CONST = const Keyword('CONST', "const");

  static const Keyword CONTINUE = const Keyword('CONTINUE', "continue");

  static const Keyword DEFAULT = const Keyword('DEFAULT', "default");

  static const Keyword DO = const Keyword('DO', "do");

  static const Keyword ELSE = const Keyword('ELSE', "else");

  static const Keyword ENUM = const Keyword('ENUM', "enum");

  static const Keyword EXTENDS = const Keyword('EXTENDS', "extends");

  static const Keyword FALSE = const Keyword('FALSE', "false");

  static const Keyword FINAL = const Keyword('FINAL', "final");

  static const Keyword FINALLY = const Keyword('FINALLY', "finally");

  static const Keyword FOR = const Keyword('FOR', "for");

  static const Keyword IF = const Keyword('IF', "if");

  static const Keyword IN = const Keyword('IN', "in");

  static const Keyword IS = const Keyword('IS', "is");

  static const Keyword NEW = const Keyword('NEW', "new");

  static const Keyword NULL = const Keyword('NULL', "null");

  static const Keyword RETHROW = const Keyword('RETHROW', "rethrow");

  static const Keyword RETURN = const Keyword('RETURN', "return");

  static const Keyword SUPER = const Keyword('SUPER', "super");

  static const Keyword SWITCH = const Keyword('SWITCH', "switch");

  static const Keyword THIS = const Keyword('THIS', "this");

  static const Keyword THROW = const Keyword('THROW', "throw");

  static const Keyword TRUE = const Keyword('TRUE', "true");

  static const Keyword TRY = const Keyword('TRY', "try");

  static const Keyword VAR = const Keyword('VAR', "var");

  static const Keyword VOID = const Keyword('VOID', "void");

  static const Keyword WHILE = const Keyword('WHILE', "while");

  static const Keyword WITH = const Keyword('WITH', "with");

  static const Keyword ABSTRACT = const Keyword('ABSTRACT', "abstract", true);

  static const Keyword AS = const Keyword('AS', "as", true);

  static const Keyword DEFERRED = const Keyword('DEFERRED', "deferred", true);

  static const Keyword DYNAMIC = const Keyword('DYNAMIC', "dynamic", true);

  static const Keyword EXPORT = const Keyword('EXPORT', "export", true);

  static const Keyword EXTERNAL = const Keyword('EXTERNAL', "external", true);

  static const Keyword FACTORY = const Keyword('FACTORY', "factory", true);

  static const Keyword GET = const Keyword('GET', "get", true);

  static const Keyword IMPLEMENTS =
      const Keyword('IMPLEMENTS', "implements", true);

  static const Keyword IMPORT = const Keyword('IMPORT', "import", true);

  static const Keyword LIBRARY = const Keyword('LIBRARY', "library", true);

  static const Keyword OPERATOR = const Keyword('OPERATOR', "operator", true);

  static const Keyword PART = const Keyword('PART', "part", true);

  static const Keyword SET = const Keyword('SET', "set", true);

  static const Keyword STATIC = const Keyword('STATIC', "static", true);

  static const Keyword TYPEDEF = const Keyword('TYPEDEF', "typedef", true);

  static const List<Keyword> values = const [
      ASSERT,
      BREAK,
      CASE,
      CATCH,
      CLASS,
      CONST,
      CONTINUE,
      DEFAULT,
      DO,
      ELSE,
      ENUM,
      EXTENDS,
      FALSE,
      FINAL,
      FINALLY,
      FOR,
      IF,
      IN,
      IS,
      NEW,
      NULL,
      RETHROW,
      RETURN,
      SUPER,
      SWITCH,
      THIS,
      THROW,
      TRUE,
      TRY,
      VAR,
      VOID,
      WHILE,
      WITH,
      ABSTRACT,
      AS,
      DEFERRED,
      DYNAMIC,
      EXPORT,
      EXTERNAL,
      FACTORY,
      GET,
      IMPLEMENTS,
      IMPORT,
      LIBRARY,
      OPERATOR,
      PART,
      SET,
      STATIC,
      TYPEDEF];

  /**
   * A table mapping the lexemes of keywords to the corresponding keyword.
   */
  static final Map<String, Keyword> keywords = _createKeywordMap();

  /**
   * The name of the keyword type.
   */
  final String name;

  /**
   * The lexeme for the keyword.
   */
  final String syntax;

  /**
   * A flag indicating whether the keyword is a pseudo-keyword. Pseudo keywords
   * can be used as identifiers.
   */
  final bool isPseudoKeyword;

  /**
   * Initialize a newly created keyword to have the given [name] and [syntax].
   * The keyword is a pseudo-keyword if the [isPseudoKeyword] flag is `true`.
   */
  const Keyword(this.name, this.syntax, [this.isPseudoKeyword = false]);

  /**
   * Create a table mapping the lexemes of keywords to the corresponding keyword
   * and return the table that was created.
   */
  static Map<String, Keyword> _createKeywordMap() {
    LinkedHashMap<String, Keyword> result =
        new LinkedHashMap<String, Keyword>();
    for (Keyword keyword in values) {
      result[keyword.syntax] = keyword;
    }
    return result;
  }
}

/**
 * A `KeywordState` is a state in a state machine used to scan keywords.
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
   *
   * [start] the index of the character in the strings used to transition to a
   * new state
   * [strings] an array containing all of the strings that will be recognized by
   * the state machine
   * [offset] the offset of the first string in the array that has the prefix
   * that is assumed to have been recognized by the time we reach the state
   * being built
   * [length] the number of strings in the array that pass through the state
   * being built
   */
  static KeywordState _computeKeywordStateTable(int start, List<String> strings,
      int offset, int length) {
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
            result[chunk - 0x61] =
                _computeKeywordStateTable(start + 1, strings, chunkStart, i - chunkStart);
          }
          chunkStart = i;
          chunk = c;
        }
      }
    }
    if (chunkStart != -1) {
      assert(result[chunk - 0x61] == null);
      result[chunk -
          0x61] = _computeKeywordStateTable(
              start + 1,
              strings,
              chunkStart,
              offset + length - chunkStart);
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
 * A `KeywordToken` is a keyword in the language.
 */
class KeywordToken extends Token {
  /**
   * The keyword being represented by this token.
   */
  final Keyword keyword;

  /**
   * Initialize a newly created token to represent the given [keyword] at the
   * given [offset].
   */
  KeywordToken(this.keyword, int offset) : super(TokenType.KEYWORD, offset);

  @override
  String get lexeme => keyword.syntax;

  @override
  Token copy() => new KeywordToken(keyword, offset);

  @override
  Keyword value() => keyword;
}

/**
 * A `KeywordTokenWithComment` is a keyword token that is preceded by comments.
 */
class KeywordTokenWithComment extends KeywordToken {
  /**
   * The first comment in the list of comments that precede this token.
   */
  final Token _precedingComment;

  /**
   * Initialize a newly created token to to represent the given [keyword] at the
   * given [offset] and to be preceded by the comments reachable from the given
   * [comment].
   */
  KeywordTokenWithComment(Keyword keyword, int offset, this._precedingComment)
      : super(keyword, offset);

  @override
  Token get precedingComments => _precedingComment;

  @override
  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = _precedingComment;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }

  @override
  Token copy() =>
      new KeywordTokenWithComment(keyword, offset, copyComments(_precedingComment));
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
      next = _reader.advance();
      if (next == 0xA) {
        next = _reader.advance();
      }
      recordStartOfLine();
      return next;
    } else if (next == 0xA) {
      next = _reader.advance();
      recordStartOfLine();
      return next;
    } else if (next == 0x9 || next == 0x20) {
      return _reader.advance();
    }
    if (next == 0x72) {
      int peek = _reader.peek();
      if (peek == 0x22 || peek == 0x27) {
        int start = _reader.offset;
        return _tokenizeString(_reader.advance(), start, true);
      }
    }
    if (0x61 <= next && next <= 0x7A) {
      return _tokenizeKeywordOrIdentifier(next, true);
    }
    if ((0x41 <= next && next <= 0x5A) || next == 0x5F || next == 0x24) {
      return _tokenizeIdentifier(next, _reader.offset, true);
    }
    if (next == 0x3C) {
      return _tokenizeLessThan(next);
    }
    if (next == 0x3E) {
      return _tokenizeGreaterThan(next);
    }
    if (next == 0x3D) {
      return _tokenizeEquals(next);
    }
    if (next == 0x21) {
      return _tokenizeExclamation(next);
    }
    if (next == 0x2B) {
      return _tokenizePlus(next);
    }
    if (next == 0x2D) {
      return _tokenizeMinus(next);
    }
    if (next == 0x2A) {
      return _tokenizeMultiply(next);
    }
    if (next == 0x25) {
      return _tokenizePercent(next);
    }
    if (next == 0x26) {
      return _tokenizeAmpersand(next);
    }
    if (next == 0x7C) {
      return _tokenizeBar(next);
    }
    if (next == 0x5E) {
      return _tokenizeCaret(next);
    }
    if (next == 0x5B) {
      return _tokenizeOpenSquareBracket(next);
    }
    if (next == 0x7E) {
      return _tokenizeTilde(next);
    }
    if (next == 0x5C) {
      _appendTokenOfType(TokenType.BACKSLASH);
      return _reader.advance();
    }
    if (next == 0x23) {
      return _tokenizeTag(next);
    }
    if (next == 0x28) {
      _appendBeginToken(TokenType.OPEN_PAREN);
      return _reader.advance();
    }
    if (next == 0x29) {
      _appendEndToken(TokenType.CLOSE_PAREN, TokenType.OPEN_PAREN);
      return _reader.advance();
    }
    if (next == 0x2C) {
      _appendTokenOfType(TokenType.COMMA);
      return _reader.advance();
    }
    if (next == 0x3A) {
      _appendTokenOfType(TokenType.COLON);
      return _reader.advance();
    }
    if (next == 0x3B) {
      _appendTokenOfType(TokenType.SEMICOLON);
      return _reader.advance();
    }
    if (next == 0x3F) {
      _appendTokenOfType(TokenType.QUESTION);
      return _reader.advance();
    }
    if (next == 0x5D) {
      _appendEndToken(
          TokenType.CLOSE_SQUARE_BRACKET,
          TokenType.OPEN_SQUARE_BRACKET);
      return _reader.advance();
    }
    if (next == 0x60) {
      _appendTokenOfType(TokenType.BACKPING);
      return _reader.advance();
    }
    if (next == 0x7B) {
      _appendBeginToken(TokenType.OPEN_CURLY_BRACKET);
      return _reader.advance();
    }
    if (next == 0x7D) {
      _appendEndToken(
          TokenType.CLOSE_CURLY_BRACKET,
          TokenType.OPEN_CURLY_BRACKET);
      return _reader.advance();
    }
    if (next == 0x2F) {
      return _tokenizeSlashOrComment(next);
    }
    if (next == 0x40) {
      _appendTokenOfType(TokenType.AT);
      return _reader.advance();
    }
    if (next == 0x22 || next == 0x27) {
      return _tokenizeString(next, _reader.offset, false);
    }
    if (next == 0x2E) {
      return _tokenizeDotOrNumber(next);
    }
    if (next == 0x30) {
      return _tokenizeHexOrNumber(next);
    }
    if (0x31 <= next && next <= 0x39) {
      return _tokenizeNumber(next);
    }
    if (next == -1) {
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
   * current offset as given by the reader. The line starts for lines before the
   * given line will not be correct.
   *
   * This method must be invoked at most one time and must be invoked before
   * scanning begins. The values provided must be sensible. The results are
   * undefined if these conditions are violated.
   *
   * [line] the one-based index of the line containing the first character of
   * the source
   * [column] the one-based index of the column in which the first character of
   * the source occurs
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
    InstrumentationBuilder instrumentation =
        Instrumentation.builder2("dart.engine.AbstractScanner.tokenize");
    int tokenCounter = 0;
    try {
      int next = _reader.advance();
      while (next != -1) {
        tokenCounter++;
        next = bigSwitch(next);
      }
      _appendEofToken();
      instrumentation.metric2("tokensCount", tokenCounter);
      return firstToken;
    } finally {
      instrumentation.log2(2);
      //Log if over 1ms
    }
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
    // Ignore comment tokens if client specified that it doesn't need them.
    if (!_preserveComments) {
      return;
    }
    // OK, remember comment tokens.
    if (_firstComment == null) {
      _firstComment = new StringToken(type, value, _tokenStart);
      _lastComment = _firstComment;
    } else {
      _lastComment =
          _lastComment.setNext(new StringToken(type, value, _tokenStart));
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
      eofToken =
          new TokenWithComment(TokenType.EOF, _reader.offset + 1, _firstComment);
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
      _tail = _tail.setNext(
          new StringTokenWithComment(type, value, _tokenStart + offset, _firstComment));
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
   * Report an error at the current offset.
   *
   * [errorCode] the error code indicating the nature of the error
   * [arguments] any arguments needed to complete the error message
   */
  void _reportError(ScannerErrorCode errorCode, [List<Object> arguments]) {
    _errorListener.onError(
        new AnalysisError.con2(source, _reader.offset, 1, errorCode, arguments));
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

  int _selectWithOffset(int choice, TokenType yesType, TokenType noType,
      int offset) {
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
          0x2E,
          TokenType.PERIOD_PERIOD_PERIOD,
          TokenType.PERIOD_PERIOD);
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
        return _selectWithOffset(
            0x2E,
            TokenType.PERIOD_PERIOD_PERIOD,
            TokenType.PERIOD_PERIOD,
            _reader.offset - 1);
      }
      _appendTokenOfTypeWithOffset(TokenType.PERIOD, _reader.offset - 1);
      return bigSwitch(next);
    }
    _appendStringToken(
        TokenType.DOUBLE,
        _reader.getString(start, next < 0 ? 0 : -1));
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
            TokenType.HEXADECIMAL,
            _reader.getString(start, next < 0 ? 0 : -1));
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
        TokenType.IDENTIFIER,
        _reader.getString(start, next < 0 ? 0 : -1));
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
              TokenType.CLOSE_CURLY_BRACKET,
              TokenType.OPEN_CURLY_BRACKET);
          next = _reader.advance();
          _beginToken();
        } else if (begin.type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
          _beginToken();
          _appendEndToken(
              TokenType.CLOSE_CURLY_BRACKET,
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
        TokenType.STRING_INTERPOLATION_IDENTIFIER,
        "\$",
        0);
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
            TokenType.MULTI_LINE_COMMENT,
            _reader.getString(_tokenStart, 0));
        return next;
      } else if (0x2A == next) {
        next = _reader.advance();
        if (0x2F == next) {
          --nesting;
          if (0 == nesting) {
            _appendCommentToken(
                TokenType.MULTI_LINE_COMMENT,
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
        recordStartOfLine();
        next = _reader.advance();
      } else {
        next = _reader.advance();
      }
    }
  }

  int _tokenizeMultiLineRawString(int quoteChar, int start) {
    int next = _reader.advance();
    outer: while (next != -1) {
      while (next != quoteChar) {
        next = _reader.advance();
        if (next == -1) {
          break outer;
        } else if (next == 0xD) {
          next = _reader.advance();
          if (next == 0xA) {
            next = _reader.advance();
          }
          recordStartOfLine();
        } else if (next == 0xA) {
          recordStartOfLine();
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
            TokenType.INT,
            _reader.getString(start, next < 0 ? 0 : -1));
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

  int _tokenizeSingleLineComment(int next) {
    while (true) {
      next = _reader.advance();
      if (-1 == next) {
        _appendCommentToken(
            TokenType.SINGLE_LINE_COMMENT,
            _reader.getString(_tokenStart, 0));
        return next;
      } else if (0xA == next || 0xD == next) {
        _appendCommentToken(
            TokenType.SINGLE_LINE_COMMENT,
            _reader.getString(_tokenStart, -1));
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
            TokenType.SCRIPT_TAG,
            _reader.getString(_tokenStart, 0));
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
}

/**
 * The enumeration `ScannerErrorCode` defines the error codes used for errors
 * detected by the scanner.
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

  static const ScannerErrorCode UNTERMINATED_MULTI_LINE_COMMENT =
      const ScannerErrorCode(
          'UNTERMINATED_MULTI_LINE_COMMENT',
          "Unterminated multi-line comment");

  static const ScannerErrorCode UNTERMINATED_STRING_LITERAL =
      const ScannerErrorCode(
          'UNTERMINATED_STRING_LITERAL',
          "Unterminated string literal");

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

/**
 * A `StringToken` is a token whose value is independent of it's type.
 */
class StringToken extends Token {
  /**
   * The lexeme represented by this token.
   */
  String _value;

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  StringToken(TokenType type, String value, int offset) : super(type, offset) {
    this._value = StringUtilities.intern(value);
  }

  @override
  String get lexeme => _value;

  @override
  Token copy() => new StringToken(type, _value, offset);

  @override
  String value() => _value;
}

/**
 * A `StringTokenWithComment` is a string token that is preceded by comments.
 */
class StringTokenWithComment extends StringToken {
  /**
   * The first comment in the list of comments that precede this token.
   */
  final Token _precedingComment;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset] and to be preceded by the comments reachable from the given
   * [comment].
   */
  StringTokenWithComment(TokenType type, String value, int offset,
      this._precedingComment)
      : super(type, value, offset);

  @override
  Token get precedingComments => _precedingComment;

  @override
  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = _precedingComment;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }

  @override
  Token copy() =>
      new StringTokenWithComment(
          type,
          lexeme,
          offset,
          copyComments(_precedingComment));
}

/**
 * A `SubSequenceReader` is a [CharacterReader] that reads characters from a
 * character sequence, but adds a delta when reporting the current character
 * offset so that the character sequence can be a subsequence from a larger
 * sequence.
 */
class SubSequenceReader extends CharSequenceReader {
  /**
   * The offset from the beginning of the file to the beginning of the source
   * being scanned.
   */
  final int _offsetDelta;

  /**
   * Initialize a newly created reader to read the characters in the given
   * [sequence]. The [_offsetDelta] is the offset from the beginning of the file
   * to the beginning of the source being scanned
   */
  SubSequenceReader(String sequence, this._offsetDelta) : super(sequence);

  @override
  int get offset => _offsetDelta + super.offset;

  @override
  void set offset(int offset) {
    super.offset = offset - _offsetDelta;
  }

  @override
  String getString(int start, int endDelta) =>
      super.getString(start - _offsetDelta, endDelta);
}

/**
 * A `SyntheticStringToken` is a token whose value is independent of it's type.
 */
class SyntheticStringToken extends StringToken {
  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  SyntheticStringToken(TokenType type, String value, int offset)
      : super(type, value, offset);

  @override
  bool get isSynthetic => true;
}

/**
 * Instances of the class `Token` represent a token that was scanned from the
 * input. Each token knows which tokens preceed and follow it, acting as a link
 * in a doubly linked list of tokens.
 */
class Token {
  /**
   * The type of the token.
   */
  final TokenType type;

  /**
   * The offset from the beginning of the file to the first character in the
   * token.
   */
  int offset = 0;

  /**
   * The previous token in the token stream.
   */
  Token previous;

  /**
   * The next token in the token stream.
   */
  Token _next;

  /**
   * Initialize a newly created token to have the given [type] and [offset].
   */
  Token(this.type, int offset) {
    this.offset = offset;
  }

  /**
   * Return the offset from the beginning of the file to the character after the
   * last character of the token.
   */
  int get end => offset + length;

  /**
   * Return `true` if this token represents an operator.
   */
  bool get isOperator => type.isOperator;

  /**
   * Return `true` if this token is a synthetic token. A synthetic token is a
   * token that was introduced by the parser in order to recover from an error
   * in the code.
   */
  bool get isSynthetic => length == 0;

  /**
   * Return `true` if this token represents an operator that can be defined by
   * users.
   */
  bool get isUserDefinableOperator => type.isUserDefinableOperator;

  /**
   * Return the number of characters in the node's source range.
   */
  int get length => lexeme.length;

  /**
   * Return the lexeme that represents this token.
   */
  String get lexeme => type.lexeme;

  /**
   * Return the next token in the token stream.
   */
  Token get next => _next;

  /**
   * Return the first comment in the list of comments that precede this token,
   * or `null` if there are no comments preceding this token. Additional
   * comments can be reached by following the token stream using [next] until
   * `null` is returned.
   *
   * For example, if the original contents were "/* one */ /* two */ id", then
   * the first precceding comment token will have a lexeme of "/* one */" and
   * the next comment token will have a lexeme of "/* two */".
   */
  Token get precedingComments => null;

  /**
   * Apply (add) the given [delta] to this token's offset.
   */
  void applyDelta(int delta) {
    offset += delta;
  }

  /**
   * Return a newly created token that is a copy of this token but that is not a
   * part of any token stream.
   */
  Token copy() => new Token(type, offset);

  /**
   * Copy a linked list of comment tokens identical to the given comment tokens.
   */
  Token copyComments(Token token) {
    if (token == null) {
      return null;
    }
    Token head = token.copy();
    Token tail = head;
    token = token.next;
    while (token != null) {
      tail = tail.setNext(token.copy());
      token = token.next;
    }
    return head;
  }

  /**
   * Return `true` if this token has any one of the given [types].
   */
  bool matchesAny(List<TokenType> types) {
    for (TokenType type in types) {
      if (this.type == type) {
        return true;
      }
    }
    return false;
  }

  /**
   * Set the next token in the token stream to the given [token]. This has the
   * side-effect of setting this token to be the previous token for the given
   * token. Return the token that was passed in.
   */
  Token setNext(Token token) {
    _next = token;
    token.previous = this;
    return token;
  }

  /**
   * Set the next token in the token stream to the given token without changing
   * which token is the previous token for the given token. Return the token
   * that was passed in.
   */
  Token setNextWithoutSettingPrevious(Token token) {
    _next = token;
    return token;
  }

  @override
  String toString() => lexeme;

  /**
   * Return the value of this token. For keyword tokens, this is the keyword
   * associated with the token, for other tokens it is the lexeme associated
   * with the token.
   */
  Object value() => type.lexeme;

  /**
   * Compare the given [tokens] to find the token that appears first in the
   * source being parsed. That is, return the left-most of all of the tokens.
   * The list must be non-`null`, but the elements of the list are allowed to be
   * `null`. Return the token with the smallest offset, or `null` if the list is
   * empty or if all of the elements of the list are `null`.
   */
  static Token lexicallyFirst(List<Token> tokens) {
    Token first = null;
    int offset = -1;
    for (Token token in tokens) {
      if (token != null && (offset < 0 || token.offset < offset)) {
        first = token;
        offset = token.offset;
      }
    }
    return first;
  }
}

/**
 * The enumeration `TokenClass` represents classes (or groups) of tokens with a
 * similar use.
 */
class TokenClass {
  /**
   * A value used to indicate that the token type is not part of any specific
   * class of token.
   */
  static const TokenClass NO_CLASS = const TokenClass('NO_CLASS');

  /**
   * A value used to indicate that the token type is an additive operator.
   */
  static const TokenClass ADDITIVE_OPERATOR =
      const TokenClass('ADDITIVE_OPERATOR', 12);

  /**
   * A value used to indicate that the token type is an assignment operator.
   */
  static const TokenClass ASSIGNMENT_OPERATOR =
      const TokenClass('ASSIGNMENT_OPERATOR', 1);

  /**
   * A value used to indicate that the token type is a bitwise-and operator.
   */
  static const TokenClass BITWISE_AND_OPERATOR =
      const TokenClass('BITWISE_AND_OPERATOR', 10);

  /**
   * A value used to indicate that the token type is a bitwise-or operator.
   */
  static const TokenClass BITWISE_OR_OPERATOR =
      const TokenClass('BITWISE_OR_OPERATOR', 8);

  /**
   * A value used to indicate that the token type is a bitwise-xor operator.
   */
  static const TokenClass BITWISE_XOR_OPERATOR =
      const TokenClass('BITWISE_XOR_OPERATOR', 9);

  /**
   * A value used to indicate that the token type is a cascade operator.
   */
  static const TokenClass CASCADE_OPERATOR =
      const TokenClass('CASCADE_OPERATOR', 2);

  /**
   * A value used to indicate that the token type is a conditional operator.
   */
  static const TokenClass CONDITIONAL_OPERATOR =
      const TokenClass('CONDITIONAL_OPERATOR', 3);

  /**
   * A value used to indicate that the token type is an equality operator.
   */
  static const TokenClass EQUALITY_OPERATOR =
      const TokenClass('EQUALITY_OPERATOR', 6);

  /**
   * A value used to indicate that the token type is a logical-and operator.
   */
  static const TokenClass LOGICAL_AND_OPERATOR =
      const TokenClass('LOGICAL_AND_OPERATOR', 5);

  /**
   * A value used to indicate that the token type is a logical-or operator.
   */
  static const TokenClass LOGICAL_OR_OPERATOR =
      const TokenClass('LOGICAL_OR_OPERATOR', 4);

  /**
   * A value used to indicate that the token type is a multiplicative operator.
   */
  static const TokenClass MULTIPLICATIVE_OPERATOR =
      const TokenClass('MULTIPLICATIVE_OPERATOR', 13);

  /**
   * A value used to indicate that the token type is a relational operator.
   */
  static const TokenClass RELATIONAL_OPERATOR =
      const TokenClass('RELATIONAL_OPERATOR', 7);

  /**
   * A value used to indicate that the token type is a shift operator.
   */
  static const TokenClass SHIFT_OPERATOR =
      const TokenClass('SHIFT_OPERATOR', 11);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static const TokenClass UNARY_POSTFIX_OPERATOR =
      const TokenClass('UNARY_POSTFIX_OPERATOR', 15);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static const TokenClass UNARY_PREFIX_OPERATOR =
      const TokenClass('UNARY_PREFIX_OPERATOR', 14);

  /**
   * The name of the token class.
   */
  final String name;

  /**
   * The precedence of tokens of this class, or `0` if the such tokens do not
   * represent an operator.
   */
  final int precedence;

  const TokenClass(this.name, [this.precedence = 0]);
}

/**
 * The enumeration `TokenType` defines the types of tokens that can be returned
 * by the scanner.
 */
class TokenType {
  /**
   * The type of the token that marks the end of the input.
   */
  static const TokenType EOF = const TokenType_EOF('EOF');

  static const TokenType DOUBLE = const TokenType('DOUBLE');

  static const TokenType HEXADECIMAL = const TokenType('HEXADECIMAL');

  static const TokenType IDENTIFIER = const TokenType('IDENTIFIER');

  static const TokenType INT = const TokenType('INT');

  static const TokenType KEYWORD = const TokenType('KEYWORD');

  static const TokenType MULTI_LINE_COMMENT =
      const TokenType('MULTI_LINE_COMMENT');

  static const TokenType SCRIPT_TAG = const TokenType('SCRIPT_TAG');

  static const TokenType SINGLE_LINE_COMMENT =
      const TokenType('SINGLE_LINE_COMMENT');

  static const TokenType STRING = const TokenType('STRING');

  static const TokenType AMPERSAND =
      const TokenType('AMPERSAND', TokenClass.BITWISE_AND_OPERATOR, "&");

  static const TokenType AMPERSAND_AMPERSAND =
      const TokenType('AMPERSAND_AMPERSAND', TokenClass.LOGICAL_AND_OPERATOR, "&&");

  static const TokenType AMPERSAND_EQ =
      const TokenType('AMPERSAND_EQ', TokenClass.ASSIGNMENT_OPERATOR, "&=");

  static const TokenType AT = const TokenType('AT', TokenClass.NO_CLASS, "@");

  static const TokenType BANG =
      const TokenType('BANG', TokenClass.UNARY_PREFIX_OPERATOR, "!");

  static const TokenType BANG_EQ =
      const TokenType('BANG_EQ', TokenClass.EQUALITY_OPERATOR, "!=");

  static const TokenType BAR =
      const TokenType('BAR', TokenClass.BITWISE_OR_OPERATOR, "|");

  static const TokenType BAR_BAR =
      const TokenType('BAR_BAR', TokenClass.LOGICAL_OR_OPERATOR, "||");

  static const TokenType BAR_EQ =
      const TokenType('BAR_EQ', TokenClass.ASSIGNMENT_OPERATOR, "|=");

  static const TokenType COLON =
      const TokenType('COLON', TokenClass.NO_CLASS, ":");

  static const TokenType COMMA =
      const TokenType('COMMA', TokenClass.NO_CLASS, ",");

  static const TokenType CARET =
      const TokenType('CARET', TokenClass.BITWISE_XOR_OPERATOR, "^");

  static const TokenType CARET_EQ =
      const TokenType('CARET_EQ', TokenClass.ASSIGNMENT_OPERATOR, "^=");

  static const TokenType CLOSE_CURLY_BRACKET =
      const TokenType('CLOSE_CURLY_BRACKET', TokenClass.NO_CLASS, "}");

  static const TokenType CLOSE_PAREN =
      const TokenType('CLOSE_PAREN', TokenClass.NO_CLASS, ")");

  static const TokenType CLOSE_SQUARE_BRACKET =
      const TokenType('CLOSE_SQUARE_BRACKET', TokenClass.NO_CLASS, "]");

  static const TokenType EQ =
      const TokenType('EQ', TokenClass.ASSIGNMENT_OPERATOR, "=");

  static const TokenType EQ_EQ =
      const TokenType('EQ_EQ', TokenClass.EQUALITY_OPERATOR, "==");

  static const TokenType FUNCTION =
      const TokenType('FUNCTION', TokenClass.NO_CLASS, "=>");

  static const TokenType GT =
      const TokenType('GT', TokenClass.RELATIONAL_OPERATOR, ">");

  static const TokenType GT_EQ =
      const TokenType('GT_EQ', TokenClass.RELATIONAL_OPERATOR, ">=");

  static const TokenType GT_GT =
      const TokenType('GT_GT', TokenClass.SHIFT_OPERATOR, ">>");

  static const TokenType GT_GT_EQ =
      const TokenType('GT_GT_EQ', TokenClass.ASSIGNMENT_OPERATOR, ">>=");

  static const TokenType HASH =
      const TokenType('HASH', TokenClass.NO_CLASS, "#");

  static const TokenType INDEX =
      const TokenType('INDEX', TokenClass.UNARY_POSTFIX_OPERATOR, "[]");

  static const TokenType INDEX_EQ =
      const TokenType('INDEX_EQ', TokenClass.UNARY_POSTFIX_OPERATOR, "[]=");

  static const TokenType IS =
      const TokenType('IS', TokenClass.RELATIONAL_OPERATOR, "is");

  static const TokenType LT =
      const TokenType('LT', TokenClass.RELATIONAL_OPERATOR, "<");

  static const TokenType LT_EQ =
      const TokenType('LT_EQ', TokenClass.RELATIONAL_OPERATOR, "<=");

  static const TokenType LT_LT =
      const TokenType('LT_LT', TokenClass.SHIFT_OPERATOR, "<<");

  static const TokenType LT_LT_EQ =
      const TokenType('LT_LT_EQ', TokenClass.ASSIGNMENT_OPERATOR, "<<=");

  static const TokenType MINUS =
      const TokenType('MINUS', TokenClass.ADDITIVE_OPERATOR, "-");

  static const TokenType MINUS_EQ =
      const TokenType('MINUS_EQ', TokenClass.ASSIGNMENT_OPERATOR, "-=");

  static const TokenType MINUS_MINUS =
      const TokenType('MINUS_MINUS', TokenClass.UNARY_PREFIX_OPERATOR, "--");

  static const TokenType OPEN_CURLY_BRACKET =
      const TokenType('OPEN_CURLY_BRACKET', TokenClass.NO_CLASS, "{");

  static const TokenType OPEN_PAREN =
      const TokenType('OPEN_PAREN', TokenClass.UNARY_POSTFIX_OPERATOR, "(");

  static const TokenType OPEN_SQUARE_BRACKET =
      const TokenType('OPEN_SQUARE_BRACKET', TokenClass.UNARY_POSTFIX_OPERATOR, "[");

  static const TokenType PERCENT =
      const TokenType('PERCENT', TokenClass.MULTIPLICATIVE_OPERATOR, "%");

  static const TokenType PERCENT_EQ =
      const TokenType('PERCENT_EQ', TokenClass.ASSIGNMENT_OPERATOR, "%=");

  static const TokenType PERIOD =
      const TokenType('PERIOD', TokenClass.UNARY_POSTFIX_OPERATOR, ".");

  static const TokenType PERIOD_PERIOD =
      const TokenType('PERIOD_PERIOD', TokenClass.CASCADE_OPERATOR, "..");

  static const TokenType PLUS =
      const TokenType('PLUS', TokenClass.ADDITIVE_OPERATOR, "+");

  static const TokenType PLUS_EQ =
      const TokenType('PLUS_EQ', TokenClass.ASSIGNMENT_OPERATOR, "+=");

  static const TokenType PLUS_PLUS =
      const TokenType('PLUS_PLUS', TokenClass.UNARY_PREFIX_OPERATOR, "++");

  static const TokenType QUESTION =
      const TokenType('QUESTION', TokenClass.CONDITIONAL_OPERATOR, "?");

  static const TokenType SEMICOLON =
      const TokenType('SEMICOLON', TokenClass.NO_CLASS, ";");

  static const TokenType SLASH =
      const TokenType('SLASH', TokenClass.MULTIPLICATIVE_OPERATOR, "/");

  static const TokenType SLASH_EQ =
      const TokenType('SLASH_EQ', TokenClass.ASSIGNMENT_OPERATOR, "/=");

  static const TokenType STAR =
      const TokenType('STAR', TokenClass.MULTIPLICATIVE_OPERATOR, "*");

  static const TokenType STAR_EQ =
      const TokenType('STAR_EQ', TokenClass.ASSIGNMENT_OPERATOR, "*=");

  static const TokenType STRING_INTERPOLATION_EXPRESSION =
      const TokenType('STRING_INTERPOLATION_EXPRESSION', TokenClass.NO_CLASS, "\${");

  static const TokenType STRING_INTERPOLATION_IDENTIFIER =
      const TokenType('STRING_INTERPOLATION_IDENTIFIER', TokenClass.NO_CLASS, "\$");

  static const TokenType TILDE =
      const TokenType('TILDE', TokenClass.UNARY_PREFIX_OPERATOR, "~");

  static const TokenType TILDE_SLASH =
      const TokenType('TILDE_SLASH', TokenClass.MULTIPLICATIVE_OPERATOR, "~/");

  static const TokenType TILDE_SLASH_EQ =
      const TokenType('TILDE_SLASH_EQ', TokenClass.ASSIGNMENT_OPERATOR, "~/=");

  static const TokenType BACKPING =
      const TokenType('BACKPING', TokenClass.NO_CLASS, "`");

  static const TokenType BACKSLASH =
      const TokenType('BACKSLASH', TokenClass.NO_CLASS, "\\");

  static const TokenType PERIOD_PERIOD_PERIOD =
      const TokenType('PERIOD_PERIOD_PERIOD', TokenClass.NO_CLASS, "...");

  /**
   * The class of the token.
   */
  final TokenClass _tokenClass;

  /**
   * The name of the token type.
   */
  final String name;

  /**
   * The lexeme that defines this type of token, or `null` if there is more than
   * one possible lexeme for this type of token.
   */
  final String lexeme;

  const TokenType(this.name, [this._tokenClass = TokenClass.NO_CLASS,
      this.lexeme = null]);

  /**
   * Return `true` if this type of token represents an additive operator.
   */
  bool get isAdditiveOperator => _tokenClass == TokenClass.ADDITIVE_OPERATOR;

  /**
   * Return `true` if this type of token represents an assignment operator.
   */
  bool get isAssignmentOperator =>
      _tokenClass == TokenClass.ASSIGNMENT_OPERATOR;

  /**
   * Return `true` if this type of token represents an associative operator. An
   * associative operator is an operator for which the following equality is
   * true: `(a * b) * c == a * (b * c)`. In other words, if the result of
   * applying the operator to multiple operands does not depend on the order in
   * which those applications occur.
   *
   * Note: This method considers the logical-and and logical-or operators to be
   * associative, even though the order in which the application of those
   * operators can have an effect because evaluation of the right-hand operand
   * is conditional.
   */
  bool get isAssociativeOperator =>
      this == AMPERSAND ||
          this == AMPERSAND_AMPERSAND ||
          this == BAR ||
          this == BAR_BAR ||
          this == CARET ||
          this == PLUS ||
          this == STAR;

  /**
   * Return `true` if this type of token represents an equality operator.
   */
  bool get isEqualityOperator => _tokenClass == TokenClass.EQUALITY_OPERATOR;

  /**
   * Return `true` if this type of token represents an increment operator.
   */
  bool get isIncrementOperator =>
      identical(lexeme, "++") || identical(lexeme, "--");

  /**
   * Return `true` if this type of token represents a multiplicative operator.
   */
  bool get isMultiplicativeOperator =>
      _tokenClass == TokenClass.MULTIPLICATIVE_OPERATOR;

  /**
   * Return `true` if this token type represents an operator.
   */
  bool get isOperator =>
      _tokenClass != TokenClass.NO_CLASS &&
          this != OPEN_PAREN &&
          this != OPEN_SQUARE_BRACKET &&
          this != PERIOD;

  /**
   * Return `true` if this type of token represents a relational operator.
   */
  bool get isRelationalOperator =>
      _tokenClass == TokenClass.RELATIONAL_OPERATOR;

  /**
   * Return `true` if this type of token represents a shift operator.
   */
  bool get isShiftOperator => _tokenClass == TokenClass.SHIFT_OPERATOR;

  /**
   * Return `true` if this type of token represents a unary postfix operator.
   */
  bool get isUnaryPostfixOperator =>
      _tokenClass == TokenClass.UNARY_POSTFIX_OPERATOR;

  /**
   * Return `true` if this type of token represents a unary prefix operator.
   */
  bool get isUnaryPrefixOperator =>
      _tokenClass == TokenClass.UNARY_PREFIX_OPERATOR;

  /**
   * Return `true` if this token type represents an operator that can be defined
   * by users.
   */
  bool get isUserDefinableOperator =>
      identical(lexeme, "==") ||
          identical(lexeme, "~") ||
          identical(lexeme, "[]") ||
          identical(lexeme, "[]=") ||
          identical(lexeme, "*") ||
          identical(lexeme, "/") ||
          identical(lexeme, "%") ||
          identical(lexeme, "~/") ||
          identical(lexeme, "+") ||
          identical(lexeme, "-") ||
          identical(lexeme, "<<") ||
          identical(lexeme, ">>") ||
          identical(lexeme, ">=") ||
          identical(lexeme, ">") ||
          identical(lexeme, "<=") ||
          identical(lexeme, "<") ||
          identical(lexeme, "&") ||
          identical(lexeme, "^") ||
          identical(lexeme, "|");

  /**
   * Return the precedence of the token, or `0` if the token does not represent
   * an operator.
   */
  int get precedence => _tokenClass.precedence;
}

class TokenType_EOF extends TokenType {
  const TokenType_EOF(String name) : super(name, TokenClass.NO_CLASS, "");

  @override
  String toString() => "-eof-";
}

/**
 * A `TokenWithComment` is a normal token that is preceded by comments.
 */
class TokenWithComment extends Token {
  /**
   * The first comment in the list of comments that precede this token.
   */
  final Token _precedingComment;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset] and to be preceded by the comments reachable from the given
   * [comment].
   */
  TokenWithComment(TokenType type, int offset, this._precedingComment)
      : super(type, offset);

  @override
  Token get precedingComments => _precedingComment;

  @override
  Token copy() => new TokenWithComment(type, offset, _precedingComment);
}
