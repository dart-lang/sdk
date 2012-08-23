// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final int EOF_TOKEN = 0;

final int KEYWORD_TOKEN = $k;
final int IDENTIFIER_TOKEN = $a;
final int DOUBLE_TOKEN = $d;
final int INT_TOKEN = $i;
final int HEXADECIMAL_TOKEN = $x;
final int STRING_TOKEN = $SQ;

final int AMPERSAND_TOKEN = $AMPERSAND;
final int BACKPING_TOKEN = $BACKPING;
final int BACKSLASH_TOKEN = $BACKSLASH;
final int BANG_TOKEN = $BANG;
final int BAR_TOKEN = $BAR;
final int COLON_TOKEN = $COLON;
final int COMMA_TOKEN = $COMMA;
final int EQ_TOKEN = $EQ;
final int GT_TOKEN = $GT;
final int HASH_TOKEN = $HASH;
final int OPEN_CURLY_BRACKET_TOKEN = $OPEN_CURLY_BRACKET;
final int OPEN_SQUARE_BRACKET_TOKEN = $OPEN_SQUARE_BRACKET;
final int OPEN_PAREN_TOKEN = $OPEN_PAREN;
final int LT_TOKEN = $LT;
final int MINUS_TOKEN = $MINUS;
final int PERIOD_TOKEN = $PERIOD;
final int PLUS_TOKEN = $PLUS;
final int QUESTION_TOKEN = $QUESTION;
final int AT_TOKEN = $AT;
final int CLOSE_CURLY_BRACKET_TOKEN = $CLOSE_CURLY_BRACKET;
final int CLOSE_SQUARE_BRACKET_TOKEN = $CLOSE_SQUARE_BRACKET;
final int CLOSE_PAREN_TOKEN = $CLOSE_PAREN;
final int SEMICOLON_TOKEN = $SEMICOLON;
final int SLASH_TOKEN = $SLASH;
final int TILDE_TOKEN = $TILDE;
final int STAR_TOKEN = $STAR;
final int PERCENT_TOKEN = $PERCENT;
final int CARET_TOKEN = $CARET;

final int STRING_INTERPOLATION_TOKEN = 128;
final int LT_EQ_TOKEN = STRING_INTERPOLATION_TOKEN + 1;
final int FUNCTION_TOKEN = LT_EQ_TOKEN + 1;
final int SLASH_EQ_TOKEN = FUNCTION_TOKEN + 1;
final int PERIOD_PERIOD_PERIOD_TOKEN = SLASH_EQ_TOKEN + 1;
final int PERIOD_PERIOD_TOKEN = PERIOD_PERIOD_PERIOD_TOKEN + 1;
final int EQ_EQ_EQ_TOKEN = PERIOD_PERIOD_TOKEN + 1;
final int EQ_EQ_TOKEN = EQ_EQ_EQ_TOKEN + 1;
final int LT_LT_EQ_TOKEN = EQ_EQ_TOKEN + 1;
final int LT_LT_TOKEN = LT_LT_EQ_TOKEN + 1;
final int GT_EQ_TOKEN = LT_LT_TOKEN + 1;
final int GT_GT_EQ_TOKEN = GT_EQ_TOKEN + 1;
final int GT_GT_GT_EQ_TOKEN = GT_GT_EQ_TOKEN + 1;
final int INDEX_EQ_TOKEN = GT_GT_GT_EQ_TOKEN + 1;
final int INDEX_TOKEN = INDEX_EQ_TOKEN + 1;
final int BANG_EQ_EQ_TOKEN = INDEX_TOKEN + 1;
final int BANG_EQ_TOKEN = BANG_EQ_EQ_TOKEN + 1;
final int AMPERSAND_AMPERSAND_TOKEN = BANG_EQ_TOKEN + 1;
final int AMPERSAND_EQ_TOKEN = AMPERSAND_AMPERSAND_TOKEN + 1;
final int BAR_BAR_TOKEN = AMPERSAND_EQ_TOKEN + 1;
final int BAR_EQ_TOKEN = BAR_BAR_TOKEN + 1;
final int STAR_EQ_TOKEN = BAR_EQ_TOKEN + 1;
final int PLUS_PLUS_TOKEN = STAR_EQ_TOKEN + 1;
final int PLUS_EQ_TOKEN = PLUS_PLUS_TOKEN + 1;
final int MINUS_MINUS_TOKEN = PLUS_EQ_TOKEN + 1;
final int MINUS_EQ_TOKEN = MINUS_MINUS_TOKEN + 1;
final int TILDE_SLASH_EQ_TOKEN = MINUS_EQ_TOKEN + 1;
final int TILDE_SLASH_TOKEN = TILDE_SLASH_EQ_TOKEN + 1;
final int PERCENT_EQ_TOKEN = TILDE_SLASH_TOKEN + 1;
final int GT_GT_TOKEN = PERCENT_EQ_TOKEN + 1;
final int CARET_EQ_TOKEN = GT_GT_TOKEN + 1;
final int IS_TOKEN = CARET_EQ_TOKEN + 1;
final int AS_TOKEN = IS_TOKEN + 1;
final int COMMENT_TOKEN = AS_TOKEN + 1;
final int GT_GT_GT_TOKEN = COMMENT_TOKEN + 1;
final int STRING_INTERPOLATION_IDENTIFIER_TOKEN = COMMENT_TOKEN + 1;

