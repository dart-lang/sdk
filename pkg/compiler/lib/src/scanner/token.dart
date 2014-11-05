// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

const int EOF_TOKEN = 0;

const int KEYWORD_TOKEN = $k;
const int IDENTIFIER_TOKEN = $a;
const int BAD_INPUT_TOKEN = $X;
const int DOUBLE_TOKEN = $d;
const int INT_TOKEN = $i;
const int HEXADECIMAL_TOKEN = $x;
const int STRING_TOKEN = $SQ;

const int AMPERSAND_TOKEN = $AMPERSAND;
const int BACKPING_TOKEN = $BACKPING;
const int BACKSLASH_TOKEN = $BACKSLASH;
const int BANG_TOKEN = $BANG;
const int BAR_TOKEN = $BAR;
const int COLON_TOKEN = $COLON;
const int COMMA_TOKEN = $COMMA;
const int EQ_TOKEN = $EQ;
const int GT_TOKEN = $GT;
const int HASH_TOKEN = $HASH;
const int OPEN_CURLY_BRACKET_TOKEN = $OPEN_CURLY_BRACKET;
const int OPEN_SQUARE_BRACKET_TOKEN = $OPEN_SQUARE_BRACKET;
const int OPEN_PAREN_TOKEN = $OPEN_PAREN;
const int LT_TOKEN = $LT;
const int MINUS_TOKEN = $MINUS;
const int PERIOD_TOKEN = $PERIOD;
const int PLUS_TOKEN = $PLUS;
const int QUESTION_TOKEN = $QUESTION;
const int AT_TOKEN = $AT;
const int CLOSE_CURLY_BRACKET_TOKEN = $CLOSE_CURLY_BRACKET;
const int CLOSE_SQUARE_BRACKET_TOKEN = $CLOSE_SQUARE_BRACKET;
const int CLOSE_PAREN_TOKEN = $CLOSE_PAREN;
const int SEMICOLON_TOKEN = $SEMICOLON;
const int SLASH_TOKEN = $SLASH;
const int TILDE_TOKEN = $TILDE;
const int STAR_TOKEN = $STAR;
const int PERCENT_TOKEN = $PERCENT;
const int CARET_TOKEN = $CARET;

const int STRING_INTERPOLATION_TOKEN = 128;
const int LT_EQ_TOKEN = STRING_INTERPOLATION_TOKEN + 1;
const int FUNCTION_TOKEN = LT_EQ_TOKEN + 1;
const int SLASH_EQ_TOKEN = FUNCTION_TOKEN + 1;
const int PERIOD_PERIOD_PERIOD_TOKEN = SLASH_EQ_TOKEN + 1;
const int PERIOD_PERIOD_TOKEN = PERIOD_PERIOD_PERIOD_TOKEN + 1;
const int EQ_EQ_EQ_TOKEN = PERIOD_PERIOD_TOKEN + 1;
const int EQ_EQ_TOKEN = EQ_EQ_EQ_TOKEN + 1;
const int LT_LT_EQ_TOKEN = EQ_EQ_TOKEN + 1;
const int LT_LT_TOKEN = LT_LT_EQ_TOKEN + 1;
const int GT_EQ_TOKEN = LT_LT_TOKEN + 1;
const int GT_GT_EQ_TOKEN = GT_EQ_TOKEN + 1;
const int INDEX_EQ_TOKEN = GT_GT_EQ_TOKEN + 1;
const int INDEX_TOKEN = INDEX_EQ_TOKEN + 1;
const int BANG_EQ_EQ_TOKEN = INDEX_TOKEN + 1;
const int BANG_EQ_TOKEN = BANG_EQ_EQ_TOKEN + 1;
const int AMPERSAND_AMPERSAND_TOKEN = BANG_EQ_TOKEN + 1;
const int AMPERSAND_EQ_TOKEN = AMPERSAND_AMPERSAND_TOKEN + 1;
const int BAR_BAR_TOKEN = AMPERSAND_EQ_TOKEN + 1;
const int BAR_EQ_TOKEN = BAR_BAR_TOKEN + 1;
const int STAR_EQ_TOKEN = BAR_EQ_TOKEN + 1;
const int PLUS_PLUS_TOKEN = STAR_EQ_TOKEN + 1;
const int PLUS_EQ_TOKEN = PLUS_PLUS_TOKEN + 1;
const int MINUS_MINUS_TOKEN = PLUS_EQ_TOKEN + 1;
const int MINUS_EQ_TOKEN = MINUS_MINUS_TOKEN + 1;
const int TILDE_SLASH_EQ_TOKEN = MINUS_EQ_TOKEN + 1;
const int TILDE_SLASH_TOKEN = TILDE_SLASH_EQ_TOKEN + 1;
const int PERCENT_EQ_TOKEN = TILDE_SLASH_TOKEN + 1;
const int GT_GT_TOKEN = PERCENT_EQ_TOKEN + 1;
const int CARET_EQ_TOKEN = GT_GT_TOKEN + 1;
const int COMMENT_TOKEN = CARET_EQ_TOKEN + 1;
const int STRING_INTERPOLATION_IDENTIFIER_TOKEN = COMMENT_TOKEN + 1;

