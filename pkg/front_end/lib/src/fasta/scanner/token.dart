// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.token;

import '../../scanner/token.dart' as analyzer;
import '../../scanner/token.dart' show TokenType;

import 'token_constants.dart' show IDENTIFIER_TOKEN;

import 'string_canonicalizer.dart';

/**
 * A token that doubles as a linked list.
 */
abstract class Token implements analyzer.TokenWithComment {
  @override
  int charOffset;

  Token(this.charOffset);

  @override
  analyzer.Token next;

  @override
  analyzer.Token previous;

  @override
  analyzer.CommentToken precedingComments;

  @override
  String get stringValue => type.stringValue;

  @override
  int get kind => type.kind;

  /**
   * Returns a textual representation of this token to be used for debugging
   * purposes. The resulting string might contain information about the
   * structure of the token, for example 'StringToken(foo)' for the identifier
   * token 'foo'.
   *
   * Use [lexeme] for the text actually parsed by the token.
   */
  String toString();

  @override
  int get charCount => lexeme.length;

  @override
  int get charEnd => charOffset + charCount;

  @override
  bool get isEof => type == analyzer.TokenType.EOF;

  bool get isBuiltInIdentifier => false;

  @override
  bool get isOperator => type.isOperator;

  @override
  bool get isUserDefinableOperator => type.isUserDefinableOperator;

  @override
  int get offset => charOffset;

  @override
  set offset(int newOffset) {
    charOffset = newOffset;
  }

  @override
  int get length => charCount;

  @override
  int get end => charEnd;

  @override
  void applyDelta(int delta) {
    charOffset += delta;
    CommentToken token = precedingComments;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }

  @override
  analyzer.Token copy() {
    return copyWithoutComments()
      ..precedingComments = copyComments(precedingComments);
  }

  @override
  analyzer.Token copyComments(analyzer.Token token) {
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

  /// Return a copy of the receiver without [preceedingComments].
  Token copyWithoutComments();

  @override
  bool get isSynthetic => false;

  @override
  analyzer.Keyword get keyword => null;

  @override
  bool matchesAny(List<analyzer.TokenType> types) {
    for (analyzer.TokenType type in types) {
      if (this.type == type) {
        return true;
      }
    }
    return false;
  }

  @override
  analyzer.Token setNext(analyzer.Token token) {
    next = token as Token;
    next.previous = this;
    return token;
  }

  @override
  analyzer.Token setNextWithoutSettingPrevious(analyzer.Token token) {
    next = token as Token;
    return token;
  }

  @override
  Object value() => lexeme;
}

/**
 * A [SymbolToken] represents the symbol in its precedence info.
 * Also used for end of file with EOF_INFO.
 */
class SymbolToken extends Token {
  final TokenType type;

  SymbolToken(this.type, int charOffset) : super(charOffset);

  factory SymbolToken.eof(int charOffset) {
    var eof = new SyntheticSymbolToken(analyzer.TokenType.EOF, charOffset);
    // EOF points to itself so there's always infinite look-ahead.
    eof.previous = eof;
    eof.next = eof;
    return eof;
  }

  @override
  String get lexeme => type.value;

  @override
  bool get isIdentifier => false;

  @override
  String toString() => "SymbolToken(${isEof ? '-eof-' : lexeme})";

  @override
  Token copyWithoutComments() => isEof
      ? new SymbolToken.eof(charOffset)
      : new SymbolToken(type, charOffset);
}

/**
 * A [SyntheticSymbolToken] represents the symbol in its precedence info
 * which does not exist in the original source.
 * For example, if the scanner finds '(' missing a ')'
 * then it will insert an synthetic ')'.
 */
class SyntheticSymbolToken extends SymbolToken {
  SyntheticSymbolToken(TokenType type, int charOffset)
      : super(type, charOffset);

  @override
  int get charCount => 0;

  @override
  bool get isSynthetic => true;

  @override
  Token copyWithoutComments() => isEof
      ? new SymbolToken.eof(charOffset)
      : new SyntheticSymbolToken(type, charOffset);
}

/**
 * A [BeginGroupToken] represents a symbol that may be the beginning of
 * a pair of brackets, i.e., ( { [ < or ${
 * The [endGroup] token points to the matching closing bracket in case
 * it can be identified during scanning.
 */
class BeginGroupToken extends SymbolToken
    implements analyzer.BeginTokenWithComment {
  Token endGroup;

  BeginGroupToken(TokenType type, int charOffset) : super(type, charOffset);

  @override
  analyzer.Token get endToken => endGroup;

  @override
  void set endToken(analyzer.Token token) {
    endGroup = token;
  }

  @override
  Token copyWithoutComments() => new BeginGroupToken(type, charOffset);
}

/**
 * A keyword token.
 */
class KeywordToken extends Token implements analyzer.KeywordTokenWithComment {
  final analyzer.Keyword keyword;