// TODO(ahe): Get rid of this.
final int UNKNOWN_TOKEN = 1024;

/**
 * A token that doubles as a linked list.
 */
class Token {
  /**
   * The precedence info for this token. [info] determines the kind and the
   * precedence level of this token.
   */
  final PrecedenceInfo info;

  /**
   * The character offset of the start of this token within the source text.
   */
  final int charOffset;

  /**
   * The next token in the token stream.
   */
  Token next;

  Token(PrecedenceInfo this.info, int this.charOffset);

  get value => info.value;

  /**
   * Returns the string value for keywords and symbols. For instance 'class' for
   * the [CLASS] keyword token and '*' for a [Token] based on [STAR_INFO]. For
   * other tokens, such identifiers, strings, numbers, etc, [stringValue]
   * returns [:null:].
   *
   * [stringValue] should only be used for testing keywords and symbols.
   */
  String get stringValue => info.value.stringValue;

  /**
   * The kind enum of this token as determined by its [info].
   */
  int get kind => info.kind;

  /**
   * The precedence level for this token.
   */
  int get precedence => info.precedence;

  /**
   * Returns a textual representation of this token to be used for debugging
   * purposes. The resulting string might contain information about the
   * structure of the token, for example 'StringToken(foo)' for the identifier
   * token 'foo'. Use [slowToString] for the text actually parsed by the token.
   */
  String toString() => info.value.toString();

  /**
   * The text parsed by this token.
   */
  String slowToString() => toString();

  /**
   * The number of characters parsed by this token.
   */
  int get slowCharCount => slowToString().length;
}

/**
 * A keyword token.
 */
class KeywordToken extends Token {
  final Keyword value;
  String get stringValue => value.syntax;

  KeywordToken(Keyword value, int charOffset)
    : this.value = value, super(value.info, charOffset);

  String toString() => value.syntax;
}

/**
 * A String-valued token.
 */
class StringToken extends Token {
  final SourceString value;
  String get stringValue => value.stringValue;

  StringToken(PrecedenceInfo info, String value, int charOffset)
    : this.fromSource(info, new SourceString(value), charOffset);

  StringToken.fromSource(PrecedenceInfo info, this.value, int charOffset)
    : super(info, charOffset);

  String toString() => "StringToken(${value.slowToString()})";

  String slowToString() => value.slowToString();
}

interface SourceString extends Hashable, Iterable<int> default StringWrapper {
  const SourceString(String string);