/**
 * A token that doubles as a linked list.
 */
abstract class Token implements Spannable {
  /**
   * The character offset of the start of this token within the source text.
   */
  final int charOffset;

  Token(this.charOffset);

  /**
   * The next token in the token stream.
   */
  Token next;

  /**
   * The precedence info for this token. [info] determines the kind and the
   * precedence level of this token.
   *
   * Defined as getter to save a field in the [KeywordToken] subclass.
   */
  PrecedenceInfo get info;

  /**
   * The string represented by this token, a substring of the source code.
   *
   * For [StringToken]s the [value] includes the quotes, explicit escapes, etc.
   */
  String get value;

  /**
   * For symbol and keyword tokens, returns the string value represented by this
   * token. For [StringToken]s this method returns [:null:].
   *
   * For [SymbolToken]s and [KeywordToken]s, the string value is a compile-time
   * constant originating in the [PrecedenceInfo] or in the [Keyword] instance.
   * This allows testing for keywords and symbols using [:identical:], e.g.,
   * [:identical('class', token.value):].
   *
   * Note that returning [:null:] for string tokens is important to identify
   * symbols and keywords, we cannot use [value] instead. The string literal
   *   "$a($b"
   * produces ..., SymbolToken($), StringToken(a), StringToken((), ...
   *
   * After parsing the identifier 'a', the parser tests for a function
   * declaration using [:identical(next.stringValue, '('):], which (rihgtfully)
   * returns false because stringValue returns [:null:].
   */
  String get stringValue;

  /**
   * The kind enum of this token as determined by its [info].
   */
  int get kind => info.kind;

  /**
   * The precedence level for this token.
   */
  int get precedence => info.precedence;

  /**
   * True if this token is an identifier. Some keywords allowed as identifiers,
   * see implementation in [KeywordToken].
   */
  bool isIdentifier();

  /**
   * Returns a textual representation of this token to be used for debugging
   * purposes. The resulting string might contain information about the
   * structure of the token, for example 'StringToken(foo)' for the identifier
   * token 'foo'.
   *
   * Use [value] for the text actually parsed by the token.
   */
  String toString();

  /**
   * The number of characters parsed by this token.
   */
  int get charCount {
    if (info == BAD_INPUT_INFO) {
      // This is a token that wraps around an error message. Return 1
      // instead of the size of the length of the error message.
      return 1;
    } else {
      return value.length;
    }
  }

  int get hashCode => computeHashCode(charOffset, info, value);
}

/// A pair of tokens marking the beginning and the end of a span. Use for error
/// reporting.
class TokenPair implements Spannable {
  final Token begin;
  final Token end;

  TokenPair(this.begin, this.end);
}

/**
 * A [SymbolToken] represents the symbol in its precendence info.
 * Also used for end of file with EOF_INFO.
 */
class SymbolToken extends Token {

  final PrecedenceInfo info;

  SymbolToken(this.info, int charOffset) : super(charOffset);

  String get value => info.value;

  String get stringValue => info.value;

  bool isIdentifier() => false;