  KeywordToken(this.keyword, int charOffset) : super(charOffset);

  @override
  String get lexeme => keyword.lexeme;

  @override
  bool get isIdentifier => keyword.isPseudo || keyword.isBuiltIn;

  @override
  bool get isBuiltInIdentifier => keyword.isBuiltIn;

  @override
  String toString() => "KeywordToken($lexeme)";

  @override
  Token copyWithoutComments() => new KeywordToken(keyword, charOffset);

  @override
  analyzer.Keyword value() => keyword;

  @override
  analyzer.TokenType get type => keyword;
}

/**
 * A synthetic keyword token.
 */
class SyntheticKeywordToken extends KeywordToken
    implements analyzer.SyntheticKeywordToken {
  /**
   * Initialize a newly created token to represent the given [keyword] at the
   * given [offset].
   */
  SyntheticKeywordToken(analyzer.Keyword keyword, int offset)
      : super(keyword, offset);

  @override
  bool get isSynthetic => true;

  @override
  int get length => 0;

  @override
  Token copyWithoutComments() => new SyntheticKeywordToken(keyword, offset);
}

/**
 * A String-valued token. Represents identifiers, string literals,
 * number literals, comments, and error tokens, using the corresponding
 * precedence info.
 */
class StringToken extends Token implements analyzer.StringTokenWithComment {
  /**
   * The length threshold above which substring tokens are computed lazily.
   *
   * For string tokens that are substrings of the program source, the actual
   * substring extraction is performed lazily. This is beneficial because
   * not all scanned code are actually used. For unused parts, the substrings
   * are never computed and allocated.
   */
  static const int LAZY_THRESHOLD = 4;

  var /* String | LazySubtring */ valueOrLazySubstring;

  @override
  final TokenType type;

  /**
   * Creates a non-lazy string token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  StringToken.fromString(this.type, String value, int charOffset,
      {bool canonicalize: false})
      : valueOrLazySubstring =
            canonicalizedString(value, 0, value.length, canonicalize),
        super(charOffset);

  /**
   * Creates a lazy string token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  StringToken.fromSubstring(
      this.type, String data, int start, int end, int charOffset,
      {bool canonicalize: false})
      : super(charOffset) {
    int length = end - start;
    if (length <= LAZY_THRESHOLD) {
      valueOrLazySubstring =
          canonicalizedString(data, start, end, canonicalize);
    } else {
      valueOrLazySubstring =
          new _LazySubstring(data, start, length, canonicalize);
    }
  }

  /**
   * Creates a lazy string token. If [asciiOnly] is false, the byte array
   * is passed through a UTF-8 decoder.
   */
  StringToken.fromUtf8Bytes(this.type, List<int> data, int start, int end,
      bool asciiOnly, int charOffset)
      : super(charOffset) {
    int length = end - start;
    if (length <= LAZY_THRESHOLD) {
      valueOrLazySubstring = decodeUtf8(data, start, end, asciiOnly);
    } else {
      valueOrLazySubstring = new _LazySubstring(data, start, length, asciiOnly);
    }
  }

  StringToken._(this.type, this.valueOrLazySubstring, int charOffset)
      : super(charOffset);

  @override
  String get lexeme {
    if (valueOrLazySubstring is String) {
      return valueOrLazySubstring;
    } else {
      assert(valueOrLazySubstring is _LazySubstring);
      var data = valueOrLazySubstring.data;
      int start = valueOrLazySubstring.start;
      int end = start + valueOrLazySubstring.length;
      if (data is String) {
        valueOrLazySubstring = canonicalizedString(
            data, start, end, valueOrLazySubstring.boolValue);
      } else {
        valueOrLazySubstring =
            decodeUtf8(data, start, end, valueOrLazySubstring.boolValue);
      }
      return valueOrLazySubstring;
    }
  }

  @override
  bool get isIdentifier => identical(kind, IDENTIFIER_TOKEN);

  @override
  String toString() => "StringToken($lexeme)";

  static final StringCanonicalizer canonicalizer = new StringCanonicalizer();

  static String canonicalizedString(
      String s, int start, int end, bool canonicalize) {
    if (!canonicalize) return s;
    return canonicalizer.canonicalize(s, start, end, false);
  }

  static String decodeUtf8(List<int> data, int start, int end, bool asciiOnly) {
    return canonicalizer.canonicalize(data, start, end, asciiOnly);
  }

  @override
  Token copyWithoutComments() =>
      new StringToken._(type, valueOrLazySubstring, charOffset);

  @override
  String value() => lexeme;
}

/**
 * A String-valued token that does not exist in the original source.
 */
class SyntheticStringToken extends StringToken
    implements analyzer.SyntheticStringToken {
  SyntheticStringToken(TokenType type, String value, int offset)
      : super._(type, value, offset);

  @override
  bool get isSynthetic => true;

  @override
  int get length => 0;

  @override
  Token copyWithoutComments() =>
      new SyntheticStringToken(type, valueOrLazySubstring, offset);
}

class CommentToken extends StringToken implements analyzer.CommentToken {
  @override
  analyzer.TokenWithComment parent;