  void printOn(StringBuffer sb);

  /** Gives a [SourceString] that is not including the [initial] first and
   * [terminal] last characters. This is only intended to be used to remove
   * quotes from string literals (including an initial '@' for raw strings).
   */
  SourceString copyWithoutQuotes(int initial, int terminal);

  String get stringValue();

  String slowToString();

  bool isEmpty();

  bool isPrivate();
}

class StringWrapper implements SourceString {
  final String stringValue;

  const StringWrapper(String this.stringValue);

  int hashCode() => stringValue.hashCode();

  bool operator ==(other) {
    return other is SourceString && toString() == other.slowToString();
  }

  Iterator<int> iterator() => new StringCodeIterator(stringValue);

  void printOn(StringBuffer sb) {
    sb.add(stringValue);
  }

  String toString() => stringValue;

  String slowToString() => stringValue;

  SourceString copyWithoutQuotes(int initial, int terminal) {
    assert(0 <= initial);
    assert(0 <= terminal);
    assert(initial + terminal <= stringValue.length);
    return new StringWrapper(
        stringValue.substring(initial, stringValue.length - terminal));
  }

  bool isEmpty() => stringValue.isEmpty();

  bool isPrivate() => !isEmpty() && stringValue.charCodeAt(0) === $_;
}

class StringCodeIterator implements Iterator<int> {
  final String string;
  int index;
  final int end;

  StringCodeIterator(String string) :
    this.string = string, index = 0, end = string.length;

  StringCodeIterator.substring(this.string, this.index, this.end) {
    assert(0 <= index);
    assert(index <= end);
    assert(end <= string.length);
  }

  bool hasNext() => index < end;
  int next() => string.charCodeAt(index++);
}

class BeginGroupToken extends StringToken {
  Token endGroup;
  BeginGroupToken(PrecedenceInfo info, String value, int charOffset)
    : super(info, value, charOffset);
}

bool isUserDefinableOperator(String value) {
  return
    (value === '==') ||
    (value === '~') ||
    (value === 'negate') ||
    (value === '[]') ||
    (value === '[]=') ||
    (value === '*') ||
    (value === '/') ||
    (value === '%') ||
    (value === '~/') ||
    (value === '+') ||
    (value === '-') ||
    (value === '<<') ||
    (value === '>>>') ||
    (value === '>>') ||
    (value === '>=') ||
    (value === '>') ||
    (value === '<=') ||
    (value === '<') ||
    (value === '&') ||
    (value === '^') ||
    (value === '|');
}

class PrecedenceInfo {
  final SourceString value;
  final int precedence;
  final int kind;

  const PrecedenceInfo(this.value, this.precedence, this.kind);

  toString() => 'PrecedenceInfo($value, $precedence, $kind)';
}

// TODO(ahe): The following are not tokens in Dart.
final PrecedenceInfo BACKPING_INFO =
  const PrecedenceInfo(const SourceString('`'), 0, BACKPING_TOKEN);
final PrecedenceInfo BACKSLASH_INFO =
  const PrecedenceInfo(const SourceString('\\'), 0, BACKSLASH_TOKEN);
final PrecedenceInfo PERIOD_PERIOD_PERIOD_INFO =
  const PrecedenceInfo(const SourceString('...'), 0,
                       PERIOD_PERIOD_PERIOD_TOKEN);

/**
 * The cascade operator has the lowest precedence of any operator
 * except assignment.
 */
final int CASCADE_PRECEDENCE = 2;
final PrecedenceInfo PERIOD_PERIOD_INFO =
  const PrecedenceInfo(const SourceString('..'), CASCADE_PRECEDENCE,
                       PERIOD_PERIOD_TOKEN);

final PrecedenceInfo BANG_INFO =
  const PrecedenceInfo(const SourceString('!'), 0, BANG_TOKEN);