  String toString() => "SymbolToken($value)";
}

/**
 * A [BeginGroupToken] represents a symbol that may be the beginning of
 * a pair of brackets, i.e., ( { [ < or ${
 * The [endGroup] token points to the matching closing bracked in case
 * it can be identified during scanning.
 */
class BeginGroupToken extends SymbolToken {
  Token endGroup;

  BeginGroupToken(PrecedenceInfo info, int charOffset)
      : super(info, charOffset);
}

/**
 * A keyword token.
 */
class KeywordToken extends Token {
  final Keyword keyword;

  KeywordToken(this.keyword, int charOffset) : super(charOffset);

  PrecedenceInfo get info => keyword.info;

  String get value => keyword.syntax;

  String get stringValue => keyword.syntax;

  bool isIdentifier() => keyword.isPseudo || keyword.isBuiltIn;

  String toString() => "KeywordToken($value)";
}

abstract class ErrorToken extends Token {
  ErrorToken(int charOffset)
      : super(charOffset);

  PrecedenceInfo get info => BAD_INPUT_INFO;

  String get value {
    throw new SpannableAssertionFailure(this, assertionMessage);
  }

  String get stringValue => null;

  bool isIdentifier() => false;

  String get assertionMessage;
}

class BadInputToken extends ErrorToken {
  final int character;

  BadInputToken(this.character, int charOffset)
      : super(charOffset);

  String toString() => "BadInputToken($character)";

  String get assertionMessage {
    return 'Character U+${character.toRadixString(16)} not allowed here.';
  }
}

class UnterminatedToken extends ErrorToken {
  final String start;
  final int endOffset;

  UnterminatedToken(this.start, int charOffset, this.endOffset)
      : super(charOffset);

  String toString() => "UnterminatedToken($start)";

  String get assertionMessage => "'$start' isn't terminated.";

  int get charCount => endOffset - charOffset;
}

class UnmatchedToken extends ErrorToken {
  final BeginGroupToken begin;

  UnmatchedToken(BeginGroupToken begin)
      : this.begin = begin,
        super(begin.charOffset);

  String toString() => "UnmatchedToken(${begin.value})";

  String get assertionMessage => "'$begin' isn't closed.";
}

/**
 * A String-valued token. Represents identifiers, string literals,
 * number literals, comments, and error tokens, using the corresponding
 * precedence info.
 */
class StringToken extends Token {
  /**
   * The length threshold above which substring tokens are computed lazily.
   *
   * For string tokens that are substrings of the program source, the actual
   * substring extraction is performed lazily. This is beneficial because
   * not all scanned code is actually used. For unused parts, the substrings
   * are never computed and allocated.
   */
  static const int LAZY_THRESHOLD = 4;

  var /* String | LazySubtring */ valueOrLazySubstring;

  final PrecedenceInfo info;

  /**
   * Creates a non-lazy string token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  StringToken.fromString(this.info, String value, int charOffset,
                         {bool canonicalize : false})
      : valueOrLazySubstring = canonicalizedString(value, canonicalize),
        super(charOffset);

  /**
   * Creates a lazy string token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  StringToken.fromSubstring(this.info, String data, int start, int end,
                            int charOffset, {bool canonicalize : false})
      : super(charOffset) {
    int length = end - start;
    if (length <= LAZY_THRESHOLD) {
      valueOrLazySubstring = canonicalizedString(data.substring(start, end),
                                                 canonicalize);
    } else {
      valueOrLazySubstring =
          new LazySubstring(data, start, length, canonicalize);
    }
  }

  /**
   * Creates a lazy string token. If [asciiOnly] is false, the byte array
   * is passed through a UTF-8 decoder.
   */
  StringToken.fromUtf8Bytes(this.info, List<int> data, int start, int end,
                            bool asciiOnly, int charOffset)
      : super(charOffset) {
    int length = end - start;
    if (length <= LAZY_THRESHOLD) {
      valueOrLazySubstring = decodeUtf8(data, start, end, asciiOnly);
    } else {
      valueOrLazySubstring = new LazySubstring(data, start, length, asciiOnly);
    }
  }

