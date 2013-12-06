// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.scanner;

import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'source.dart';
import 'error.dart';
import 'instrumentation.dart';
import 'utilities_collection.dart' show TokenMap;

/**
 * Instances of the abstract class `KeywordState` represent a state in a state machine used to
 * scan keywords.
 *
 * @coverage dart.engine.parser
 */
class KeywordState {
  /**
   * An empty transition table used by leaf states.
   */
  static List<KeywordState> _EMPTY_TABLE = new List<KeywordState>(26);

  /**
   * The initial state in the state machine.
   */
  static KeywordState KEYWORD_STATE = createKeywordStateTable();

  /**
   * Create the next state in the state machine where we have already recognized the subset of
   * strings in the given array of strings starting at the given offset and having the given length.
   * All of these strings have a common prefix and the next character is at the given start index.
   *
   * @param start the index of the character in the strings used to transition to a new state
   * @param strings an array containing all of the strings that will be recognized by the state
   *          machine
   * @param offset the offset of the first string in the array that has the prefix that is assumed
   *          to have been recognized by the time we reach the state being built
   * @param length the number of strings in the array that pass through the state being built
   * @return the state that was created
   */
  static KeywordState computeKeywordStateTable(int start, List<String> strings, int offset, int length) {
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
            result[chunk - 0x61] = computeKeywordStateTable(start + 1, strings, chunkStart, i - chunkStart);
          }
          chunkStart = i;
          chunk = c;
        }
      }
    }
    if (chunkStart != -1) {
      assert(result[chunk - 0x61] == null);
      result[chunk - 0x61] = computeKeywordStateTable(start + 1, strings, chunkStart, offset + length - chunkStart);
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
   * Create the initial state in the state machine.
   *
   * @return the state that was created
   */
  static KeywordState createKeywordStateTable() {
    List<Keyword> values = Keyword.values;
    List<String> strings = new List<String>(values.length);
    for (int i = 0; i < values.length; i++) {
      strings[i] = values[i].syntax;
    }
    strings.sort();
    return computeKeywordStateTable(0, strings, 0, strings.length);
  }

  /**
   * A table mapping characters to the states to which those characters will transition. (The index
   * into the array is the offset from the character `'a'` to the transitioning character.)
   */
  List<KeywordState> _table;

  /**
   * The keyword that is recognized by this state, or `null` if this state is not a terminal
   * state.
   */
  Keyword _keyword2;

  /**
   * Initialize a newly created state to have the given transitions and to recognize the keyword
   * with the given syntax.
   *
   * @param table a table mapping characters to the states to which those characters will transition
   * @param syntax the syntax of the keyword that is recognized by the state
   */
  KeywordState(List<KeywordState> table, String syntax) {
    this._table = table;
    this._keyword2 = (syntax == null) ? null : Keyword.keywords[syntax];
  }

  /**
   * Return the keyword that was recognized by this state, or `null` if this state does not
   * recognized a keyword.
   *
   * @return the keyword that was matched by reaching this state
   */
  Keyword keyword() => _keyword2;

  /**
   * Return the state that follows this state on a transition of the given character, or
   * `null` if there is no valid state reachable from this state with such a transition.
   *
   * @param c the character used to transition from this state to another state
   * @return the state that follows this state on a transition of the given character
   */
  KeywordState next(int c) => _table[c - 0x61];
}

/**
 * The enumeration `ScannerErrorCode` defines the error codes used for errors detected by the
 * scanner.
 *
 * @coverage dart.engine.parser
 */
class ScannerErrorCode extends Enum<ScannerErrorCode> implements ErrorCode {
  static final ScannerErrorCode ILLEGAL_CHARACTER = new ScannerErrorCode.con1('ILLEGAL_CHARACTER', 0, "Illegal character %x");

  static final ScannerErrorCode MISSING_DIGIT = new ScannerErrorCode.con1('MISSING_DIGIT', 1, "Decimal digit expected");

  static final ScannerErrorCode MISSING_HEX_DIGIT = new ScannerErrorCode.con1('MISSING_HEX_DIGIT', 2, "Hexidecimal digit expected");

  static final ScannerErrorCode MISSING_QUOTE = new ScannerErrorCode.con1('MISSING_QUOTE', 3, "Expected quote (' or \")");

  static final ScannerErrorCode UNTERMINATED_MULTI_LINE_COMMENT = new ScannerErrorCode.con1('UNTERMINATED_MULTI_LINE_COMMENT', 4, "Unterminated multi-line comment");

  static final ScannerErrorCode UNTERMINATED_STRING_LITERAL = new ScannerErrorCode.con1('UNTERMINATED_STRING_LITERAL', 5, "Unterminated string literal");

  static final List<ScannerErrorCode> values = [
      ILLEGAL_CHARACTER,
      MISSING_DIGIT,
      MISSING_HEX_DIGIT,
      MISSING_QUOTE,
      UNTERMINATED_MULTI_LINE_COMMENT,
      UNTERMINATED_STRING_LITERAL];

  /**
   * The template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  String correction10;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for this error
   */
  ScannerErrorCode.con1(String name, int ordinal, String message) : super(name, ordinal) {
    this._message = message;
  }

  /**
   * Initialize a newly created error code to have the given message and correction.
   *
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  ScannerErrorCode.con2(String name, int ordinal, String message, String correction) : super(name, ordinal) {
    this._message = message;
    this.correction10 = correction;
  }

  String get correction => correction10;

  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  String get message => _message;

  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}

/**
 * Instances of the class `SubSequenceReader` implement a [CharacterReader] that reads
 * characters from a character sequence, but adds a delta when reporting the current character
 * offset so that the character sequence can be a subsequence from a larger sequence.
 */
class SubSequenceReader extends CharSequenceReader {
  /**
   * The offset from the beginning of the file to the beginning of the source being scanned.
   */
  int _offsetDelta = 0;

  /**
   * Initialize a newly created reader to read the characters in the given sequence.
   *
   * @param sequence the sequence from which characters will be read
   * @param offsetDelta the offset from the beginning of the file to the beginning of the source
   *          being scanned
   */
  SubSequenceReader(CharSequence sequence, int offsetDelta) : super(sequence) {
    this._offsetDelta = offsetDelta;
  }

  int get offset => _offsetDelta + super.offset;

  String getString(int start, int endDelta) => super.getString(start - _offsetDelta, endDelta);

  void set offset(int offset) {
    super.offset = offset - _offsetDelta;
  }
}

/**
 * Instances of the class `TokenWithComment` represent a string token that is preceded by
 * comments.
 *
 * @coverage dart.engine.parser
 */
class StringTokenWithComment extends StringToken {
  /**
   * The first comment in the list of comments that precede this token.
   */
  Token _precedingComment;

  /**
   * Initialize a newly created token to have the given type and offset and to be preceded by the
   * comments reachable from the given comment.
   *
   * @param type the type of the token
   * @param offset the offset from the beginning of the file to the first character in the token
   * @param precedingComment the first comment in the list of comments that precede this token
   */
  StringTokenWithComment(TokenType type, String value, int offset, Token precedingComment) : super(type, value, offset) {
    this._precedingComment = precedingComment;
  }

  Token copy() => new StringTokenWithComment(type, lexeme, offset, copyComments(_precedingComment));

  Token get precedingComments => _precedingComment;

  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = _precedingComment;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }
}

/**
 * The enumeration `Keyword` defines the keywords in the Dart programming language.
 *
 * @coverage dart.engine.parser
 */
class Keyword extends Enum<Keyword> {
  static final Keyword ASSERT = new Keyword.con1('ASSERT', 0, "assert");

  static final Keyword BREAK = new Keyword.con1('BREAK', 1, "break");

  static final Keyword CASE = new Keyword.con1('CASE', 2, "case");

  static final Keyword CATCH = new Keyword.con1('CATCH', 3, "catch");

  static final Keyword CLASS = new Keyword.con1('CLASS', 4, "class");

  static final Keyword CONST = new Keyword.con1('CONST', 5, "const");

  static final Keyword CONTINUE = new Keyword.con1('CONTINUE', 6, "continue");

  static final Keyword DEFAULT = new Keyword.con1('DEFAULT', 7, "default");

  static final Keyword DO = new Keyword.con1('DO', 8, "do");

  static final Keyword ELSE = new Keyword.con1('ELSE', 9, "else");

  static final Keyword ENUM = new Keyword.con1('ENUM', 10, "enum");

  static final Keyword EXTENDS = new Keyword.con1('EXTENDS', 11, "extends");

  static final Keyword FALSE = new Keyword.con1('FALSE', 12, "false");

  static final Keyword FINAL = new Keyword.con1('FINAL', 13, "final");

  static final Keyword FINALLY = new Keyword.con1('FINALLY', 14, "finally");

  static final Keyword FOR = new Keyword.con1('FOR', 15, "for");

  static final Keyword IF = new Keyword.con1('IF', 16, "if");

  static final Keyword IN = new Keyword.con1('IN', 17, "in");

  static final Keyword IS = new Keyword.con1('IS', 18, "is");

  static final Keyword NEW = new Keyword.con1('NEW', 19, "new");

  static final Keyword NULL = new Keyword.con1('NULL', 20, "null");

  static final Keyword RETHROW = new Keyword.con1('RETHROW', 21, "rethrow");

  static final Keyword RETURN = new Keyword.con1('RETURN', 22, "return");

  static final Keyword SUPER = new Keyword.con1('SUPER', 23, "super");

  static final Keyword SWITCH = new Keyword.con1('SWITCH', 24, "switch");

  static final Keyword THIS = new Keyword.con1('THIS', 25, "this");

  static final Keyword THROW = new Keyword.con1('THROW', 26, "throw");

  static final Keyword TRUE = new Keyword.con1('TRUE', 27, "true");