final PrecedenceInfo COLON_INFO =
  const PrecedenceInfo(const SourceString(':'), 0, COLON_TOKEN);
final PrecedenceInfo INDEX_INFO =
  const PrecedenceInfo(const SourceString('[]'), 0, INDEX_TOKEN);
final PrecedenceInfo MINUS_MINUS_INFO =
  const PrecedenceInfo(const SourceString('--'), POSTFIX_PRECEDENCE,
                       MINUS_MINUS_TOKEN);
final PrecedenceInfo PLUS_PLUS_INFO =
  const PrecedenceInfo(const SourceString('++'), POSTFIX_PRECEDENCE,
                       PLUS_PLUS_TOKEN);
final PrecedenceInfo TILDE_INFO =
  const PrecedenceInfo(const SourceString('~'), 0, TILDE_TOKEN);

final PrecedenceInfo FUNCTION_INFO =
  const PrecedenceInfo(const SourceString('=>'), 0, FUNCTION_TOKEN);
final PrecedenceInfo HASH_INFO =
  const PrecedenceInfo(const SourceString('#'), 0, HASH_TOKEN);
final PrecedenceInfo INDEX_EQ_INFO =
  const PrecedenceInfo(const SourceString('[]='), 0, INDEX_EQ_TOKEN);
final PrecedenceInfo SEMICOLON_INFO =
  const PrecedenceInfo(const SourceString(';'), 0, SEMICOLON_TOKEN);
final PrecedenceInfo COMMA_INFO =
  const PrecedenceInfo(const SourceString(','), 0, COMMA_TOKEN);

final PrecedenceInfo AT_INFO =
  const PrecedenceInfo(const SourceString('@'), 0, AT_TOKEN);

// Assignment operators.
final int ASSIGNMENT_PRECEDENCE = 1;
final PrecedenceInfo AMPERSAND_EQ_INFO =
  const PrecedenceInfo(const SourceString('&='),
                       ASSIGNMENT_PRECEDENCE, AMPERSAND_EQ_TOKEN);
final PrecedenceInfo BAR_EQ_INFO =
  const PrecedenceInfo(const SourceString('|='),
                       ASSIGNMENT_PRECEDENCE, BAR_EQ_TOKEN);
final PrecedenceInfo CARET_EQ_INFO =
  const PrecedenceInfo(const SourceString('^='),
                       ASSIGNMENT_PRECEDENCE, CARET_EQ_TOKEN);
final PrecedenceInfo EQ_INFO =
  const PrecedenceInfo(const SourceString('='),
                       ASSIGNMENT_PRECEDENCE, EQ_TOKEN);
final PrecedenceInfo GT_GT_EQ_INFO =
  const PrecedenceInfo(const SourceString('>>='),
                       ASSIGNMENT_PRECEDENCE, GT_GT_EQ_TOKEN);
final PrecedenceInfo GT_GT_GT_EQ_INFO =
  const PrecedenceInfo(const SourceString('>>>='),
                       ASSIGNMENT_PRECEDENCE, GT_GT_GT_EQ_TOKEN);
final PrecedenceInfo LT_LT_EQ_INFO =
  const PrecedenceInfo(const SourceString('<<='),
                       ASSIGNMENT_PRECEDENCE, LT_LT_EQ_TOKEN);
final PrecedenceInfo MINUS_EQ_INFO =
  const PrecedenceInfo(const SourceString('-='),
                       ASSIGNMENT_PRECEDENCE, MINUS_EQ_TOKEN);
final PrecedenceInfo PERCENT_EQ_INFO =
  const PrecedenceInfo(const SourceString('%='),
                       ASSIGNMENT_PRECEDENCE, PERCENT_EQ_TOKEN);
final PrecedenceInfo PLUS_EQ_INFO =
  const PrecedenceInfo(const SourceString('+='),
                       ASSIGNMENT_PRECEDENCE, PLUS_EQ_TOKEN);