  String get value {
    if (valueOrLazySubstring is String) {
      return valueOrLazySubstring;
    } else {
      assert(valueOrLazySubstring is LazySubstring);
      var data = valueOrLazySubstring.data;
      int start = valueOrLazySubstring.start;
      int end = start + valueOrLazySubstring.length;
      if (data is String) {
        valueOrLazySubstring = canonicalizedString(
            data.substring(start, end), valueOrLazySubstring.boolValue);
      } else {
        valueOrLazySubstring = decodeUtf8(
            data, start, end, valueOrLazySubstring.boolValue);
      }
      return valueOrLazySubstring;
    }
  }

  String get stringValue => null;

  bool isIdentifier() => identical(kind, IDENTIFIER_TOKEN);

  String toString() => "StringToken($value)";

  static final HashSet<String> canonicalizedSubstrings =
      new HashSet<String>();

  static String canonicalizedString(String s, bool canonicalize) {
    if (!canonicalize) return s;
    var result = canonicalizedSubstrings.lookup(s);
    if (result != null) return result;
    canonicalizedSubstrings.add(s);
    return s;
  }

  static String decodeUtf8(List<int> data, int start, int end, bool asciiOnly) {
    var s;
    if (asciiOnly) {
      // getRange returns an iterator, it does not copy the data.
      s = new String.fromCharCodes(data.getRange(start, end));
    } else {
      // TODO(lry): this is measurably slow. Also sublist is copied eagerly.
      var bytes = data.sublist(start, end);
      s = UTF8.decode(bytes);
    }
    return canonicalizedString(s, true);
  }
}

/**
 * This class represents the necessary information to compute a substring
 * lazily. The substring can either originate from a string or from
 * a [:List<int>:] of UTF-8 bytes.
 */
abstract class LazySubstring {
  /** The original data, either a string or a List<int> */
  get data;

  int get start;
  int get length;

  /**
   * If this substring is based on a String, the [boolValue] indicates wheter
   * the resulting substring should be canonicalized.
   *
   * For substrings based on a byte array, the [boolValue] is true if the
   * array only holds ASCII characters. The resulting substring will be
   * canonicalized after decoding.
   */
  bool get boolValue;

  LazySubstring.internal();

  factory LazySubstring(data, int start, int length, bool b) {
    // See comment on [CompactLazySubstring].
    if (start < 0x100000 && length < 0x200) {
      int fields = (start << 9);
      fields = fields | length;
      fields = fields << 1;
      if (b) fields |= 1;
      return new CompactLazySubstring(data, fields);
    } else {
      return new FullLazySubstring(data, start, length, b);
    }
  }
}

/**
 * This class encodes [start], [length] and [boolValue] in a single
 * 30 bit integer. It uses 20 bits for [start], which covers source files
 * of 1MB. [length] has 9 bits, which covers 512 characters.
 *
 * The file html_dart2js.dart is currently around 1MB.
 */
class CompactLazySubstring extends LazySubstring {
  final data;
  final int fields;

  CompactLazySubstring(this.data, this.fields) : super.internal();

  int get start => fields >> 10;
  int get length => (fields >> 1) & 0x1ff;
  bool get boolValue => (fields & 1) == 1;
}

class FullLazySubstring extends LazySubstring {
  final data;
  final int start;
  final int length;
  final bool boolValue;
  FullLazySubstring(this.data, this.start, this.length, this.boolValue)
      : super.internal();
}

bool isUserDefinableOperator(String value) {
  return
      isBinaryOperator(value) ||
      isMinusOperator(value) ||
      isTernaryOperator(value) ||
      isUnaryOperator(value);
}

bool isUnaryOperator(String value) => identical(value, '~');

bool isBinaryOperator(String value) {
  return
      (identical(value, '==')) ||
      (identical(value, '[]')) ||
      (identical(value, '*')) ||
      (identical(value, '/')) ||
      (identical(value, '%')) ||
      (identical(value, '~/')) ||
      (identical(value, '+')) ||
      (identical(value, '<<')) ||
      (identical(value, '>>')) ||
      (identical(value, '>=')) ||
      (identical(value, '>')) ||
      (identical(value, '<=')) ||
      (identical(value, '<')) ||
      (identical(value, '&')) ||
      (identical(value, '^')) ||
      (identical(value, '|'));
}