  /**
   * Creates a lazy comment token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  CommentToken.fromSubstring(
      TokenType type, String data, int start, int end, int charOffset,
      {bool canonicalize: false})
      : super.fromSubstring(type, data, start, end, charOffset,
            canonicalize: canonicalize);

  /**
   * Creates a non-lazy comment token.
   */
  CommentToken.fromString(TokenType type, String lexeme, int charOffset)
      : super.fromString(type, lexeme, charOffset);

  /**
   * Creates a lazy string token. If [asciiOnly] is false, the byte array
   * is passed through a UTF-8 decoder.
   */
  CommentToken.fromUtf8Bytes(TokenType type, List<int> data, int start, int end,
      bool asciiOnly, int charOffset)
      : super.fromUtf8Bytes(type, data, start, end, asciiOnly, charOffset);

  CommentToken._(TokenType type, valueOrLazySubstring, int charOffset)
      : super._(type, valueOrLazySubstring, charOffset);

  @override
  CommentToken copy() =>
      new CommentToken._(type, valueOrLazySubstring, charOffset);

  @override
  void remove() {
    if (previous != null) {
      previous.setNextWithoutSettingPrevious(next);
      next?.previous = previous;
    } else {
      assert(parent.precedingComments == this);
      parent.precedingComments = next as CommentToken;
    }
  }
}

class DartDocToken extends CommentToken
    implements analyzer.DocumentationCommentToken {
  @override
  final List<Token> references = <Token>[];

  /**
   * Creates a lazy comment token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  DartDocToken.fromSubstring(
      TokenType type, String data, int start, int end, int charOffset,
      {bool canonicalize: false})
      : super.fromSubstring(type, data, start, end, charOffset,
            canonicalize: canonicalize);

  /**
   * Creates a lazy string token. If [asciiOnly] is false, the byte array
   * is passed through a UTF-8 decoder.
   */
  DartDocToken.fromUtf8Bytes(TokenType type, List<int> data, int start, int end,
      bool asciiOnly, int charOffset)
      : super.fromUtf8Bytes(type, data, start, end, asciiOnly, charOffset);

  DartDocToken._(TokenType type, valueOrLazySubstring, int charOffset)
      : super._(type, valueOrLazySubstring, charOffset);

  @override
  DartDocToken copy() {
    DartDocToken copy =
        new DartDocToken._(type, valueOrLazySubstring, charOffset);
    references.forEach((ref) => copy.references.add(ref.copy()));
    return copy;
  }
}

/**
 * This class represents the necessary information to compute a substring
 * lazily. The substring can either originate from a string or from
 * a [:List<int>:] of UTF-8 bytes.
 */
abstract class _LazySubstring {
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

  _LazySubstring.internal();

  factory _LazySubstring(data, int start, int length, bool b) {
    // See comment on [CompactLazySubstring].
    if (start < 0x100000 && length < 0x200) {
      int fields = (start << 9);
      fields = fields | length;
      fields = fields << 1;
      if (b) fields |= 1;
      return new _CompactLazySubstring(data, fields);
    } else {
      return new _FullLazySubstring(data, start, length, b);
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
class _CompactLazySubstring extends _LazySubstring {
  final data;
  final int fields;

  _CompactLazySubstring(this.data, this.fields) : super.internal();

  int get start => fields >> 10;
  int get length => (fields >> 1) & 0x1ff;
  bool get boolValue => (fields & 1) == 1;
}

class _FullLazySubstring extends _LazySubstring {
  final data;
  final int start;
  final int length;
  final bool boolValue;
  _FullLazySubstring(this.data, this.start, this.length, this.boolValue)
      : super.internal();
}

bool isUserDefinableOperator(String value) {
  return isBinaryOperator(value) ||
      isMinusOperator(value) ||
      isTernaryOperator(value) ||
      isUnaryOperator(value);
}

bool isUnaryOperator(String value) => identical(value, "~");

bool isBinaryOperator(String value) {
  return identical(value, "==") ||
      identical(value, "[]") ||
      identical(value, "*") ||
      identical(value, "/") ||
      identical(value, "%") ||
      identical(value, "~/") ||
      identical(value, "+") ||
      identical(value, "<<") ||
      identical(value, ">>") ||
      identical(value, ">=") ||
      identical(value, ">") ||
      identical(value, "<=") ||
      identical(value, "<") ||
      identical(value, "&") ||
      identical(value, "^") ||
      identical(value, "|");
}

bool isTernaryOperator(String value) => identical(value, "[]=");

bool isMinusOperator(String value) => identical(value, "-");