final PrecedenceInfo SLASH_EQ_INFO =
  const PrecedenceInfo(const SourceString('/='),
                       ASSIGNMENT_PRECEDENCE, SLASH_EQ_TOKEN);
final PrecedenceInfo STAR_EQ_INFO =
  const PrecedenceInfo(const SourceString('*='),
                       ASSIGNMENT_PRECEDENCE, STAR_EQ_TOKEN);
final PrecedenceInfo TILDE_SLASH_EQ_INFO =
  const PrecedenceInfo(const SourceString('~/='),
                       ASSIGNMENT_PRECEDENCE, TILDE_SLASH_EQ_TOKEN);

final PrecedenceInfo QUESTION_INFO =
  const PrecedenceInfo(const SourceString('?'), 3, QUESTION_TOKEN);

final PrecedenceInfo BAR_BAR_INFO =
  const PrecedenceInfo(const SourceString('||'), 4, BAR_BAR_TOKEN);

final PrecedenceInfo AMPERSAND_AMPERSAND_INFO =
  const PrecedenceInfo(const SourceString('&&'), 5, AMPERSAND_AMPERSAND_TOKEN);

final PrecedenceInfo BAR_INFO =
  const PrecedenceInfo(const SourceString('|'), 6, BAR_TOKEN);

final PrecedenceInfo CARET_INFO =
  const PrecedenceInfo(const SourceString('^'), 7, CARET_TOKEN);

final PrecedenceInfo AMPERSAND_INFO =
  const PrecedenceInfo(const SourceString('&'), 8, AMPERSAND_TOKEN);

// Equality operators.
final PrecedenceInfo BANG_EQ_EQ_INFO =
  const PrecedenceInfo(const SourceString('!=='), 9, BANG_EQ_EQ_TOKEN);
final PrecedenceInfo BANG_EQ_INFO =
  const PrecedenceInfo(const SourceString('!='), 9, BANG_EQ_TOKEN);
final PrecedenceInfo EQ_EQ_EQ_INFO =
  const PrecedenceInfo(const SourceString('==='), 9, EQ_EQ_EQ_TOKEN);
final PrecedenceInfo EQ_EQ_INFO =
  const PrecedenceInfo(const SourceString('=='), 9, EQ_EQ_TOKEN);

// Relational operators.
final PrecedenceInfo GT_EQ_INFO =
  const PrecedenceInfo(const SourceString('>='), 10, GT_EQ_TOKEN);
final PrecedenceInfo GT_INFO =
  const PrecedenceInfo(const SourceString('>'), 10, GT_TOKEN);
final PrecedenceInfo IS_INFO =
  const PrecedenceInfo(const SourceString('is'), 10, IS_TOKEN);
final PrecedenceInfo AS_INFO =
  const PrecedenceInfo(const SourceString('as'), 10, AS_TOKEN);
final PrecedenceInfo LT_EQ_INFO =
  const PrecedenceInfo(const SourceString('<='), 10, LT_EQ_TOKEN);
final PrecedenceInfo LT_INFO =
  const PrecedenceInfo(const SourceString('<'), 10, LT_TOKEN);

// Shift operators.
final PrecedenceInfo GT_GT_GT_INFO =
  const PrecedenceInfo(const SourceString('>>>'), 11, GT_GT_GT_TOKEN);
final PrecedenceInfo GT_GT_INFO =
  const PrecedenceInfo(const SourceString('>>'), 11, GT_GT_TOKEN);
final PrecedenceInfo LT_LT_INFO =
  const PrecedenceInfo(const SourceString('<<'), 11, LT_LT_TOKEN);

// Additive operators.
final PrecedenceInfo MINUS_INFO =
  const PrecedenceInfo(const SourceString('-'), 12, MINUS_TOKEN);
final PrecedenceInfo PLUS_INFO =
  const PrecedenceInfo(const SourceString('+'), 12, PLUS_TOKEN);