bool isTernaryOperator(String value) => identical(value, '[]=');

bool isMinusOperator(String value) => identical(value, '-');

class PrecedenceInfo {
  final String value;
  final int precedence;
  final int kind;

  const PrecedenceInfo(this.value, this.precedence, this.kind);

  toString() => 'PrecedenceInfo($value, $precedence, $kind)';

  int get hashCode => computeHashCode(value, precedence, kind);
}

// TODO(ahe): The following are not tokens in Dart.
const PrecedenceInfo BACKPING_INFO =
  const PrecedenceInfo('`', 0, BACKPING_TOKEN);
const PrecedenceInfo BACKSLASH_INFO =
  const PrecedenceInfo('\\', 0, BACKSLASH_TOKEN);
const PrecedenceInfo PERIOD_PERIOD_PERIOD_INFO =
  const PrecedenceInfo('...', 0,
                       PERIOD_PERIOD_PERIOD_TOKEN);

/**
 * The cascade operator has the lowest precedence of any operator
 * except assignment.
 */
const int CASCADE_PRECEDENCE = 2;
const PrecedenceInfo PERIOD_PERIOD_INFO =
  const PrecedenceInfo('..', CASCADE_PRECEDENCE,
                       PERIOD_PERIOD_TOKEN);

const PrecedenceInfo BANG_INFO =
  const PrecedenceInfo('!', 0, BANG_TOKEN);
const PrecedenceInfo COLON_INFO =
  const PrecedenceInfo(':', 0, COLON_TOKEN);
const PrecedenceInfo INDEX_INFO =
  const PrecedenceInfo('[]', 0, INDEX_TOKEN);
const PrecedenceInfo MINUS_MINUS_INFO =
  const PrecedenceInfo('--', POSTFIX_PRECEDENCE,
                       MINUS_MINUS_TOKEN);
const PrecedenceInfo PLUS_PLUS_INFO =
  const PrecedenceInfo('++', POSTFIX_PRECEDENCE,
                       PLUS_PLUS_TOKEN);
const PrecedenceInfo TILDE_INFO =
  const PrecedenceInfo('~', 0, TILDE_TOKEN);

const PrecedenceInfo FUNCTION_INFO =
  const PrecedenceInfo('=>', 0, FUNCTION_TOKEN);
const PrecedenceInfo HASH_INFO =
  const PrecedenceInfo('#', 0, HASH_TOKEN);
const PrecedenceInfo INDEX_EQ_INFO =
  const PrecedenceInfo('[]=', 0, INDEX_EQ_TOKEN);
const PrecedenceInfo SEMICOLON_INFO =
  const PrecedenceInfo(';', 0, SEMICOLON_TOKEN);
const PrecedenceInfo COMMA_INFO =
  const PrecedenceInfo(',', 0, COMMA_TOKEN);

const PrecedenceInfo AT_INFO =
  const PrecedenceInfo('@', 0, AT_TOKEN);

// Assignment operators.
const int ASSIGNMENT_PRECEDENCE = 1;
const PrecedenceInfo AMPERSAND_EQ_INFO =
  const PrecedenceInfo('&=',
                       ASSIGNMENT_PRECEDENCE, AMPERSAND_EQ_TOKEN);
const PrecedenceInfo BAR_EQ_INFO =
  const PrecedenceInfo('|=',
                       ASSIGNMENT_PRECEDENCE, BAR_EQ_TOKEN);
const PrecedenceInfo CARET_EQ_INFO =
  const PrecedenceInfo('^=',
                       ASSIGNMENT_PRECEDENCE, CARET_EQ_TOKEN);
const PrecedenceInfo EQ_INFO =
  const PrecedenceInfo('=',
                       ASSIGNMENT_PRECEDENCE, EQ_TOKEN);
const PrecedenceInfo GT_GT_EQ_INFO =
  const PrecedenceInfo('>>=',
                       ASSIGNMENT_PRECEDENCE, GT_GT_EQ_TOKEN);