  static final Keyword TRY = new Keyword.con1('TRY', 28, "try");

  static final Keyword VAR = new Keyword.con1('VAR', 29, "var");

  static final Keyword VOID = new Keyword.con1('VOID', 30, "void");

  static final Keyword WHILE = new Keyword.con1('WHILE', 31, "while");

  static final Keyword WITH = new Keyword.con1('WITH', 32, "with");

  static final Keyword ABSTRACT = new Keyword.con2('ABSTRACT', 33, "abstract", true);

  static final Keyword AS = new Keyword.con2('AS', 34, "as", true);

  static final Keyword DYNAMIC = new Keyword.con2('DYNAMIC', 35, "dynamic", true);

  static final Keyword EXPORT = new Keyword.con2('EXPORT', 36, "export", true);

  static final Keyword EXTERNAL = new Keyword.con2('EXTERNAL', 37, "external", true);

  static final Keyword FACTORY = new Keyword.con2('FACTORY', 38, "factory", true);

  static final Keyword GET = new Keyword.con2('GET', 39, "get", true);

  static final Keyword IMPLEMENTS = new Keyword.con2('IMPLEMENTS', 40, "implements", true);

  static final Keyword IMPORT = new Keyword.con2('IMPORT', 41, "import", true);

  static final Keyword LIBRARY = new Keyword.con2('LIBRARY', 42, "library", true);

  static final Keyword OPERATOR = new Keyword.con2('OPERATOR', 43, "operator", true);

  static final Keyword PART = new Keyword.con2('PART', 44, "part", true);

  static final Keyword SET = new Keyword.con2('SET', 45, "set", true);

  static final Keyword STATIC = new Keyword.con2('STATIC', 46, "static", true);

  static final Keyword TYPEDEF = new Keyword.con2('TYPEDEF', 47, "typedef", true);

  static final List<Keyword> values = [
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
   * The lexeme for the keyword.
   */
  String syntax;

  /**
   * A flag indicating whether the keyword is a pseudo-keyword. Pseudo keywords can be used as
   * identifiers.
   */
  bool isPseudoKeyword = false;

  /**
   * A table mapping the lexemes of keywords to the corresponding keyword.
   */
  static Map<String, Keyword> keywords = createKeywordMap();

  /**
   * Create a table mapping the lexemes of keywords to the corresponding keyword.
   *
   * @return the table that was created
   */
  static Map<String, Keyword> createKeywordMap() {
    LinkedHashMap<String, Keyword> result = new LinkedHashMap<String, Keyword>();
    for (Keyword keyword in values) {
      result[keyword.syntax] = keyword;
    }
    return result;
  }

  /**
   * Initialize a newly created keyword to have the given syntax. The keyword is not a
   * pseudo-keyword.
   *
   * @param syntax the lexeme for the keyword
   */
  Keyword.con1(String name, int ordinal, String syntax) : this.con2(name, ordinal, syntax, false);

  /**
   * Initialize a newly created keyword to have the given syntax. The keyword is a pseudo-keyword if
   * the given flag is `true`.
   *
   * @param syntax the lexeme for the keyword
   * @param isPseudoKeyword `true` if this keyword is a pseudo-keyword
   */
  Keyword.con2(String name, int ordinal, String syntax, bool isPseudoKeyword) : super(name, ordinal) {
    this.syntax = syntax;
    this.isPseudoKeyword = isPseudoKeyword;
  }
}

/**
 * Instances of the class `CharSequenceReader` implement a [CharacterReader] that reads
 * characters from a character sequence.
 */
class CharSequenceReader implements CharacterReader {
  /**
   * The sequence from which characters will be read.
   */
  CharSequence _sequence;

  /**
   * The number of characters in the string.
   */
  int _stringLength = 0;

  /**
   * The index, relative to the string, of the last character that was read.
   */
  int _charOffset = 0;

  /**
   * Initialize a newly created reader to read the characters in the given sequence.
   *
   * @param sequence the sequence from which characters will be read
   */
  CharSequenceReader(CharSequence sequence) {
    this._sequence = sequence;
    this._stringLength = sequence.length();
    this._charOffset = -1;
  }

  int advance() {
    if (_charOffset + 1 >= _stringLength) {
      return -1;
    }
    return _sequence.charAt(++_charOffset);
  }

  int get offset => _charOffset;

  String getString(int start, int endDelta) => _sequence.subSequence(start, _charOffset + 1 + endDelta).toString();

  int peek() {
    if (_charOffset + 1 >= _sequence.length()) {
      return -1;
    }
    return _sequence.charAt(_charOffset + 1);
  }

  void set offset(int offset) {
    _charOffset = offset;
  }
}

/**
 * Synthetic `StringToken` represent a token whose value is independent of it's type.
 *
 * @coverage dart.engine.parser
 */
class SyntheticStringToken extends StringToken {
  /**
   * Initialize a newly created token to represent a token of the given type with the given value.
   *
   * @param type the type of the token
   * @param value the lexeme represented by this token
   * @param offset the offset from the beginning of the file to the first character in the token
   */
  SyntheticStringToken(TokenType type, String value, int offset) : super(type, value, offset);

  bool get isSynthetic => true;
}

/**
 * Instances of the class `IncrementalScanner` implement a scanner that scans a subset of a
 * string and inserts the resulting tokens into the middle of an existing token stream.
 *
 * @coverage dart.engine.parser
 */
class IncrementalScanner extends Scanner {
  /**
   * The reader used to access the characters in the source.
   */
  CharacterReader _reader;

  /**
   * A map from tokens that were copied to the copies of the tokens.
   */
  final TokenMap tokenMap = new TokenMap();

  /**
   * The token in the new token stream immediately to the left of the range of tokens that were
   * inserted, or the token immediately to the left of the modified region if there were no new
   * tokens.
   */
  Token leftToken;

  /**
   * The token in the new token stream immediately to the right of the range of tokens that were
   * inserted, or the token immediately to the right of the modified region if there were no new
   * tokens.
   */
  Token rightToken;

  /**
   * A flag indicating whether there were any tokens changed as a result of the modification.
   */
  bool _hasNonWhitespaceChange2 = false;

  /**
   * Initialize a newly created scanner.
   *
   * @param source the source being scanned
   * @param reader the character reader used to read the characters in the source
   * @param errorListener the error listener that will be informed of any errors that are found
   */
  IncrementalScanner(Source source, CharacterReader reader, AnalysisErrorListener errorListener) : super(source, reader, errorListener) {
    this._reader = reader;
  }

  /**
   * Return `true` if there were any tokens either added or removed (or both) as a result of
   * the modification.
   *
   * @return `true` if there were any tokens changed as a result of the modification
   */
  bool hasNonWhitespaceChange() => _hasNonWhitespaceChange2;

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
  Token rescan(Token originalStream, int index, int removedLength, int insertedLength) {
    while (originalStream.type != TokenType.EOF && originalStream.end < index) {
      originalStream = copyAndAdvance(originalStream, 0);
    }
    Token oldFirst = originalStream;
    Token oldLeftToken = originalStream.previous;
    leftToken = tail;
    int removedEnd = index + (removedLength == 0 ? 0 : removedLength - 1);
    while (originalStream.type != TokenType.EOF && originalStream.offset <= removedEnd) {
      originalStream = originalStream.next;
    }
    Token oldLast;
    Token oldRightToken;
    if (originalStream.type != TokenType.EOF && removedEnd + 1 == originalStream.offset) {
      oldLast = originalStream;
      originalStream = originalStream.next;
      oldRightToken = originalStream;
    } else {
      oldLast = originalStream.previous;
      oldRightToken = originalStream;
    }
    int delta = insertedLength - removedLength;
    int scanStart = Math.min(oldFirst.offset, index);
    int oldEnd = oldLast.end + delta - 1;
    int newEnd = index + insertedLength - 1;
    int scanEnd = Math.max(newEnd, oldEnd);
    _reader.offset = scanStart - 1;
    int next = _reader.advance();
    while (next != -1 && _reader.offset <= scanEnd) {
      next = bigSwitch(next);
    }
    if (identical(originalStream.type, TokenType.EOF)) {
      copyAndAdvance(originalStream, delta);
      rightToken = tail;
      rightToken.setNextWithoutSettingPrevious(rightToken);
    } else {
      originalStream = copyAndAdvance(originalStream, delta);
      rightToken = tail;
      while (originalStream.type != TokenType.EOF) {
        originalStream = copyAndAdvance(originalStream, delta);
      }
      Token eof = copyAndAdvance(originalStream, delta);
      eof.setNextWithoutSettingPrevious(eof);
    }
    Token newFirst = leftToken.next;
    while (newFirst != rightToken && oldFirst != oldRightToken && newFirst.type != TokenType.EOF && equals3(oldFirst, newFirst)) {
      tokenMap.put(oldFirst, newFirst);
      oldLeftToken = oldFirst;
      oldFirst = oldFirst.next;
      leftToken = newFirst;
      newFirst = newFirst.next;
    }
    Token newLast = rightToken.previous;
    while (newLast != leftToken && oldLast != oldLeftToken && newLast.type != TokenType.EOF && equals3(oldLast, newLast)) {
      tokenMap.put(oldLast, newLast);
      oldRightToken = oldLast;
      oldLast = oldLast.previous;
      rightToken = newLast;
      newLast = newLast.previous;
    }
    _hasNonWhitespaceChange2 = leftToken.next != rightToken || oldLeftToken.next != oldRightToken;
    return firstToken;
  }