// Multiplicative operators.
final PrecedenceInfo PERCENT_INFO =
  const PrecedenceInfo(const SourceString('%'), 13, PERCENT_TOKEN);
final PrecedenceInfo SLASH_INFO =
  const PrecedenceInfo(const SourceString('/'), 13, SLASH_TOKEN);
final PrecedenceInfo STAR_INFO =
  const PrecedenceInfo(const SourceString('*'), 13, STAR_TOKEN);
final PrecedenceInfo TILDE_SLASH_INFO =
  const PrecedenceInfo(const SourceString('~/'), 13, TILDE_SLASH_TOKEN);

final int POSTFIX_PRECEDENCE = 14;
final PrecedenceInfo PERIOD_INFO =
  const PrecedenceInfo(const SourceString('.'), POSTFIX_PRECEDENCE,
                       PERIOD_TOKEN);

final PrecedenceInfo KEYWORD_INFO =
  const PrecedenceInfo(const SourceString('keyword'), 0, KEYWORD_TOKEN);

final PrecedenceInfo EOF_INFO =
  const PrecedenceInfo(const SourceString('EOF'), 0, EOF_TOKEN);

final PrecedenceInfo IDENTIFIER_INFO =
  const PrecedenceInfo(const SourceString('identifier'), 0, IDENTIFIER_TOKEN);

final PrecedenceInfo OPEN_PAREN_INFO =
  const PrecedenceInfo(const SourceString('('), POSTFIX_PRECEDENCE,
                       OPEN_PAREN_TOKEN);

final PrecedenceInfo CLOSE_PAREN_INFO =
  const PrecedenceInfo(const SourceString(')'), 0, CLOSE_PAREN_TOKEN);

final PrecedenceInfo OPEN_CURLY_BRACKET_INFO =
  const PrecedenceInfo(const SourceString('{'), 0, OPEN_CURLY_BRACKET_TOKEN);

final PrecedenceInfo CLOSE_CURLY_BRACKET_INFO =
  const PrecedenceInfo(const SourceString('}'), 0, CLOSE_CURLY_BRACKET_TOKEN);

final PrecedenceInfo INT_INFO =
  const PrecedenceInfo(const SourceString('int'), 0, INT_TOKEN);

final PrecedenceInfo STRING_INFO =
  const PrecedenceInfo(const SourceString('string'), 0, STRING_TOKEN);

final PrecedenceInfo OPEN_SQUARE_BRACKET_INFO =
  const PrecedenceInfo(const SourceString('['), POSTFIX_PRECEDENCE,
                       OPEN_SQUARE_BRACKET_TOKEN);

final PrecedenceInfo CLOSE_SQUARE_BRACKET_INFO =
  const PrecedenceInfo(const SourceString(']'), 0, CLOSE_SQUARE_BRACKET_TOKEN);

final PrecedenceInfo DOUBLE_INFO =
  const PrecedenceInfo(const SourceString('double'), 0, DOUBLE_TOKEN);

final PrecedenceInfo STRING_INTERPOLATION_INFO =
  const PrecedenceInfo(const SourceString('\${'), 0,
                       STRING_INTERPOLATION_TOKEN);

final PrecedenceInfo STRING_INTERPOLATION_IDENTIFIER_INFO =
  const PrecedenceInfo(const SourceString('\$'), 0,
                       STRING_INTERPOLATION_IDENTIFIER_TOKEN);

final PrecedenceInfo HEXADECIMAL_INFO =
  const PrecedenceInfo(const SourceString('hexadecimal'), 0, HEXADECIMAL_TOKEN);

final PrecedenceInfo COMMENT_INFO =
  const PrecedenceInfo(const SourceString('comment'), 0, COMMENT_TOKEN);

// For reporting lexical errors.
final PrecedenceInfo ERROR_INFO =
  const PrecedenceInfo(const SourceString('?'), 0, UNKNOWN_TOKEN);