const PrecedenceInfo LT_LT_EQ_INFO =
  const PrecedenceInfo('<<=',
                       ASSIGNMENT_PRECEDENCE, LT_LT_EQ_TOKEN);
const PrecedenceInfo MINUS_EQ_INFO =
  const PrecedenceInfo('-=',
                       ASSIGNMENT_PRECEDENCE, MINUS_EQ_TOKEN);
const PrecedenceInfo PERCENT_EQ_INFO =
  const PrecedenceInfo('%=',
                       ASSIGNMENT_PRECEDENCE, PERCENT_EQ_TOKEN);
const PrecedenceInfo PLUS_EQ_INFO =
  const PrecedenceInfo('+=',
                       ASSIGNMENT_PRECEDENCE, PLUS_EQ_TOKEN);
const PrecedenceInfo SLASH_EQ_INFO =
  const PrecedenceInfo('/=',
                       ASSIGNMENT_PRECEDENCE, SLASH_EQ_TOKEN);
const PrecedenceInfo STAR_EQ_INFO =
  const PrecedenceInfo('*=',
                       ASSIGNMENT_PRECEDENCE, STAR_EQ_TOKEN);
const PrecedenceInfo TILDE_SLASH_EQ_INFO =
  const PrecedenceInfo('~/=',
                       ASSIGNMENT_PRECEDENCE, TILDE_SLASH_EQ_TOKEN);

const PrecedenceInfo QUESTION_INFO =
  const PrecedenceInfo('?', 3, QUESTION_TOKEN);

const PrecedenceInfo BAR_BAR_INFO =
  const PrecedenceInfo('||', 4, BAR_BAR_TOKEN);

const PrecedenceInfo AMPERSAND_AMPERSAND_INFO =
  const PrecedenceInfo('&&', 5, AMPERSAND_AMPERSAND_TOKEN);

const PrecedenceInfo BAR_INFO =
  const PrecedenceInfo('|', 8, BAR_TOKEN);

const PrecedenceInfo CARET_INFO =
  const PrecedenceInfo('^', 9, CARET_TOKEN);

const PrecedenceInfo AMPERSAND_INFO =
  const PrecedenceInfo('&', 10, AMPERSAND_TOKEN);

// Equality operators.
const int EQUALITY_PRECEDENCE = 6;
const PrecedenceInfo BANG_EQ_EQ_INFO =
  const PrecedenceInfo('!==',
                       EQUALITY_PRECEDENCE, BANG_EQ_EQ_TOKEN);
const PrecedenceInfo BANG_EQ_INFO =
  const PrecedenceInfo('!=',
                       EQUALITY_PRECEDENCE, BANG_EQ_TOKEN);
const PrecedenceInfo EQ_EQ_EQ_INFO =
  const PrecedenceInfo('===',
                       EQUALITY_PRECEDENCE, EQ_EQ_EQ_TOKEN);
const PrecedenceInfo EQ_EQ_INFO =
  const PrecedenceInfo('==',
                       EQUALITY_PRECEDENCE, EQ_EQ_TOKEN);

// Relational operators.
const int RELATIONAL_PRECEDENCE = 7;
const PrecedenceInfo GT_EQ_INFO =
  const PrecedenceInfo('>=',
                       RELATIONAL_PRECEDENCE, GT_EQ_TOKEN);
const PrecedenceInfo GT_INFO =
  const PrecedenceInfo('>',
                       RELATIONAL_PRECEDENCE, GT_TOKEN);
const PrecedenceInfo IS_INFO =
  const PrecedenceInfo('is',
                       RELATIONAL_PRECEDENCE, KEYWORD_TOKEN);
const PrecedenceInfo AS_INFO =
  const PrecedenceInfo('as',
                       RELATIONAL_PRECEDENCE, KEYWORD_TOKEN);
const PrecedenceInfo LT_EQ_INFO =
  const PrecedenceInfo('<=',
                       RELATIONAL_PRECEDENCE, LT_EQ_TOKEN);
const PrecedenceInfo LT_INFO =
  const PrecedenceInfo('<',
                       RELATIONAL_PRECEDENCE, LT_TOKEN);