  Token copyAndAdvance(Token originalToken, int delta) {
    Token copiedToken = originalToken.copy();
    tokenMap.put(originalToken, copiedToken);
    copiedToken.applyDelta(delta);
    appendToken(copiedToken);
    Token originalComment = originalToken.precedingComments;
    Token copiedComment = originalToken.precedingComments;
    while (originalComment != null) {
      tokenMap.put(originalComment, copiedComment);
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
  bool equals3(Token oldToken, Token newToken) => identical(oldToken.type, newToken.type) && oldToken.length == newToken.length && oldToken.lexeme == newToken.lexeme;
}

/**
 * The class `Scanner` implements a scanner for Dart code.
 *
 * The lexical structure of Dart is ambiguous without knowledge of the context in which a token is
 * being scanned. For example, without context we cannot determine whether source of the form "<<"
 * should be scanned as a single left-shift operator or as two left angle brackets. This scanner
 * does not have any context, so it always resolves such conflicts by scanning the longest possible
 * token.
 *
 * @coverage dart.engine.parser
 */
class Scanner {
  /**
   * The source being scanned.
   */
  Source source;

  /**
   * The reader used to access the characters in the source.
   */
  CharacterReader _reader;

  /**
   * The error listener that will be informed of any errors that are found during the scan.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The flag specifying if documentation comments should be parsed.
   */
  bool _preserveComments = true;

  /**
   * The token pointing to the head of the linked list of tokens.
   */
  Token _tokens;

  /**
   * The last token that was scanned.
   */
  Token tail;

  /**
   * The first token in the list of comment tokens found since the last non-comment token.
   */
  Token _firstComment;

  /**
   * The last token in the list of comment tokens found since the last non-comment token.
   */
  Token _lastComment;

  /**
   * The index of the first character of the current token.
   */
  int _tokenStart = 0;

  /**
   * A list containing the offsets of the first character of each line in the source code.
   */
  List<int> _lineStarts = new List<int>();

  /**
   * A list, treated something like a stack, of tokens representing the beginning of a matched pair.
   * It is used to pair the end tokens with the begin tokens.
   */
  List<BeginToken> _groupingStack = new List<BeginToken>();

  /**
   * The index of the last item in the [groupingStack], or `-1` if the stack is empty.
   */
  int _stackEnd = -1;

  /**
   * A flag indicating whether any unmatched groups were found during the parse.
   */
  bool _hasUnmatchedGroups2 = false;

  /**
   * Initialize a newly created scanner.
   *
   * @param source the source being scanned
   * @param reader the character reader used to read the characters in the source
   * @param errorListener the error listener that will be informed of any errors that are found
   */
  Scanner(Source source, CharacterReader reader, AnalysisErrorListener errorListener) {
    this.source = source;
    this._reader = reader;
    this._errorListener = errorListener;
    _tokens = new Token(TokenType.EOF, -1);
    _tokens.setNext(_tokens);
    tail = _tokens;
    _tokenStart = -1;
    _lineStarts.add(0);
  }

  /**
   * Return an array containing the offsets of the first character of each line in the source code.
   *
   * @return an array containing the offsets of the first character of each line in the source code
   */
  List<int> get lineStarts => _lineStarts;

  /**
   * Return `true` if any unmatched groups were found during the parse.
   *
   * @return `true` if any unmatched groups were found during the parse
   */
  bool hasUnmatchedGroups() => _hasUnmatchedGroups2;

  /**
   * Set whether documentation tokens should be scanned.
   *
   * @param preserveComments `true` if documentation tokens should be scanned
   */
  void set preserveComments(bool preserveComments) {
    this._preserveComments = preserveComments;
  }

  /**
   * Record that the source begins on the given line and column at the current offset as given by
   * the reader. The line starts for lines before the given line will not be correct.
   *
   * This method must be invoked at most one time and must be invoked before scanning begins. The
   * values provided must be sensible. The results are undefined if these conditions are violated.
   *
   * @param line the one-based index of the line containing the first character of the source
   * @param column the one-based index of the column in which the first character of the source
   *          occurs
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
   * Scan the source code to produce a list of tokens representing the source.
   *
   * @return the first token in the list of tokens that were produced
   */
  Token tokenize() {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.AbstractScanner.tokenize");
    int tokenCounter = 0;
    try {
      int next = _reader.advance();
      while (next != -1) {
        tokenCounter++;
        next = bigSwitch(next);
      }
      appendEofToken();
      instrumentation.metric2("tokensCount", tokenCounter);
      return firstToken;
    } finally {
      instrumentation.log2(2);
    }
  }

  /**
   * Append the given token to the end of the token stream being scanned. This method is intended to
   * be used by subclasses that copy existing tokens and should not normally be used because it will
   * fail to correctly associate any comments with the token being passed in.
   *
   * @param token the token to be appended
   */
  void appendToken(Token token) {
    tail = tail.setNext(token);
  }

  int bigSwitch(int next) {
    beginToken();
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
        return tokenizeString(_reader.advance(), start, true);
      }
    }
    if (0x61 <= next && next <= 0x7A) {
      return tokenizeKeywordOrIdentifier(next, true);
    }
    if ((0x41 <= next && next <= 0x5A) || next == 0x5F || next == 0x24) {
      return tokenizeIdentifier(next, _reader.offset, true);
    }
    if (next == 0x3C) {
      return tokenizeLessThan(next);
    }
    if (next == 0x3E) {
      return tokenizeGreaterThan(next);
    }
    if (next == 0x3D) {
      return tokenizeEquals(next);
    }
    if (next == 0x21) {
      return tokenizeExclamation(next);
    }
    if (next == 0x2B) {
      return tokenizePlus(next);
    }
    if (next == 0x2D) {
      return tokenizeMinus(next);
    }
    if (next == 0x2A) {
      return tokenizeMultiply(next);
    }
    if (next == 0x25) {
      return tokenizePercent(next);
    }
    if (next == 0x26) {
      return tokenizeAmpersand(next);
    }
    if (next == 0x7C) {
      return tokenizeBar(next);
    }
    if (next == 0x5E) {
      return tokenizeCaret(next);
    }
    if (next == 0x5B) {
      return tokenizeOpenSquareBracket(next);
    }
    if (next == 0x7E) {
      return tokenizeTilde(next);
    }
    if (next == 0x5C) {
      appendToken2(TokenType.BACKSLASH);
      return _reader.advance();
    }
    if (next == 0x23) {
      return tokenizeTag(next);
    }
    if (next == 0x28) {
      appendBeginToken(TokenType.OPEN_PAREN);
      return _reader.advance();
    }
    if (next == 0x29) {
      appendEndToken(TokenType.CLOSE_PAREN, TokenType.OPEN_PAREN);
      return _reader.advance();
    }
    if (next == 0x2C) {
      appendToken2(TokenType.COMMA);
      return _reader.advance();
    }
    if (next == 0x3A) {
      appendToken2(TokenType.COLON);
      return _reader.advance();
    }
    if (next == 0x3B) {
      appendToken2(TokenType.SEMICOLON);
      return _reader.advance();
    }
    if (next == 0x3F) {
      appendToken2(TokenType.QUESTION);
      return _reader.advance();
    }
    if (next == 0x5D) {
      appendEndToken(TokenType.CLOSE_SQUARE_BRACKET, TokenType.OPEN_SQUARE_BRACKET);
      return _reader.advance();
    }
    if (next == 0x60) {
      appendToken2(TokenType.BACKPING);
      return _reader.advance();
    }
    if (next == 0x7B) {
      appendBeginToken(TokenType.OPEN_CURLY_BRACKET);
      return _reader.advance();
    }
    if (next == 0x7D) {
      appendEndToken(TokenType.CLOSE_CURLY_BRACKET, TokenType.OPEN_CURLY_BRACKET);
      return _reader.advance();
    }
    if (next == 0x2F) {
      return tokenizeSlashOrComment(next);
    }
    if (next == 0x40) {
      appendToken2(TokenType.AT);
      return _reader.advance();
    }
    if (next == 0x22 || next == 0x27) {
      return tokenizeString(next, _reader.offset, false);
    }
    if (next == 0x2E) {
      return tokenizeDotOrNumber(next);
    }
    if (next == 0x30) {
      return tokenizeHexOrNumber(next);
    }
    if (0x31 <= next && next <= 0x39) {
      return tokenizeNumber(next);
    }
    if (next == -1) {
      return -1;
    }
    reportError(ScannerErrorCode.ILLEGAL_CHARACTER, [next]);
    return _reader.advance();
  }

  /**
   * Return the first token in the token stream that was scanned.
   *
   * @return the first token in the token stream that was scanned
   */
  Token get firstToken => _tokens.next;

  /**
   * Record the fact that we are at the beginning of a new line in the source.
   */
  void recordStartOfLine() {
    _lineStarts.add(_reader.offset);
  }

  void appendBeginToken(TokenType type) {
    BeginToken token;
    if (_firstComment == null) {
      token = new BeginToken(type, _tokenStart);
    } else {
      token = new BeginTokenWithComment(type, _tokenStart, _firstComment);
      _firstComment = null;
      _lastComment = null;
    }
    tail = tail.setNext(token);
    _groupingStack.add(token);
    _stackEnd++;
  }

  void appendCommentToken(TokenType type, String value) {
    if (!_preserveComments) {
      return;
    }
    if (_firstComment == null) {
      _firstComment = new StringToken(type, value, _tokenStart);
      _lastComment = _firstComment;
    } else {
      _lastComment = _lastComment.setNext(new StringToken(type, value, _tokenStart));
    }
  }

  void appendEndToken(TokenType type, TokenType beginType) {
    Token token;
    if (_firstComment == null) {
      token = new Token(type, _tokenStart);
    } else {
      token = new TokenWithComment(type, _tokenStart, _firstComment);
      _firstComment = null;
      _lastComment = null;
    }
    tail = tail.setNext(token);
    if (_stackEnd >= 0) {
      BeginToken begin = _groupingStack[_stackEnd];
      if (identical(begin.type, beginType)) {
        begin.endToken = token;
        _groupingStack.removeAt(_stackEnd--);
      }
    }
  }