// Shift operators.
const PrecedenceInfo GT_GT_INFO =
  const PrecedenceInfo('>>', 11, GT_GT_TOKEN);
const PrecedenceInfo LT_LT_INFO =
  const PrecedenceInfo('<<', 11, LT_LT_TOKEN);

// Additive operators.
const PrecedenceInfo MINUS_INFO =
  const PrecedenceInfo('-', 12, MINUS_TOKEN);
const PrecedenceInfo PLUS_INFO =
  const PrecedenceInfo('+', 12, PLUS_TOKEN);

// Multiplicative operators.
const PrecedenceInfo PERCENT_INFO =
  const PrecedenceInfo('%', 13, PERCENT_TOKEN);
const PrecedenceInfo SLASH_INFO =
  const PrecedenceInfo('/', 13, SLASH_TOKEN);
const PrecedenceInfo STAR_INFO =
  const PrecedenceInfo('*', 13, STAR_TOKEN);
const PrecedenceInfo TILDE_SLASH_INFO =
  const PrecedenceInfo('~/', 13, TILDE_SLASH_TOKEN);

const int POSTFIX_PRECEDENCE = 14;
const PrecedenceInfo PERIOD_INFO =
  const PrecedenceInfo('.', POSTFIX_PRECEDENCE,
                       PERIOD_TOKEN);

const PrecedenceInfo KEYWORD_INFO =
  const PrecedenceInfo('keyword', 0, KEYWORD_TOKEN);

const PrecedenceInfo EOF_INFO =
  const PrecedenceInfo('EOF', 0, EOF_TOKEN);

const PrecedenceInfo IDENTIFIER_INFO =
  const PrecedenceInfo('identifier', 0, IDENTIFIER_TOKEN);

const PrecedenceInfo BAD_INPUT_INFO =
  const PrecedenceInfo('malformed input', 0,
                       BAD_INPUT_TOKEN);

const PrecedenceInfo OPEN_PAREN_INFO =
  const PrecedenceInfo('(', POSTFIX_PRECEDENCE,
                       OPEN_PAREN_TOKEN);

const PrecedenceInfo CLOSE_PAREN_INFO =
  const PrecedenceInfo(')', 0, CLOSE_PAREN_TOKEN);

const PrecedenceInfo OPEN_CURLY_BRACKET_INFO =
  const PrecedenceInfo('{', 0, OPEN_CURLY_BRACKET_TOKEN);

const PrecedenceInfo CLOSE_CURLY_BRACKET_INFO =
  const PrecedenceInfo('}', 0, CLOSE_CURLY_BRACKET_TOKEN);

const PrecedenceInfo INT_INFO =
  const PrecedenceInfo('int', 0, INT_TOKEN);

const PrecedenceInfo STRING_INFO =
  const PrecedenceInfo('string', 0, STRING_TOKEN);

const PrecedenceInfo OPEN_SQUARE_BRACKET_INFO =
  const PrecedenceInfo('[', POSTFIX_PRECEDENCE,
                       OPEN_SQUARE_BRACKET_TOKEN);

const PrecedenceInfo CLOSE_SQUARE_BRACKET_INFO =
  const PrecedenceInfo(']', 0, CLOSE_SQUARE_BRACKET_TOKEN);

const PrecedenceInfo DOUBLE_INFO =
  const PrecedenceInfo('double', 0, DOUBLE_TOKEN);

const PrecedenceInfo STRING_INTERPOLATION_INFO =
  const PrecedenceInfo('\${', 0,
                       STRING_INTERPOLATION_TOKEN);

const PrecedenceInfo STRING_INTERPOLATION_IDENTIFIER_INFO =
  const PrecedenceInfo('\$', 0,
                       STRING_INTERPOLATION_IDENTIFIER_TOKEN);

const PrecedenceInfo HEXADECIMAL_INFO =
  const PrecedenceInfo('hexadecimal', 0, HEXADECIMAL_TOKEN);

const PrecedenceInfo COMMENT_INFO =
  const PrecedenceInfo('comment', 0, COMMENT_TOKEN);