  void appendEofToken() {
    Token eofToken;
    if (_firstComment == null) {
      eofToken = new Token(TokenType.EOF, _reader.offset + 1);
    } else {
      eofToken = new TokenWithComment(TokenType.EOF, _reader.offset + 1, _firstComment);
      _firstComment = null;
      _lastComment = null;
    }
    eofToken.setNext(eofToken);
    tail = tail.setNext(eofToken);
    if (_stackEnd >= 0) {
      _hasUnmatchedGroups2 = true;
    }
  }

  void appendKeywordToken(Keyword keyword) {
    if (_firstComment == null) {
      tail = tail.setNext(new KeywordToken(keyword, _tokenStart));
    } else {
      tail = tail.setNext(new KeywordTokenWithComment(keyword, _tokenStart, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void appendStringToken(TokenType type, String value) {
    if (_firstComment == null) {
      tail = tail.setNext(new StringToken(type, value, _tokenStart));
    } else {
      tail = tail.setNext(new StringTokenWithComment(type, value, _tokenStart, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void appendStringToken2(TokenType type, String value, int offset) {
    if (_firstComment == null) {
      tail = tail.setNext(new StringToken(type, value, _tokenStart + offset));
    } else {
      tail = tail.setNext(new StringTokenWithComment(type, value, _tokenStart + offset, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void appendToken2(TokenType type) {
    if (_firstComment == null) {
      tail = tail.setNext(new Token(type, _tokenStart));
    } else {
      tail = tail.setNext(new TokenWithComment(type, _tokenStart, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void appendToken3(TokenType type, int offset) {
    if (_firstComment == null) {
      tail = tail.setNext(new Token(type, offset));
    } else {
      tail = tail.setNext(new TokenWithComment(type, offset, _firstComment));
      _firstComment = null;
      _lastComment = null;
    }
  }

  void beginToken() {
    _tokenStart = _reader.offset;
  }

  /**
   * Return the beginning token corresponding to a closing brace that was found while scanning
   * inside a string interpolation expression. Tokens that cannot be matched with the closing brace
   * will be dropped from the stack.
   *
   * @return the token to be paired with the closing brace
   */
  BeginToken findTokenMatchingClosingBraceInInterpolationExpression() {
    while (_stackEnd >= 0) {
      BeginToken begin = _groupingStack[_stackEnd];
      if (identical(begin.type, TokenType.OPEN_CURLY_BRACKET) || identical(begin.type, TokenType.STRING_INTERPOLATION_EXPRESSION)) {
        return begin;
      }
      _hasUnmatchedGroups2 = true;
      _groupingStack.removeAt(_stackEnd--);
    }
    return null;
  }

  /**
   * Report an error at the current offset.
   *
   * @param errorCode the error code indicating the nature of the error
   * @param arguments any arguments needed to complete the error message
   */
  void reportError(ScannerErrorCode errorCode, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(source, _reader.offset, 1, errorCode, arguments));
  }

  int select(int choice, TokenType yesType, TokenType noType) {
    int next = _reader.advance();
    if (next == choice) {
      appendToken2(yesType);
      return _reader.advance();
    } else {
      appendToken2(noType);
      return next;
    }
  }

  int select2(int choice, TokenType yesType, TokenType noType, int offset) {
    int next = _reader.advance();
    if (next == choice) {
      appendToken3(yesType, offset);
      return _reader.advance();
    } else {
      appendToken3(noType, offset);
      return next;
    }
  }

  int tokenizeAmpersand(int next) {
    next = _reader.advance();
    if (next == 0x26) {
      appendToken2(TokenType.AMPERSAND_AMPERSAND);
      return _reader.advance();
    } else if (next == 0x3D) {
      appendToken2(TokenType.AMPERSAND_EQ);
      return _reader.advance();
    } else {
      appendToken2(TokenType.AMPERSAND);
      return next;
    }
  }

  int tokenizeBar(int next) {
    next = _reader.advance();
    if (next == 0x7C) {
      appendToken2(TokenType.BAR_BAR);
      return _reader.advance();
    } else if (next == 0x3D) {
      appendToken2(TokenType.BAR_EQ);
      return _reader.advance();
    } else {
      appendToken2(TokenType.BAR);
      return next;
    }
  }

  int tokenizeCaret(int next) => select(0x3D, TokenType.CARET_EQ, TokenType.CARET);

  int tokenizeDotOrNumber(int next) {
    int start = _reader.offset;
    next = _reader.advance();
    if (0x30 <= next && next <= 0x39) {
      return tokenizeFractionPart(next, start);
    } else if (0x2E == next) {
      return select(0x2E, TokenType.PERIOD_PERIOD_PERIOD, TokenType.PERIOD_PERIOD);
    } else {
      appendToken2(TokenType.PERIOD);
      return next;
    }
  }

  int tokenizeEquals(int next) {
    next = _reader.advance();
    if (next == 0x3D) {
      appendToken2(TokenType.EQ_EQ);
      return _reader.advance();
    } else if (next == 0x3E) {
      appendToken2(TokenType.FUNCTION);
      return _reader.advance();
    }
    appendToken2(TokenType.EQ);
    return next;
  }

  int tokenizeExclamation(int next) {
    next = _reader.advance();
    if (next == 0x3D) {
      appendToken2(TokenType.BANG_EQ);
      return _reader.advance();
    }
    appendToken2(TokenType.BANG);
    return next;
  }

  int tokenizeExponent(int next) {
    if (next == 0x2B || next == 0x2D) {
      next = _reader.advance();
    }
    bool hasDigits = false;
    while (true) {
      if (0x30 <= next && next <= 0x39) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          reportError(ScannerErrorCode.MISSING_DIGIT, []);
        }
        return next;
      }
      next = _reader.advance();
    }
  }

  int tokenizeFractionPart(int next, int start) {
    bool done = false;
    bool hasDigit = false;
    LOOP: while (!done) {
      if (0x30 <= next && next <= 0x39) {
        hasDigit = true;
      } else if (0x65 == next || 0x45 == next) {
        hasDigit = true;
        next = tokenizeExponent(_reader.advance());
        done = true;
        continue LOOP;
      } else {
        done = true;
        continue LOOP;
      }
      next = _reader.advance();
    }
    if (!hasDigit) {
      appendStringToken(TokenType.INT, _reader.getString(start, -2));
      if (0x2E == next) {
        return select2(0x2E, TokenType.PERIOD_PERIOD_PERIOD, TokenType.PERIOD_PERIOD, _reader.offset - 1);
      }
      appendToken3(TokenType.PERIOD, _reader.offset - 1);
      return bigSwitch(next);
    }
    appendStringToken(TokenType.DOUBLE, _reader.getString(start, next < 0 ? 0 : -1));
    return next;
  }

  int tokenizeGreaterThan(int next) {
    next = _reader.advance();
    if (0x3D == next) {
      appendToken2(TokenType.GT_EQ);
      return _reader.advance();
    } else if (0x3E == next) {
      next = _reader.advance();
      if (0x3D == next) {
        appendToken2(TokenType.GT_GT_EQ);
        return _reader.advance();
      } else {
        appendToken2(TokenType.GT_GT);
        return next;
      }
    } else {
      appendToken2(TokenType.GT);
      return next;
    }
  }

  int tokenizeHex(int next) {
    int start = _reader.offset - 1;
    bool hasDigits = false;
    while (true) {
      next = _reader.advance();
      if ((0x30 <= next && next <= 0x39) || (0x41 <= next && next <= 0x46) || (0x61 <= next && next <= 0x66)) {
        hasDigits = true;
      } else {
        if (!hasDigits) {
          reportError(ScannerErrorCode.MISSING_HEX_DIGIT, []);
        }
        appendStringToken(TokenType.HEXADECIMAL, _reader.getString(start, next < 0 ? 0 : -1));
        return next;
      }
    }
  }

  int tokenizeHexOrNumber(int next) {
    int x = _reader.peek();
    if (x == 0x78 || x == 0x58) {
      _reader.advance();
      return tokenizeHex(x);
    }
    return tokenizeNumber(next);
  }

  int tokenizeIdentifier(int next, int start, bool allowDollar) {
    while ((0x61 <= next && next <= 0x7A) || (0x41 <= next && next <= 0x5A) || (0x30 <= next && next <= 0x39) || next == 0x5F || (next == 0x24 && allowDollar)) {
      next = _reader.advance();
    }
    appendStringToken(TokenType.IDENTIFIER, _reader.getString(start, next < 0 ? 0 : -1));
    return next;
  }

  int tokenizeInterpolatedExpression(int next, int start) {
    appendBeginToken(TokenType.STRING_INTERPOLATION_EXPRESSION);
    next = _reader.advance();
    while (next != -1) {
      if (next == 0x7D) {
        BeginToken begin = findTokenMatchingClosingBraceInInterpolationExpression();
        if (begin == null) {
          beginToken();
          appendToken2(TokenType.CLOSE_CURLY_BRACKET);
          next = _reader.advance();
          beginToken();
          return next;
        } else if (identical(begin.type, TokenType.OPEN_CURLY_BRACKET)) {
          beginToken();
          appendEndToken(TokenType.CLOSE_CURLY_BRACKET, TokenType.OPEN_CURLY_BRACKET);
          next = _reader.advance();
          beginToken();
        } else if (identical(begin.type, TokenType.STRING_INTERPOLATION_EXPRESSION)) {
          beginToken();
          appendEndToken(TokenType.CLOSE_CURLY_BRACKET, TokenType.STRING_INTERPOLATION_EXPRESSION);
          next = _reader.advance();
          beginToken();
          return next;
        }
      } else {
        next = bigSwitch(next);
      }
    }
    if (next == -1) {
      return next;
    }
    next = _reader.advance();
    beginToken();
    return next;
  }

  int tokenizeInterpolatedIdentifier(int next, int start) {
    appendStringToken2(TokenType.STRING_INTERPOLATION_IDENTIFIER, "\$", 0);
    if ((0x41 <= next && next <= 0x5A) || (0x61 <= next && next <= 0x7A) || next == 0x5F) {
      beginToken();
      next = tokenizeKeywordOrIdentifier(next, false);
    }
    beginToken();
    return next;
  }

  int tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    KeywordState state = KeywordState.KEYWORD_STATE;
    int start = _reader.offset;
    while (state != null && 0x61 <= next && next <= 0x7A) {
      state = state.next(next as int);
      next = _reader.advance();
    }
    if (state == null || state.keyword() == null) {
      return tokenizeIdentifier(next, start, allowDollar);
    }
    if ((0x41 <= next && next <= 0x5A) || (0x30 <= next && next <= 0x39) || next == 0x5F || next == 0x24) {
      return tokenizeIdentifier(next, start, allowDollar);
    } else if (next < 128) {
      appendKeywordToken(state.keyword());
      return next;
    } else {
      return tokenizeIdentifier(next, start, allowDollar);
    }
  }

  int tokenizeLessThan(int next) {
    next = _reader.advance();
    if (0x3D == next) {
      appendToken2(TokenType.LT_EQ);
      return _reader.advance();
    } else if (0x3C == next) {
      return select(0x3D, TokenType.LT_LT_EQ, TokenType.LT_LT);
    } else {
      appendToken2(TokenType.LT);
      return next;
    }
  }

  int tokenizeMinus(int next) {
    next = _reader.advance();
    if (next == 0x2D) {
      appendToken2(TokenType.MINUS_MINUS);
      return _reader.advance();
    } else if (next == 0x3D) {
      appendToken2(TokenType.MINUS_EQ);
      return _reader.advance();
    } else {
      appendToken2(TokenType.MINUS);
      return next;
    }
  }

  int tokenizeMultiLineComment(int next) {
    int nesting = 1;
    next = _reader.advance();
    while (true) {
      if (-1 == next) {
        reportError(ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT, []);
        appendCommentToken(TokenType.MULTI_LINE_COMMENT, _reader.getString(_tokenStart, 0));
        return next;
      } else if (0x2A == next) {
        next = _reader.advance();
        if (0x2F == next) {
          --nesting;
          if (0 == nesting) {
            appendCommentToken(TokenType.MULTI_LINE_COMMENT, _reader.getString(_tokenStart, 0));
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

  int tokenizeMultiLineRawString(int quoteChar, int start) {
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
          appendStringToken(TokenType.STRING, _reader.getString(start, 0));
          return _reader.advance();
        }
      }
    }
    reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, []);
    appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    return _reader.advance();
  }

  int tokenizeMultiLineString(int quoteChar, int start, bool raw) {
    if (raw) {
      return tokenizeMultiLineRawString(quoteChar, start);
    }
    int next = _reader.advance();
    while (next != -1) {
      if (next == 0x24) {
        appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        beginToken();
        next = tokenizeStringInterpolation(start);
        start = _reader.offset;
        continue;
      }
      if (next == quoteChar) {
        next = _reader.advance();
        if (next == quoteChar) {
          next = _reader.advance();
          if (next == quoteChar) {
            appendStringToken(TokenType.STRING, _reader.getString(start, 0));
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
    reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, []);
    appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    return _reader.advance();
  }

  int tokenizeMultiply(int next) => select(0x3D, TokenType.STAR_EQ, TokenType.STAR);

  int tokenizeNumber(int next) {
    int start = _reader.offset;
    while (true) {
      next = _reader.advance();
      if (0x30 <= next && next <= 0x39) {
        continue;
      } else if (next == 0x2E) {
        return tokenizeFractionPart(_reader.advance(), start);
      } else if (next == 0x65 || next == 0x45) {
        return tokenizeFractionPart(next, start);
      } else {
        appendStringToken(TokenType.INT, _reader.getString(start, next < 0 ? 0 : -1));
        return next;
      }
    }
  }

  int tokenizeOpenSquareBracket(int next) {
    next = _reader.advance();
    if (next == 0x5D) {
      return select(0x3D, TokenType.INDEX_EQ, TokenType.INDEX);
    } else {
      appendBeginToken(TokenType.OPEN_SQUARE_BRACKET);
      return next;
    }
  }

  int tokenizePercent(int next) => select(0x3D, TokenType.PERCENT_EQ, TokenType.PERCENT);

  int tokenizePlus(int next) {
    next = _reader.advance();
    if (0x2B == next) {
      appendToken2(TokenType.PLUS_PLUS);
      return _reader.advance();
    } else if (0x3D == next) {
      appendToken2(TokenType.PLUS_EQ);
      return _reader.advance();
    } else {
      appendToken2(TokenType.PLUS);
      return next;
    }
  }

  int tokenizeSingleLineComment(int next) {
    while (true) {
      next = _reader.advance();
      if (-1 == next) {
        appendCommentToken(TokenType.SINGLE_LINE_COMMENT, _reader.getString(_tokenStart, 0));
        return next;
      } else if (0xA == next || 0xD == next) {
        appendCommentToken(TokenType.SINGLE_LINE_COMMENT, _reader.getString(_tokenStart, -1));
        return next;
      }
    }
  }

  int tokenizeSingleLineRawString(int next, int quoteChar, int start) {
    next = _reader.advance();
    while (next != -1) {
      if (next == quoteChar) {
        appendStringToken(TokenType.STRING, _reader.getString(start, 0));
        return _reader.advance();
      } else if (next == 0xD || next == 0xA) {
        reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, []);
        appendStringToken(TokenType.STRING, _reader.getString(start, 0));
        return _reader.advance();
      }
      next = _reader.advance();
    }
    reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, []);
    appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    return _reader.advance();
  }

  int tokenizeSingleLineString(int next, int quoteChar, int start) {
    while (next != quoteChar) {
      if (next == 0x5C) {
        next = _reader.advance();
      } else if (next == 0x24) {
        appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        beginToken();
        next = tokenizeStringInterpolation(start);
        start = _reader.offset;
        continue;
      }
      if (next <= 0xD && (next == 0xA || next == 0xD || next == -1)) {
        reportError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, []);
        appendStringToken(TokenType.STRING, _reader.getString(start, 0));
        return _reader.advance();
      }
      next = _reader.advance();
    }
    appendStringToken(TokenType.STRING, _reader.getString(start, 0));
    return _reader.advance();
  }

  int tokenizeSlashOrComment(int next) {
    next = _reader.advance();
    if (0x2A == next) {
      return tokenizeMultiLineComment(next);
    } else if (0x2F == next) {
      return tokenizeSingleLineComment(next);
    } else if (0x3D == next) {
      appendToken2(TokenType.SLASH_EQ);
      return _reader.advance();
    } else {
      appendToken2(TokenType.SLASH);
      return next;
    }
  }

  int tokenizeString(int next, int start, bool raw) {
    int quoteChar = next;
    next = _reader.advance();
    if (quoteChar == next) {
      next = _reader.advance();
      if (quoteChar == next) {
        return tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        appendStringToken(TokenType.STRING, _reader.getString(start, -1));
        return next;
      }
    }
    if (raw) {
      return tokenizeSingleLineRawString(next, quoteChar, start);
    } else {
      return tokenizeSingleLineString(next, quoteChar, start);
    }
  }

  int tokenizeStringInterpolation(int start) {
    beginToken();
    int next = _reader.advance();
    if (next == 0x7B) {
      return tokenizeInterpolatedExpression(next, start);
    } else {
      return tokenizeInterpolatedIdentifier(next, start);
    }
  }

  int tokenizeTag(int next) {
    if (_reader.offset == 0) {
      if (_reader.peek() == 0x21) {
        do {
          next = _reader.advance();
        } while (next != 0xA && next != 0xD && next > 0);
        appendStringToken(TokenType.SCRIPT_TAG, _reader.getString(_tokenStart, 0));
        return next;
      }
    }
    appendToken2(TokenType.HASH);
    return _reader.advance();
  }

  int tokenizeTilde(int next) {
    next = _reader.advance();
    if (next == 0x2F) {
      return select(0x3D, TokenType.TILDE_SLASH_EQ, TokenType.TILDE_SLASH);
    } else {
      appendToken2(TokenType.TILDE);
      return next;
    }
  }
}

/**
 * Instances of the class `StringToken` represent a token whose value is independent of it's
 * type.
 *
 * @coverage dart.engine.parser
 */
class StringToken extends Token {
  /**
   * The lexeme represented by this token.
   */
  String _value2;

  /**
   * Initialize a newly created token to represent a token of the given type with the given value.
   *
   * @param type the type of the token
   * @param value the lexeme represented by this token
   * @param offset the offset from the beginning of the file to the first character in the token
   */
  StringToken(TokenType type, String value, int offset) : super(type, offset) {
    this._value2 = StringUtilities.intern(value);
  }

  Token copy() => new StringToken(type, _value2, offset);

  String get lexeme => _value2;

  String value() => _value2;
}

/**
 * Instances of the class `TokenWithComment` represent a normal token that is preceded by
 * comments.
 *
 * @coverage dart.engine.parser
 */
class TokenWithComment extends Token {
  /**
   * The first comment in the list of comments that precede this token.
   */
  Token _precedingComment;

  /**
   * Initialize a newly created token to have the given type and offset and to be preceded by the
   * comments reachable from the given comment.
   *
   * @param type the type of the token
   * @param offset the offset from the beginning of the file to the first character in the token
   * @param precedingComment the first comment in the list of comments that precede this token
   */
  TokenWithComment(TokenType type, int offset, Token precedingComment) : super(type, offset) {
    this._precedingComment = precedingComment;
  }

  Token copy() => new TokenWithComment(type, offset, _precedingComment);

  Token get precedingComments => _precedingComment;
}

/**
 * Instances of the class `Token` represent a token that was scanned from the input. Each
 * token knows which token follows it, acting as the head of a linked list of tokens.
 *
 * @coverage dart.engine.parser
 */
class Token {
  /**
   * The type of the token.
   */
  TokenType type;

  /**
   * The offset from the beginning of the file to the first character in the token.
   */
  int offset = 0;

  /**
   * The previous token in the token stream.
   */
  Token previous;

  /**
   * The next token in the token stream.
   */
  Token next;

  /**
   * Initialize a newly created token to have the given type and offset.
   *
   * @param type the type of the token
   * @param offset the offset from the beginning of the file to the first character in the token
   */
  Token(TokenType type, int offset) {
    this.type = type;
    this.offset = offset;
  }

  /**
   * Return a newly created token that is a copy of this token but that is not a part of any token
   * stream.
   *
   * @return a newly created token that is a copy of this token
   */
  Token copy() => new Token(type, offset);

  /**
   * Return the offset from the beginning of the file to the character after last character of the
   * token.
   *
   * @return the offset from the beginning of the file to the first character after last character
   *         of the token
   */
  int get end => offset + length;

  /**
   * Return the number of characters in the node's source range.
   *
   * @return the number of characters in the node's source range
   */
  int get length => lexeme.length;

  /**
   * Return the lexeme that represents this token.
   *
   * @return the lexeme that represents this token
   */
  String get lexeme => type.lexeme;

  /**
   * Return the first comment in the list of comments that precede this token, or `null` if
   * there are no comments preceding this token. Additional comments can be reached by following the
   * token stream using [getNext] until `null` is returned.
   *
   * @return the first comment in the list of comments that precede this token
   */
  Token get precedingComments => null;

  /**
   * Return `true` if this token represents an operator.
   *
   * @return `true` if this token represents an operator
   */
  bool get isOperator => type.isOperator;

  /**
   * Return `true` if this token is a synthetic token. A synthetic token is a token that was
   * introduced by the parser in order to recover from an error in the code.
   *
   * @return `true` if this token is a synthetic token
   */
  bool get isSynthetic => length == 0;

  /**
   * Return `true` if this token represents an operator that can be defined by users.
   *
   * @return `true` if this token represents an operator that can be defined by users
   */
  bool get isUserDefinableOperator => type.isUserDefinableOperator;

  /**
   * Set the next token in the token stream to the given token. This has the side-effect of setting
   * this token to be the previous token for the given token.
   *
   * @param token the next token in the token stream
   * @return the token that was passed in
   */
  Token setNext(Token token) {
    next = token;
    token.previous = this;
    return token;
  }

  /**
   * Set the next token in the token stream to the given token without changing which token is the
   * previous token for the given token.
   *
   * @param token the next token in the token stream
   * @return the token that was passed in
   */
  Token setNextWithoutSettingPrevious(Token token) {
    next = token;
    return token;
  }

  String toString() => lexeme;

  /**
   * Return the value of this token. For keyword tokens, this is the keyword associated with the
   * token, for other tokens it is the lexeme associated with the token.
   *
   * @return the value of this token
   */
  Object value() => type.lexeme;

  /**
   * Apply (add) the given delta to this token's offset.
   *
   * @param delta the amount by which the offset is to be adjusted
   */
  void applyDelta(int delta) {
    offset += delta;
  }

  /**
   * Copy a linked list of comment tokens identical to the given comment tokens.
   *
   * @param token the first token in the list, or `null` if there are no tokens to be copied
   * @return the tokens that were created
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
}

/**
 * The interface `CharacterReader`
 */
abstract class CharacterReader {
  /**
   * Advance the current position and return the character at the new current position.
   *
   * @return the character at the new current position
   */
  int advance();

  /**
   * Return the current offset relative to the beginning of the source. Return the initial offset if
   * the scanner has not yet scanned the source code, and one (1) past the end of the source code if
   * the entire source code has been scanned.
   *
   * @return the current offset of the scanner in the source
   */
  int get offset;

  /**
   * Return the substring of the source code between the start offset and the modified current
   * position. The current position is modified by adding the end delta.
   *
   * @param start the offset to the beginning of the string, relative to the start of the file
   * @param endDelta the number of characters after the current location to be included in the
   *          string, or the number of characters before the current location to be excluded if the
   *          offset is negative
   * @return the specified substring of the source code
   */
  String getString(int start, int endDelta);

  /**
   * Return the character at the current position without changing the current position.
   *
   * @return the character at the current position
   */
  int peek();

  /**
   * Set the current offset relative to the beginning of the source. The new offset must be between
   * the initial offset and one (1) past the end of the source code.
   *
   * @param offset the new offset in the source
   */
  void set offset(int offset);
}

/**
 * Instances of the class `BeginTokenWithComment` represent a begin token that is preceded by
 * comments.
 *
 * @coverage dart.engine.parser
 */
class BeginTokenWithComment extends BeginToken {
  /**
   * The first comment in the list of comments that precede this token.
   */
  Token _precedingComment;

  /**
   * Initialize a newly created token to have the given type and offset and to be preceded by the
   * comments reachable from the given comment.
   *
   * @param type the type of the token
   * @param offset the offset from the beginning of the file to the first character in the token
   * @param precedingComment the first comment in the list of comments that precede this token
   */
  BeginTokenWithComment(TokenType type, int offset, Token precedingComment) : super(type, offset) {
    this._precedingComment = precedingComment;
  }

  Token copy() => new BeginTokenWithComment(type, offset, copyComments(_precedingComment));

  Token get precedingComments => _precedingComment;

  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = _precedingComment;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }
}

/**
 * Instances of the class `KeywordToken` represent a keyword in the language.
 *
 * @coverage dart.engine.parser
 */
class KeywordToken extends Token {
  /**
   * The keyword being represented by this token.
   */
  Keyword keyword;

  /**
   * Initialize a newly created token to represent the given keyword.
   *
   * @param keyword the keyword being represented by this token
   * @param offset the offset from the beginning of the file to the first character in the token
   */
  KeywordToken(Keyword keyword, int offset) : super(TokenType.KEYWORD, offset) {
    this.keyword = keyword;
  }

  Token copy() => new KeywordToken(keyword, offset);

  String get lexeme => keyword.syntax;

  Keyword value() => keyword;
}

/**
 * Instances of the class `BeginToken` represent the opening half of a grouping pair of
 * tokens. This is used for curly brackets ('{'), parentheses ('('), and square brackets ('[').
 *
 * @coverage dart.engine.parser
 */
class BeginToken extends Token {
  /**
   * The token that corresponds to this token.
   */
  Token endToken;

  /**
   * Initialize a newly created token representing the opening half of a grouping pair of tokens.
   *
   * @param type the type of the token
   * @param offset the offset from the beginning of the file to the first character in the token
   */
  BeginToken(TokenType type, int offset) : super(type, offset) {
    assert((identical(type, TokenType.OPEN_CURLY_BRACKET) || identical(type, TokenType.OPEN_PAREN) || identical(type, TokenType.OPEN_SQUARE_BRACKET) || identical(type, TokenType.STRING_INTERPOLATION_EXPRESSION)));
  }

  Token copy() => new BeginToken(type, offset);
}

/**
 * The enumeration `TokenClass` represents classes (or groups) of tokens with a similar use.
 *
 * @coverage dart.engine.parser
 */
class TokenClass extends Enum<TokenClass> {
  /**
   * A value used to indicate that the token type is not part of any specific class of token.
   */
  static final TokenClass NO_CLASS = new TokenClass.con1('NO_CLASS', 0);

  /**
   * A value used to indicate that the token type is an additive operator.
   */
  static final TokenClass ADDITIVE_OPERATOR = new TokenClass.con2('ADDITIVE_OPERATOR', 1, 12);

  /**
   * A value used to indicate that the token type is an assignment operator.
   */
  static final TokenClass ASSIGNMENT_OPERATOR = new TokenClass.con2('ASSIGNMENT_OPERATOR', 2, 1);

  /**
   * A value used to indicate that the token type is a bitwise-and operator.
   */
  static final TokenClass BITWISE_AND_OPERATOR = new TokenClass.con2('BITWISE_AND_OPERATOR', 3, 10);

  /**
   * A value used to indicate that the token type is a bitwise-or operator.
   */
  static final TokenClass BITWISE_OR_OPERATOR = new TokenClass.con2('BITWISE_OR_OPERATOR', 4, 8);

  /**
   * A value used to indicate that the token type is a bitwise-xor operator.
   */
  static final TokenClass BITWISE_XOR_OPERATOR = new TokenClass.con2('BITWISE_XOR_OPERATOR', 5, 9);

  /**
   * A value used to indicate that the token type is a cascade operator.
   */
  static final TokenClass CASCADE_OPERATOR = new TokenClass.con2('CASCADE_OPERATOR', 6, 2);

  /**
   * A value used to indicate that the token type is a conditional operator.
   */
  static final TokenClass CONDITIONAL_OPERATOR = new TokenClass.con2('CONDITIONAL_OPERATOR', 7, 3);

  /**
   * A value used to indicate that the token type is an equality operator.
   */
  static final TokenClass EQUALITY_OPERATOR = new TokenClass.con2('EQUALITY_OPERATOR', 8, 6);

  /**
   * A value used to indicate that the token type is a logical-and operator.
   */
  static final TokenClass LOGICAL_AND_OPERATOR = new TokenClass.con2('LOGICAL_AND_OPERATOR', 9, 5);

  /**
   * A value used to indicate that the token type is a logical-or operator.
   */
  static final TokenClass LOGICAL_OR_OPERATOR = new TokenClass.con2('LOGICAL_OR_OPERATOR', 10, 4);

  /**
   * A value used to indicate that the token type is a multiplicative operator.
   */
  static final TokenClass MULTIPLICATIVE_OPERATOR = new TokenClass.con2('MULTIPLICATIVE_OPERATOR', 11, 13);

  /**
   * A value used to indicate that the token type is a relational operator.
   */
  static final TokenClass RELATIONAL_OPERATOR = new TokenClass.con2('RELATIONAL_OPERATOR', 12, 7);

  /**
   * A value used to indicate that the token type is a shift operator.
   */
  static final TokenClass SHIFT_OPERATOR = new TokenClass.con2('SHIFT_OPERATOR', 13, 11);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static final TokenClass UNARY_POSTFIX_OPERATOR = new TokenClass.con2('UNARY_POSTFIX_OPERATOR', 14, 15);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static final TokenClass UNARY_PREFIX_OPERATOR = new TokenClass.con2('UNARY_PREFIX_OPERATOR', 15, 14);

  static final List<TokenClass> values = [
      NO_CLASS,
      ADDITIVE_OPERATOR,
      ASSIGNMENT_OPERATOR,
      BITWISE_AND_OPERATOR,
      BITWISE_OR_OPERATOR,
      BITWISE_XOR_OPERATOR,
      CASCADE_OPERATOR,
      CONDITIONAL_OPERATOR,
      EQUALITY_OPERATOR,
      LOGICAL_AND_OPERATOR,
      LOGICAL_OR_OPERATOR,
      MULTIPLICATIVE_OPERATOR,
      RELATIONAL_OPERATOR,
      SHIFT_OPERATOR,
      UNARY_POSTFIX_OPERATOR,
      UNARY_PREFIX_OPERATOR];

  /**
   * The precedence of tokens of this class, or `0` if the such tokens do not represent an
   * operator.
   */
  int precedence = 0;

  TokenClass.con1(String name, int ordinal) : this.con2(name, ordinal, 0);

  TokenClass.con2(String name, int ordinal, int precedence) : super(name, ordinal) {
    this.precedence = precedence;
  }
}

/**
 * Instances of the class `KeywordTokenWithComment` implement a keyword token that is preceded
 * by comments.
 *
 * @coverage dart.engine.parser
 */
class KeywordTokenWithComment extends KeywordToken {
  /**
   * The first comment in the list of comments that precede this token.
   */
  Token _precedingComment;

  /**
   * Initialize a newly created token to to represent the given keyword and to be preceded by the
   * comments reachable from the given comment.
   *
   * @param keyword the keyword being represented by this token
   * @param offset the offset from the beginning of the file to the first character in the token
   * @param precedingComment the first comment in the list of comments that precede this token
   */
  KeywordTokenWithComment(Keyword keyword, int offset, Token precedingComment) : super(keyword, offset) {
    this._precedingComment = precedingComment;
  }

  Token copy() => new KeywordTokenWithComment(keyword, offset, copyComments(_precedingComment));

  Token get precedingComments => _precedingComment;

  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = _precedingComment;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }
}

/**
 * The enumeration `TokenType` defines the types of tokens that can be returned by the
 * scanner.
 *
 * @coverage dart.engine.parser
 */
class TokenType extends Enum<TokenType> {
  /**
   * The type of the token that marks the end of the input.
   */
  static final TokenType EOF = new TokenType_EOF('EOF', 0, null, "");

  static final TokenType DOUBLE = new TokenType.con1('DOUBLE', 1);

  static final TokenType HEXADECIMAL = new TokenType.con1('HEXADECIMAL', 2);

  static final TokenType IDENTIFIER = new TokenType.con1('IDENTIFIER', 3);

  static final TokenType INT = new TokenType.con1('INT', 4);

  static final TokenType KEYWORD = new TokenType.con1('KEYWORD', 5);

  static final TokenType MULTI_LINE_COMMENT = new TokenType.con1('MULTI_LINE_COMMENT', 6);

  static final TokenType SCRIPT_TAG = new TokenType.con1('SCRIPT_TAG', 7);

  static final TokenType SINGLE_LINE_COMMENT = new TokenType.con1('SINGLE_LINE_COMMENT', 8);

  static final TokenType STRING = new TokenType.con1('STRING', 9);

  static final TokenType AMPERSAND = new TokenType.con2('AMPERSAND', 10, TokenClass.BITWISE_AND_OPERATOR, "&");

  static final TokenType AMPERSAND_AMPERSAND = new TokenType.con2('AMPERSAND_AMPERSAND', 11, TokenClass.LOGICAL_AND_OPERATOR, "&&");

  static final TokenType AMPERSAND_EQ = new TokenType.con2('AMPERSAND_EQ', 12, TokenClass.ASSIGNMENT_OPERATOR, "&=");

  static final TokenType AT = new TokenType.con2('AT', 13, null, "@");

  static final TokenType BANG = new TokenType.con2('BANG', 14, TokenClass.UNARY_PREFIX_OPERATOR, "!");

  static final TokenType BANG_EQ = new TokenType.con2('BANG_EQ', 15, TokenClass.EQUALITY_OPERATOR, "!=");

  static final TokenType BAR = new TokenType.con2('BAR', 16, TokenClass.BITWISE_OR_OPERATOR, "|");

  static final TokenType BAR_BAR = new TokenType.con2('BAR_BAR', 17, TokenClass.LOGICAL_OR_OPERATOR, "||");

  static final TokenType BAR_EQ = new TokenType.con2('BAR_EQ', 18, TokenClass.ASSIGNMENT_OPERATOR, "|=");

  static final TokenType COLON = new TokenType.con2('COLON', 19, null, ":");

  static final TokenType COMMA = new TokenType.con2('COMMA', 20, null, ",");

  static final TokenType CARET = new TokenType.con2('CARET', 21, TokenClass.BITWISE_XOR_OPERATOR, "^");

  static final TokenType CARET_EQ = new TokenType.con2('CARET_EQ', 22, TokenClass.ASSIGNMENT_OPERATOR, "^=");

  static final TokenType CLOSE_CURLY_BRACKET = new TokenType.con2('CLOSE_CURLY_BRACKET', 23, null, "}");

  static final TokenType CLOSE_PAREN = new TokenType.con2('CLOSE_PAREN', 24, null, ")");

  static final TokenType CLOSE_SQUARE_BRACKET = new TokenType.con2('CLOSE_SQUARE_BRACKET', 25, null, "]");

  static final TokenType EQ = new TokenType.con2('EQ', 26, TokenClass.ASSIGNMENT_OPERATOR, "=");

  static final TokenType EQ_EQ = new TokenType.con2('EQ_EQ', 27, TokenClass.EQUALITY_OPERATOR, "==");

  static final TokenType FUNCTION = new TokenType.con2('FUNCTION', 28, null, "=>");

  static final TokenType GT = new TokenType.con2('GT', 29, TokenClass.RELATIONAL_OPERATOR, ">");

  static final TokenType GT_EQ = new TokenType.con2('GT_EQ', 30, TokenClass.RELATIONAL_OPERATOR, ">=");

  static final TokenType GT_GT = new TokenType.con2('GT_GT', 31, TokenClass.SHIFT_OPERATOR, ">>");

  static final TokenType GT_GT_EQ = new TokenType.con2('GT_GT_EQ', 32, TokenClass.ASSIGNMENT_OPERATOR, ">>=");

  static final TokenType HASH = new TokenType.con2('HASH', 33, null, "#");

  static final TokenType INDEX = new TokenType.con2('INDEX', 34, TokenClass.UNARY_POSTFIX_OPERATOR, "[]");

  static final TokenType INDEX_EQ = new TokenType.con2('INDEX_EQ', 35, TokenClass.UNARY_POSTFIX_OPERATOR, "[]=");

  static final TokenType IS = new TokenType.con2('IS', 36, TokenClass.RELATIONAL_OPERATOR, "is");

  static final TokenType LT = new TokenType.con2('LT', 37, TokenClass.RELATIONAL_OPERATOR, "<");

  static final TokenType LT_EQ = new TokenType.con2('LT_EQ', 38, TokenClass.RELATIONAL_OPERATOR, "<=");

  static final TokenType LT_LT = new TokenType.con2('LT_LT', 39, TokenClass.SHIFT_OPERATOR, "<<");

  static final TokenType LT_LT_EQ = new TokenType.con2('LT_LT_EQ', 40, TokenClass.ASSIGNMENT_OPERATOR, "<<=");

  static final TokenType MINUS = new TokenType.con2('MINUS', 41, TokenClass.ADDITIVE_OPERATOR, "-");

  static final TokenType MINUS_EQ = new TokenType.con2('MINUS_EQ', 42, TokenClass.ASSIGNMENT_OPERATOR, "-=");

  static final TokenType MINUS_MINUS = new TokenType.con2('MINUS_MINUS', 43, TokenClass.UNARY_PREFIX_OPERATOR, "--");

  static final TokenType OPEN_CURLY_BRACKET = new TokenType.con2('OPEN_CURLY_BRACKET', 44, null, "{");

  static final TokenType OPEN_PAREN = new TokenType.con2('OPEN_PAREN', 45, TokenClass.UNARY_POSTFIX_OPERATOR, "(");

  static final TokenType OPEN_SQUARE_BRACKET = new TokenType.con2('OPEN_SQUARE_BRACKET', 46, TokenClass.UNARY_POSTFIX_OPERATOR, "[");

  static final TokenType PERCENT = new TokenType.con2('PERCENT', 47, TokenClass.MULTIPLICATIVE_OPERATOR, "%");

  static final TokenType PERCENT_EQ = new TokenType.con2('PERCENT_EQ', 48, TokenClass.ASSIGNMENT_OPERATOR, "%=");

  static final TokenType PERIOD = new TokenType.con2('PERIOD', 49, TokenClass.UNARY_POSTFIX_OPERATOR, ".");

  static final TokenType PERIOD_PERIOD = new TokenType.con2('PERIOD_PERIOD', 50, TokenClass.CASCADE_OPERATOR, "..");

  static final TokenType PLUS = new TokenType.con2('PLUS', 51, TokenClass.ADDITIVE_OPERATOR, "+");

  static final TokenType PLUS_EQ = new TokenType.con2('PLUS_EQ', 52, TokenClass.ASSIGNMENT_OPERATOR, "+=");

  static final TokenType PLUS_PLUS = new TokenType.con2('PLUS_PLUS', 53, TokenClass.UNARY_PREFIX_OPERATOR, "++");

  static final TokenType QUESTION = new TokenType.con2('QUESTION', 54, TokenClass.CONDITIONAL_OPERATOR, "?");

  static final TokenType SEMICOLON = new TokenType.con2('SEMICOLON', 55, null, ";");

  static final TokenType SLASH = new TokenType.con2('SLASH', 56, TokenClass.MULTIPLICATIVE_OPERATOR, "/");

  static final TokenType SLASH_EQ = new TokenType.con2('SLASH_EQ', 57, TokenClass.ASSIGNMENT_OPERATOR, "/=");

  static final TokenType STAR = new TokenType.con2('STAR', 58, TokenClass.MULTIPLICATIVE_OPERATOR, "*");

  static final TokenType STAR_EQ = new TokenType.con2('STAR_EQ', 59, TokenClass.ASSIGNMENT_OPERATOR, "*=");

  static final TokenType STRING_INTERPOLATION_EXPRESSION = new TokenType.con2('STRING_INTERPOLATION_EXPRESSION', 60, null, "\${");

  static final TokenType STRING_INTERPOLATION_IDENTIFIER = new TokenType.con2('STRING_INTERPOLATION_IDENTIFIER', 61, null, "\$");

  static final TokenType TILDE = new TokenType.con2('TILDE', 62, TokenClass.UNARY_PREFIX_OPERATOR, "~");

  static final TokenType TILDE_SLASH = new TokenType.con2('TILDE_SLASH', 63, TokenClass.MULTIPLICATIVE_OPERATOR, "~/");

  static final TokenType TILDE_SLASH_EQ = new TokenType.con2('TILDE_SLASH_EQ', 64, TokenClass.ASSIGNMENT_OPERATOR, "~/=");

  static final TokenType BACKPING = new TokenType.con2('BACKPING', 65, null, "`");

  static final TokenType BACKSLASH = new TokenType.con2('BACKSLASH', 66, null, "\\");

  static final TokenType PERIOD_PERIOD_PERIOD = new TokenType.con2('PERIOD_PERIOD_PERIOD', 67, null, "...");

  static final List<TokenType> values = [
      EOF,
      DOUBLE,
      HEXADECIMAL,
      IDENTIFIER,
      INT,
      KEYWORD,
      MULTI_LINE_COMMENT,
      SCRIPT_TAG,
      SINGLE_LINE_COMMENT,
      STRING,
      AMPERSAND,
      AMPERSAND_AMPERSAND,
      AMPERSAND_EQ,
      AT,
      BANG,
      BANG_EQ,
      BAR,
      BAR_BAR,
      BAR_EQ,
      COLON,
      COMMA,
      CARET,
      CARET_EQ,
      CLOSE_CURLY_BRACKET,
      CLOSE_PAREN,
      CLOSE_SQUARE_BRACKET,
      EQ,
      EQ_EQ,
      FUNCTION,
      GT,
      GT_EQ,
      GT_GT,
      GT_GT_EQ,
      HASH,
      INDEX,
      INDEX_EQ,
      IS,
      LT,
      LT_EQ,
      LT_LT,
      LT_LT_EQ,
      MINUS,
      MINUS_EQ,
      MINUS_MINUS,
      OPEN_CURLY_BRACKET,
      OPEN_PAREN,
      OPEN_SQUARE_BRACKET,
      PERCENT,
      PERCENT_EQ,
      PERIOD,
      PERIOD_PERIOD,
      PLUS,
      PLUS_EQ,
      PLUS_PLUS,
      QUESTION,
      SEMICOLON,
      SLASH,
      SLASH_EQ,
      STAR,
      STAR_EQ,
      STRING_INTERPOLATION_EXPRESSION,
      STRING_INTERPOLATION_IDENTIFIER,
      TILDE,
      TILDE_SLASH,
      TILDE_SLASH_EQ,
      BACKPING,
      BACKSLASH,
      PERIOD_PERIOD_PERIOD];

  /**
   * The class of the token.
   */
  TokenClass _tokenClass;

  /**
   * The lexeme that defines this type of token, or `null` if there is more than one possible
   * lexeme for this type of token.
   */
  String lexeme;

  TokenType.con1(String name, int ordinal) : this.con2(name, ordinal, TokenClass.NO_CLASS, null);

  TokenType.con2(String name, int ordinal, TokenClass tokenClass, String lexeme) : super(name, ordinal) {
    this._tokenClass = tokenClass == null ? TokenClass.NO_CLASS : tokenClass;
    this.lexeme = lexeme;
  }

  /**
   * Return the precedence of the token, or `0` if the token does not represent an operator.
   *
   * @return the precedence of the token
   */
  int get precedence => _tokenClass.precedence;

  /**
   * Return `true` if this type of token represents an additive operator.
   *
   * @return `true` if this type of token represents an additive operator
   */
  bool get isAdditiveOperator => identical(_tokenClass, TokenClass.ADDITIVE_OPERATOR);

  /**
   * Return `true` if this type of token represents an assignment operator.
   *
   * @return `true` if this type of token represents an assignment operator
   */
  bool get isAssignmentOperator => identical(_tokenClass, TokenClass.ASSIGNMENT_OPERATOR);

  /**
   * Return `true` if this type of token represents an associative operator. An associative
   * operator is an operator for which the following equality is true:
   * `(a * b) * c == a * (b * c)`. In other words, if the result of applying the operator to
   * multiple operands does not depend on the order in which those applications occur.
   *
   * Note: This method considers the logical-and and logical-or operators to be associative, even
   * though the order in which the application of those operators can have an effect because
   * evaluation of the right-hand operand is conditional.
   *
   * @return `true` if this type of token represents an associative operator
   */
  bool get isAssociativeOperator => identical(this, AMPERSAND) || identical(this, AMPERSAND_AMPERSAND) || identical(this, BAR) || identical(this, BAR_BAR) || identical(this, CARET) || identical(this, PLUS) || identical(this, STAR);

  /**
   * Return `true` if this type of token represents an equality operator.
   *
   * @return `true` if this type of token represents an equality operator
   */
  bool get isEqualityOperator => identical(_tokenClass, TokenClass.EQUALITY_OPERATOR);

  /**
   * Return `true` if this type of token represents an increment operator.
   *
   * @return `true` if this type of token represents an increment operator
   */
  bool get isIncrementOperator => identical(lexeme, "++") || identical(lexeme, "--");

  /**
   * Return `true` if this type of token represents a multiplicative operator.
   *
   * @return `true` if this type of token represents a multiplicative operator
   */
  bool get isMultiplicativeOperator => identical(_tokenClass, TokenClass.MULTIPLICATIVE_OPERATOR);

  /**
   * Return `true` if this token type represents an operator.
   *
   * @return `true` if this token type represents an operator
   */
  bool get isOperator => _tokenClass != TokenClass.NO_CLASS && this != OPEN_PAREN && this != OPEN_SQUARE_BRACKET && this != PERIOD;

  /**
   * Return `true` if this type of token represents a relational operator.
   *
   * @return `true` if this type of token represents a relational operator
   */
  bool get isRelationalOperator => identical(_tokenClass, TokenClass.RELATIONAL_OPERATOR);

  /**
   * Return `true` if this type of token represents a shift operator.
   *
   * @return `true` if this type of token represents a shift operator
   */
  bool get isShiftOperator => identical(_tokenClass, TokenClass.SHIFT_OPERATOR);

  /**
   * Return `true` if this type of token represents a unary postfix operator.
   *
   * @return `true` if this type of token represents a unary postfix operator
   */
  bool get isUnaryPostfixOperator => identical(_tokenClass, TokenClass.UNARY_POSTFIX_OPERATOR);

  /**
   * Return `true` if this type of token represents a unary prefix operator.
   *
   * @return `true` if this type of token represents a unary prefix operator
   */
  bool get isUnaryPrefixOperator => identical(_tokenClass, TokenClass.UNARY_PREFIX_OPERATOR);

  /**
   * Return `true` if this token type represents an operator that can be defined by users.
   *
   * @return `true` if this token type represents an operator that can be defined by users
   */
  bool get isUserDefinableOperator => identical(lexeme, "==") || identical(lexeme, "~") || identical(lexeme, "[]") || identical(lexeme, "[]=") || identical(lexeme, "*") || identical(lexeme, "/") || identical(lexeme, "%") || identical(lexeme, "~/") || identical(lexeme, "+") || identical(lexeme, "-") || identical(lexeme, "<<") || identical(lexeme, ">>") || identical(lexeme, ">=") || identical(lexeme, ">") || identical(lexeme, "<=") || identical(lexeme, "<") || identical(lexeme, "&") || identical(lexeme, "^") || identical(lexeme, "|");
}

class TokenType_EOF extends TokenType {
  TokenType_EOF(String name, int ordinal, TokenClass arg0, String arg1) : super.con2(name, ordinal, arg0, arg1);

  String toString() => "-eof-";
}