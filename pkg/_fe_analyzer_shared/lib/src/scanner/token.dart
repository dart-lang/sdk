// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the tokens that are produced by the scanner, used by the parser, and
 * referenced from the [AST structure](ast.dart).
 */
import 'dart:collection';

import '../base/syntactic_entity.dart';
import 'string_utilities.dart';
import 'token_constants.dart';

const int NO_PRECEDENCE = 0;
const int ASSIGNMENT_PRECEDENCE = 1;
const int CASCADE_PRECEDENCE = 2;
const int CONDITIONAL_PRECEDENCE = 3;
const int IF_NULL_PRECEDENCE = 4;
const int LOGICAL_OR_PRECEDENCE = 5;
const int LOGICAL_AND_PRECEDENCE = 6;
const int EQUALITY_PRECEDENCE = 7;
const int RELATIONAL_PRECEDENCE = 8;
const int BITWISE_OR_PRECEDENCE = 9;
const int BITWISE_XOR_PRECEDENCE = 10;
const int BITWISE_AND_PRECEDENCE = 11;
const int SHIFT_PRECEDENCE = 12;
const int ADDITIVE_PRECEDENCE = 13;
const int MULTIPLICATIVE_PRECEDENCE = 14;
const int PREFIX_PRECEDENCE = 15;
const int POSTFIX_PRECEDENCE = 16;
const int SELECTOR_PRECEDENCE = 17;

/**
 * The opening half of a grouping pair of tokens. This is used for curly
 * brackets ('{'), parentheses ('('), and square brackets ('[').
 */
class BeginToken extends SimpleToken {
  /**
   * The token that corresponds to this token.
   */
  Token? endToken;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset].
   */
  BeginToken(TokenType type, int offset, [CommentToken? precedingComment])
      : super(type, offset, precedingComment) {
    assert(type == TokenType.LT ||
        type == TokenType.OPEN_CURLY_BRACKET ||
        type == TokenType.OPEN_PAREN ||
        type == TokenType.OPEN_SQUARE_BRACKET ||
        type == TokenType.STRING_INTERPOLATION_EXPRESSION);
  }

  @override
  Token? get endGroup => endToken;

  /**
   * Set the token that corresponds to this token.
   */
  set endGroup(Token? token) {
    endToken = token;
  }
}

/**
 * A token representing a comment.
 */
class CommentToken extends StringToken {
  /**
   * The token that contains this comment.
   */
  SimpleToken? parent;

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  CommentToken(super.type, super.value, super.offset);
}

/**
 * A documentation comment token.
 */
class DocumentationCommentToken extends CommentToken {
  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  DocumentationCommentToken(super.type, super.value, super.offset);
}

enum KeywordStyle {
  reserved,
  builtIn,
  pseudo,
}

/**
 * The keywords in the Dart programming language.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Keyword extends TokenType {
  static const Keyword ABSTRACT = const Keyword(
      /* index = */ 79, "abstract", "ABSTRACT", KeywordStyle.builtIn,
      isModifier: true);

  static const Keyword AS = const Keyword(
      /* index = */ 80, "as", "AS", KeywordStyle.builtIn,
      precedence: RELATIONAL_PRECEDENCE);

  static const Keyword ASSERT = const Keyword(
      /* index = */ 81, "assert", "ASSERT", KeywordStyle.reserved);

  static const Keyword ASYNC =
      const Keyword(/* index = */ 82, "async", "ASYNC", KeywordStyle.pseudo);

  static const Keyword AUGMENT = const Keyword(
      /* index = */ 83, "augment", "AUGMENT", KeywordStyle.builtIn,
      isModifier: true);

  static const Keyword AWAIT =
      const Keyword(/* index = */ 84, "await", "AWAIT", KeywordStyle.pseudo);

  static const Keyword BASE =
      const Keyword(/* index = */ 85, "base", "BASE", KeywordStyle.pseudo);

  static const Keyword BREAK =
      const Keyword(/* index = */ 86, "break", "BREAK", KeywordStyle.reserved);

  static const Keyword CASE =
      const Keyword(/* index = */ 87, "case", "CASE", KeywordStyle.reserved);

  static const Keyword CATCH =
      const Keyword(/* index = */ 88, "catch", "CATCH", KeywordStyle.reserved);

  static const Keyword CLASS = const Keyword(
      /* index = */ 89, "class", "CLASS", KeywordStyle.reserved,
      isTopLevelKeyword: true);

  static const Keyword CONST = const Keyword(
      /* index = */ 90, "const", "CONST", KeywordStyle.reserved,
      isModifier: true);

  static const Keyword CONTINUE = const Keyword(
      /* index = */ 91, "continue", "CONTINUE", KeywordStyle.reserved);

  static const Keyword COVARIANT = const Keyword(
      /* index = */ 92, "covariant", "COVARIANT", KeywordStyle.builtIn,
      isModifier: true);

  static const Keyword DEFAULT = const Keyword(
      /* index = */ 93, "default", "DEFAULT", KeywordStyle.reserved);

  static const Keyword DEFERRED = const Keyword(
      /* index = */ 94, "deferred", "DEFERRED", KeywordStyle.builtIn);

  static const Keyword DO =
      const Keyword(/* index = */ 95, "do", "DO", KeywordStyle.reserved);

  static const Keyword DYNAMIC = const Keyword(
      /* index = */ 96, "dynamic", "DYNAMIC", KeywordStyle.builtIn);

  static const Keyword ELSE =
      const Keyword(/* index = */ 97, "else", "ELSE", KeywordStyle.reserved);

  static const Keyword ENUM = const Keyword(
      /* index = */ 98, "enum", "ENUM", KeywordStyle.reserved,
      isTopLevelKeyword: true);

  static const Keyword EXPORT = const Keyword(
      /* index = */ 99, "export", "EXPORT", KeywordStyle.builtIn,
      isTopLevelKeyword: true);

  static const Keyword EXTENDS = const Keyword(
      /* index = */ 100, "extends", "EXTENDS", KeywordStyle.reserved);

  static const Keyword EXTENSION = const Keyword(
      /* index = */ 101, "extension", "EXTENSION", KeywordStyle.builtIn,
      isTopLevelKeyword: true);

  static const Keyword EXTERNAL = const Keyword(
      /* index = */ 102, "external", "EXTERNAL", KeywordStyle.builtIn,
      isModifier: true);

  static const Keyword FACTORY = const Keyword(
      /* index = */ 103, "factory", "FACTORY", KeywordStyle.builtIn);

  static const Keyword FALSE =
      const Keyword(/* index = */ 104, "false", "FALSE", KeywordStyle.reserved);

  static const Keyword FINAL = const Keyword(
      /* index = */ 105, "final", "FINAL", KeywordStyle.reserved,
      isModifier: true);

  static const Keyword FINALLY = const Keyword(
      /* index = */ 106, "finally", "FINALLY", KeywordStyle.reserved);

  static const Keyword FOR =
      const Keyword(/* index = */ 107, "for", "FOR", KeywordStyle.reserved);

  static const Keyword FUNCTION = const Keyword(
      /* index = */ 108, "Function", "FUNCTION", KeywordStyle.builtIn);

  static const Keyword GET =
      const Keyword(/* index = */ 109, "get", "GET", KeywordStyle.builtIn);

  static const Keyword HIDE =
      const Keyword(/* index = */ 110, "hide", "HIDE", KeywordStyle.pseudo);

  static const Keyword IF =
      const Keyword(/* index = */ 111, "if", "IF", KeywordStyle.reserved);

  static const Keyword IMPLEMENTS = const Keyword(
      /* index = */ 112, "implements", "IMPLEMENTS", KeywordStyle.builtIn);

  static const Keyword IMPORT = const Keyword(
      /* index = */ 113, "import", "IMPORT", KeywordStyle.builtIn,
      isTopLevelKeyword: true);

  static const Keyword IN =
      const Keyword(/* index = */ 114, "in", "IN", KeywordStyle.reserved);

  static const Keyword INOUT =
      const Keyword(/* index = */ 115, "inout", "INOUT", KeywordStyle.pseudo);

  static const Keyword INTERFACE = const Keyword(
      /* index = */ 116, "interface", "INTERFACE", KeywordStyle.builtIn);

  static const Keyword IS = const Keyword(
      /* index = */ 117, "is", "IS", KeywordStyle.reserved,
      precedence: RELATIONAL_PRECEDENCE);

  static const Keyword LATE = const Keyword(
      /* index = */ 118, "late", "LATE", KeywordStyle.builtIn,
      isModifier: true);

  static const Keyword LIBRARY = const Keyword(
      /* index = */ 119, "library", "LIBRARY", KeywordStyle.builtIn,
      isTopLevelKeyword: true);

  static const Keyword MIXIN = const Keyword(
      /* index = */ 120, "mixin", "MIXIN", KeywordStyle.builtIn,
      isTopLevelKeyword: true);

  static const Keyword NATIVE =
      const Keyword(/* index = */ 121, "native", "NATIVE", KeywordStyle.pseudo);

  static const Keyword NEW =
      const Keyword(/* index = */ 122, "new", "NEW", KeywordStyle.reserved);

  static const Keyword NULL =
      const Keyword(/* index = */ 123, "null", "NULL", KeywordStyle.reserved);

  static const Keyword OF =
      const Keyword(/* index = */ 124, "of", "OF", KeywordStyle.pseudo);

  static const Keyword ON =
      const Keyword(/* index = */ 125, "on", "ON", KeywordStyle.pseudo);

  static const Keyword OPERATOR = const Keyword(
      /* index = */ 126, "operator", "OPERATOR", KeywordStyle.builtIn);

  static const Keyword OUT =
      const Keyword(/* index = */ 127, "out", "OUT", KeywordStyle.pseudo);

  static const Keyword PART = const Keyword(
      /* index = */ 128, "part", "PART", KeywordStyle.builtIn,
      isTopLevelKeyword: true);

  static const Keyword PATCH =
      const Keyword(/* index = */ 129, "patch", "PATCH", KeywordStyle.pseudo);

  static const Keyword REQUIRED = const Keyword(
      /* index = */ 130, "required", "REQUIRED", KeywordStyle.builtIn,
      isModifier: true);

  static const Keyword RETHROW = const Keyword(
      /* index = */ 131, "rethrow", "RETHROW", KeywordStyle.reserved);

  static const Keyword RETURN = const Keyword(
      /* index = */ 132, "return", "RETURN", KeywordStyle.reserved);

  static const Keyword SEALED =
      const Keyword(/* index = */ 133, "sealed", "SEALED", KeywordStyle.pseudo);

  static const Keyword SET =
      const Keyword(/* index = */ 134, "set", "SET", KeywordStyle.builtIn);

  static const Keyword SHOW =
      const Keyword(/* index = */ 135, "show", "SHOW", KeywordStyle.pseudo);

  static const Keyword SOURCE =
      const Keyword(/* index = */ 136, "source", "SOURCE", KeywordStyle.pseudo);

  static const Keyword STATIC = const Keyword(
      /* index = */ 137, "static", "STATIC", KeywordStyle.builtIn,
      isModifier: true);

  static const Keyword SUPER =
      const Keyword(/* index = */ 138, "super", "SUPER", KeywordStyle.reserved);

  static const Keyword SWITCH = const Keyword(
      /* index = */ 139, "switch", "SWITCH", KeywordStyle.reserved);

  static const Keyword SYNC =
      const Keyword(/* index = */ 140, "sync", "SYNC", KeywordStyle.pseudo);

  static const Keyword THIS =
      const Keyword(/* index = */ 141, "this", "THIS", KeywordStyle.reserved);

  static const Keyword THROW =
      const Keyword(/* index = */ 142, "throw", "THROW", KeywordStyle.reserved);

  static const Keyword TRUE =
      const Keyword(/* index = */ 143, "true", "TRUE", KeywordStyle.reserved);

  static const Keyword TRY =
      const Keyword(/* index = */ 144, "try", "TRY", KeywordStyle.reserved);

  static const Keyword TYPEDEF = const Keyword(
      /* index = */ 145, "typedef", "TYPEDEF", KeywordStyle.builtIn,
      isTopLevelKeyword: true);

  static const Keyword VAR = const Keyword(
      /* index = */ 146, "var", "VAR", KeywordStyle.reserved,
      isModifier: true);

  static const Keyword VOID =
      const Keyword(/* index = */ 147, "void", "VOID", KeywordStyle.reserved);

  static const Keyword WHEN =
      const Keyword(/* index = */ 148, "when", 'WHEN', KeywordStyle.pseudo);

  static const Keyword WHILE =
      const Keyword(/* index = */ 149, "while", "WHILE", KeywordStyle.reserved);

  static const Keyword WITH =
      const Keyword(/* index = */ 150, "with", "WITH", KeywordStyle.reserved);

  static const Keyword YIELD =
      const Keyword(/* index = */ 151, "yield", "YIELD", KeywordStyle.pseudo);

  static const List<Keyword> values = const <Keyword>[
    ABSTRACT,
    AS,
    ASSERT,
    ASYNC,
    AUGMENT,
    AWAIT,
    BASE,
    BREAK,
    CASE,
    CATCH,
    CLASS,
    CONST,
    CONTINUE,
    COVARIANT,
    DEFAULT,
    DEFERRED,
    DO,
    DYNAMIC,
    ELSE,
    ENUM,
    EXPORT,
    EXTENDS,
    EXTENSION,
    EXTERNAL,
    FACTORY,
    FALSE,
    FINAL,
    FINALLY,
    FOR,
    FUNCTION,
    GET,
    HIDE,
    IF,
    IMPLEMENTS,
    IMPORT,
    IN,
    INOUT,
    INTERFACE,
    IS,
    LATE,
    LIBRARY,
    MIXIN,
    NATIVE,
    NEW,
    NULL,
    OF,
    ON,
    OPERATOR,
    OUT,
    PART,
    PATCH,
    REQUIRED,
    RETHROW,
    RETURN,
    SEALED,
    SET,
    SHOW,
    SOURCE,
    STATIC,
    SUPER,
    SWITCH,
    SYNC,
    THIS,
    THROW,
    TRUE,
    TRY,
    TYPEDEF,
    VAR,
    VOID,
    WHEN,
    WHILE,
    WITH,
    YIELD,
  ];

  /**
   * A table mapping the lexemes of keywords to the corresponding keyword.
   */
  static final Map<String, Keyword> keywords = _createKeywordMap();

  final KeywordStyle keywordStyle;

  /**
   * Initialize a newly created keyword.
   */
  const Keyword(int index, String lexeme, String name, this.keywordStyle,
      {bool isModifier = false,
      bool isTopLevelKeyword = false,
      int precedence = NO_PRECEDENCE})
      : super(index, lexeme, name, precedence, KEYWORD_TOKEN,
            isModifier: isModifier, isTopLevelKeyword: isTopLevelKeyword);

  @override
  bool get isBuiltIn => keywordStyle == KeywordStyle.builtIn;

  @override
  bool get isPseudo => keywordStyle == KeywordStyle.pseudo;

  bool get isBuiltInOrPseudo => isBuiltIn || isPseudo;

  @override
  bool get isReservedWord => keywordStyle == KeywordStyle.reserved;

  /**
   * The name of the keyword type.
   */
  @override
  String get name => lexeme.toUpperCase();

  @override
  String toString() => name;

  /**
   * Create a table mapping the lexemes of keywords to the corresponding keyword
   * and return the table that was created.
   */
  static Map<String, Keyword> _createKeywordMap() {
    LinkedHashMap<String, Keyword> result =
        new LinkedHashMap<String, Keyword>();
    for (Keyword keyword in values) {
      result[keyword.lexeme] = keyword;
    }
    return result;
  }
}

/**
 * A token representing a keyword in the language.
 */
class KeywordToken extends SimpleToken {
  @override
  final Keyword keyword;

  /**
   * Initialize a newly created token to represent the given [keyword] at the
   * given [offset].
   */
  KeywordToken(this.keyword, int offset, [CommentToken? precedingComment])
      : super(keyword, offset, precedingComment);

  @override
  bool get isIdentifier => keyword.isPseudo || keyword.isBuiltIn;

  @override
  bool get isKeyword => true;

  @override
  bool get isKeywordOrIdentifier => true;

  @override
  Object value() => keyword;
}

/**
 * A specialized comment token representing a language version
 * (e.g. '// @dart = 2.1').
 */
class LanguageVersionToken extends CommentToken {
  /**
   * The major language version.
   */
  final int major;

  /**
   * The minor language version.
   */
  final int minor;

  LanguageVersionToken.from(String text, int offset, this.major, this.minor)
      : super(TokenType.SINGLE_LINE_COMMENT, text, offset);
}

/**
 * A token that was scanned from the input. Each token knows which tokens
 * precede and follow it, acting as a link in a doubly linked list of tokens.
 */
class SimpleToken implements Token {
  /**
   * The type of the token.
   */
  @override
  TokenType get type => _tokenTypesByIndex[_typeAndOffset & 0xff];

  /**
   * The offset from the beginning of the file to the first character in the
   * token.
   */
  @override
  int get offset => (_typeAndOffset >> 8) - 1;

  /**
   * Set the offset from the beginning of the file to the first character in
   * the token to the given [offset].
   */
  @override
  void set offset(int value) {
    assert(_tokenTypesByIndex.length < 256);
    // See https://github.com/dart-lang/sdk/issues/50048 for details.
    assert(value >= -1);
    _typeAndOffset = ((value + 1) << 8) | (_typeAndOffset & 0xff);
  }

  /**
   * The previous token in the token stream.
   */
  @override
  Token? previous;

  @override
  Token? next;

  /**
   * The first comment in the list of comments that precede this token.
   */
  CommentToken? _precedingComment;

  /**
   * The combined encoding of token type and offset.
   */
  int _typeAndOffset;

  /**
   * Initialize a newly created token to have the given [type] and [offset].
   */
  SimpleToken(TokenType type, int offset, [this._precedingComment])
      : _typeAndOffset = (((offset + 1) << 8) | type.index) {
    // See https://github.com/dart-lang/sdk/issues/50048 for details.
    assert(offset >= -1);

    // Assert the encoding of the [type] is fully reversible.
    assert(type.index < 256 && _tokenTypesByIndex.length < 256);
    assert(identical(offset, this.offset));
    assert(identical(type, this.type));

    _setCommentParent(_precedingComment);
  }

  @override
  int get charCount => length;

  @override
  int get charOffset => offset;

  @override
  int get charEnd => end;

  @override
  Token? get beforeSynthetic => null;

  @override
  set beforeSynthetic(Token? previous) {
    // ignored
  }

  @override
  int get end => offset + length;

  @override
  Token? get endGroup => null;

  @override
  bool get isEof => type == TokenType.EOF;

  @override
  bool get isIdentifier => false;

  @override
  bool get isKeyword => false;

  @override
  bool get isKeywordOrIdentifier => isIdentifier;

  @override
  bool get isModifier => type.isModifier;

  @override
  bool get isOperator => type.isOperator;

  @override
  bool get isSynthetic => length == 0;

  @override
  bool get isTopLevelKeyword => type.isTopLevelKeyword;

  @override
  bool get isUserDefinableOperator => type.isUserDefinableOperator;

  @override
  Keyword? get keyword => null;

  @override
  int get kind => type.kind;

  @override
  int get length => lexeme.length;

  @override
  String get lexeme => type.lexeme;

  @override
  CommentToken? get precedingComments => _precedingComment;

  void set precedingComments(CommentToken? comment) {
    _precedingComment = comment;
    _setCommentParent(_precedingComment);
  }

  @override
  String? get stringValue => type.stringValue;

  @override
  bool matchesAny(List<TokenType> types) {
    for (TokenType type in types) {
      if (this.type == type) {
        return true;
      }
    }
    return false;
  }

  @override
  Token setNext(Token token) {
    next = token;
    token.previous = this;
    token.beforeSynthetic = this;
    return token;
  }

  @override
  Token? setNextWithoutSettingPrevious(Token? token) {
    next = token;
    return token;
  }

  @override
  String toString() => lexeme;

  @override
  Object value() => lexeme;

  /**
   * Sets the `parent` property to `this` for the given [comment] and all the
   * next tokens.
   */
  void _setCommentParent(CommentToken? comment) {
    while (comment != null) {
      comment.parent = this;
      comment = comment.next as CommentToken?;
    }
  }
}

/**
 * A token whose value is independent of it's type.
 */
class StringToken extends SimpleToken {
  /**
   * The lexeme represented by this token.
   */
  final String _value;

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  StringToken(super.type, String value, super.offset, [super.precedingComment])
      : _value = StringUtilities.intern(value);

  @override
  bool get isIdentifier => identical(kind, IDENTIFIER_TOKEN);

  @override
  String get lexeme => _value;

  @override
  String value() => _value;
}

/**
 * A synthetic begin token.
 */
class SyntheticBeginToken extends BeginToken {
  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset].
   */
  SyntheticBeginToken(super.type, super.offset, [super.precedingComment]);

  @override
  Token? beforeSynthetic;

  @override
  bool get isSynthetic => true;

  @override
  int get length => 0;
}

/**
 * A synthetic keyword token.
 */
class SyntheticKeywordToken extends KeywordToken {
  /**
   * Initialize a newly created token to represent the given [keyword] at the
   * given [offset].
   */
  SyntheticKeywordToken(super.keyword, super.offset);

  @override
  Token? beforeSynthetic;

  @override
  int get length => 0;
}

/**
 * A token whose value is independent of it's type.
 */
class SyntheticStringToken extends StringToken {
  final int? _length;

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset]. If the [length] is
   * not specified, then it defaults to the length of [value].
   */
  SyntheticStringToken(super.type, super.value, super.offset, [this._length]);

  @override
  Token? beforeSynthetic;

  @override
  bool get isSynthetic => true;

  @override
  int get length => _length ?? super.length;
}

/**
 * A synthetic token.
 */
class SyntheticToken extends SimpleToken {
  SyntheticToken(super.type, super.offset);

  @override
  Token? beforeSynthetic;

  @override
  bool get isSynthetic => true;

  @override
  int get length => 0;
}

/// A token used to replace another token in the stream, while still keeping the
/// old token around (in [replacedToken]). Automatically sets the offset and
/// precedingComments from the data available on [replacedToken].
class ReplacementToken extends SyntheticToken {
  /// The token that this token replaces. This will normally be the token
  /// representing what the user actually wrote.
  final Token replacedToken;

  ReplacementToken(TokenType type, this.replacedToken)
      : super(type, replacedToken.offset) {
    precedingComments = replacedToken.precedingComments;
  }

  @override
  Token? beforeSynthetic;

  @override
  bool get isSynthetic => true;

  @override
  int get length => 0;
}

/**
 * A token that was scanned from the input. Each token knows which tokens
 * precede and follow it, acting as a link in a doubly linked list of tokens.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Token implements SyntacticEntity {
  /**
   * Initialize a newly created token to have the given [type] and [offset].
   */
  factory Token(TokenType type, int offset, [CommentToken? precedingComment]) =
      SimpleToken;

  /**
   * Initialize a newly created end-of-file token to have the given [offset].
   */
  factory Token.eof(int offset, [CommentToken? precedingComments]) {
    Token eof = new SimpleToken(TokenType.EOF, offset, precedingComments);
    // EOF points to itself so there's always infinite look-ahead.
    eof.previous = eof;
    eof.next = eof;
    return eof;
  }

  /**
   * The number of characters parsed by this token.
   */
  int get charCount;

  /**
   * The character offset of the start of this token within the source text.
   */
  int get charOffset;

  /**
   * The character offset of the end of this token within the source text.
   */
  int get charEnd;

  /**
   * The token before this synthetic token,
   * or `null` if this is not a synthetic `)`, `]`, `}`, or `>` token.
   */
  Token? get beforeSynthetic;

  /**
   * Set token before this synthetic `)`, `]`, `}`, or `>` token,
   * and ignored otherwise.
   */
  set beforeSynthetic(Token? previous);

  @override
  int get end;

  /**
   * The token that corresponds to this token, or `null` if this token is not
   * the first of a pair of matching tokens (such as parentheses).
   */
  Token? get endGroup => null;

  /**
   * Return `true` if this token represents an end of file.
   */
  bool get isEof;

  /**
   * True if this token is an identifier. Some keywords allowed as identifiers,
   * see implementation in [KeywordToken].
   */
  bool get isIdentifier;

  /**
   * True if this token is a keyword. Some keywords allowed as identifiers,
   * see implementation in [KeywordToken].
   */
  bool get isKeyword;

  /**
   * True if this token is a keyword or an identifier.
   */
  bool get isKeywordOrIdentifier;

  /**
   * Return `true` if this token is a modifier such as `abstract` or `const`.
   */
  bool get isModifier;

  /**
   * Return `true` if this token represents an operator.
   */
  bool get isOperator;

  /**
   * Return `true` if this token is a synthetic token. A synthetic token is a
   * token that was introduced by the parser in order to recover from an error
   * in the code.
   */
  bool get isSynthetic;

  /**
   * Return `true` if this token is a keyword starting a top level declaration
   * such as `class`, `enum`, `import`, etc.
   */
  bool get isTopLevelKeyword;

  /**
   * Return `true` if this token represents an operator that can be defined by
   * users.
   */
  bool get isUserDefinableOperator;

  /**
   * Return the keyword, if a keyword token, or `null` otherwise.
   */
  Keyword? get keyword;

  /**
   * The kind enum of this token as determined by its [type].
   */
  int get kind;

  @override
  int get length;

  /**
   * Return the lexeme that represents this token.
   *
   * For [StringToken]s the [lexeme] includes the quotes, explicit escapes, etc.
   */
  String get lexeme;

  /**
   * Return the next token in the token stream.
   */
  Token? get next;

  /**
   * Return the next token in the token stream.
   */
  void set next(Token? next);

  @override
  int get offset;

  /**
   * Set the offset from the beginning of the file to the first character in
   * the token to the given [offset].
   */
  void set offset(int offset);

  /**
   * Return the first comment in the list of comments that precede this token,
   * or `null` if there are no comments preceding this token. Additional
   * comments can be reached by following the token stream using [next] until
   * `null` is returned.
   *
   * For example, if the original contents were `/* one */ /* two */ id`, then
   * the first preceding comment token will have a lexeme of `/* one */` and
   * the next comment token will have a lexeme of `/* two */`.
   */
  CommentToken? get precedingComments;

  /**
   * Return the previous token in the token stream.
   */
  Token? get previous;

  /**
   * Set the previous token in the token stream to the given [token].
   */
  void set previous(Token? token);

  /**
   * For symbol and keyword tokens, returns the string value represented by this
   * token. For [StringToken]s this method returns [:null:].
   *
   * For [SymbolToken]s and [KeywordToken]s, the string value is a compile-time
   * constant originating in the [TokenType] or in the [Keyword] instance.
   * This allows testing for keywords and symbols using [:identical:], e.g.,
   * [:identical('class', token.value):].
   *
   * Note that returning [:null:] for string tokens is important to identify
   * symbols and keywords, we cannot use [lexeme] instead. The string literal
   *   "$a($b"
   * produces ..., SymbolToken($), StringToken(a), StringToken((), ...
   *
   * After parsing the identifier 'a', the parser tests for a function
   * declaration using [:identical(next.stringValue, '('):], which (rightfully)
   * returns false because stringValue returns [:null:].
   */
  String? get stringValue;

  /**
   * Return the type of the token.
   */
  TokenType get type;

  /**
   * Return `true` if this token has any one of the given [types].
   */
  bool matchesAny(List<TokenType> types);

  /**
   * Set the next token in the token stream to the given [token]. This has the
   * side-effect of setting this token to be the previous token for the given
   * token. Return the token that was passed in.
   */
  Token setNext(Token token);

  /**
   * Set the next token in the token stream to the given token without changing
   * which token is the previous token for the given token. Return the token
   * that was passed in.
   */
  Token? setNextWithoutSettingPrevious(Token? token);

  /**
   * Returns a textual representation of this token to be used for debugging
   * purposes. The resulting string might contain information about the
   * structure of the token, for example 'StringToken(foo)' for the identifier
   * token 'foo'.
   *
   * Use [lexeme] for the text actually parsed by the token.
   */
  @override
  String toString();

  /**
   * Return the value of this token. For keyword tokens, this is the keyword
   * associated with the token, for other tokens it is the lexeme associated
   * with the token.
   */
  Object value();

  /**
   * Compare the given tokens to find the token that appears first in the
   * source being parsed. That is, return the left-most of all of the tokens.
   * Return the token with the smallest offset, or `null` if all of the
   * tokens are `null`.
   */
  static Token? lexicallyFirst(
      [Token? t1, Token? t2, Token? t3, Token? t4, Token? t5]) {
    Token? result = t1;
    if (result == null || t2 != null && t2.offset < result.offset) {
      result = t2;
    }
    if (result == null || t3 != null && t3.offset < result.offset) {
      result = t3;
    }
    if (result == null || t4 != null && t4.offset < result.offset) {
      result = t4;
    }
    if (result == null || t5 != null && t5.offset < result.offset) {
      result = t5;
    }
    return result;
  }
}

/**
 * The classes (or groups) of tokens with a similar use.
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
      const TokenClass('ADDITIVE_OPERATOR', ADDITIVE_PRECEDENCE);

  /**
   * A value used to indicate that the token type is an assignment operator.
   */
  static const TokenClass ASSIGNMENT_OPERATOR =
      const TokenClass('ASSIGNMENT_OPERATOR', ASSIGNMENT_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a bitwise-and operator.
   */
  static const TokenClass BITWISE_AND_OPERATOR =
      const TokenClass('BITWISE_AND_OPERATOR', BITWISE_AND_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a bitwise-or operator.
   */
  static const TokenClass BITWISE_OR_OPERATOR =
      const TokenClass('BITWISE_OR_OPERATOR', BITWISE_OR_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a bitwise-xor operator.
   */
  static const TokenClass BITWISE_XOR_OPERATOR =
      const TokenClass('BITWISE_XOR_OPERATOR', BITWISE_XOR_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a cascade operator.
   */
  static const TokenClass CASCADE_OPERATOR =
      const TokenClass('CASCADE_OPERATOR', CASCADE_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a conditional operator.
   */
  static const TokenClass CONDITIONAL_OPERATOR =
      const TokenClass('CONDITIONAL_OPERATOR', CONDITIONAL_PRECEDENCE);

  /**
   * A value used to indicate that the token type is an equality operator.
   */
  static const TokenClass EQUALITY_OPERATOR =
      const TokenClass('EQUALITY_OPERATOR', EQUALITY_PRECEDENCE);

  /**
   * A value used to indicate that the token type is an if-null operator.
   */
  static const TokenClass IF_NULL_OPERATOR =
      const TokenClass('IF_NULL_OPERATOR', IF_NULL_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a logical-and operator.
   */
  static const TokenClass LOGICAL_AND_OPERATOR =
      const TokenClass('LOGICAL_AND_OPERATOR', LOGICAL_AND_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a logical-or operator.
   */
  static const TokenClass LOGICAL_OR_OPERATOR =
      const TokenClass('LOGICAL_OR_OPERATOR', LOGICAL_OR_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a multiplicative operator.
   */
  static const TokenClass MULTIPLICATIVE_OPERATOR =
      const TokenClass('MULTIPLICATIVE_OPERATOR', MULTIPLICATIVE_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a relational operator.
   */
  static const TokenClass RELATIONAL_OPERATOR =
      const TokenClass('RELATIONAL_OPERATOR', RELATIONAL_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a shift operator.
   */
  static const TokenClass SHIFT_OPERATOR =
      const TokenClass('SHIFT_OPERATOR', SHIFT_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static const TokenClass UNARY_POSTFIX_OPERATOR =
      const TokenClass('UNARY_POSTFIX_OPERATOR', POSTFIX_PRECEDENCE);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static const TokenClass UNARY_PREFIX_OPERATOR =
      const TokenClass('UNARY_PREFIX_OPERATOR', PREFIX_PRECEDENCE);

  /**
   * The name of the token class.
   */
  final String name;

  /**
   * The precedence of tokens of this class, or `0` if the such tokens do not
   * represent an operator.
   */
  final int precedence;

  /**
   * Initialize a newly created class of tokens to have the given [name] and
   * [precedence].
   */
  const TokenClass(this.name, [this.precedence = NO_PRECEDENCE]);

  @override
  String toString() => name;
}

/**
 * The types of tokens that can be returned by the scanner.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class TokenType {
  /**
   * The type of the token that marks the start or end of the input.
   */
  static const TokenType EOF =
      const TokenType(/* index = */ 0, '', 'EOF', NO_PRECEDENCE, EOF_TOKEN);

  static const TokenType DOUBLE = const TokenType(
      /* index = */ 1, 'double', 'DOUBLE', NO_PRECEDENCE, DOUBLE_TOKEN,
      stringValue: null);

  static const TokenType HEXADECIMAL = const TokenType(/* index = */ 2,
      'hexadecimal', 'HEXADECIMAL', NO_PRECEDENCE, HEXADECIMAL_TOKEN,
      stringValue: null);

  static const TokenType IDENTIFIER = const TokenType(/* index = */ 3,
      'identifier', 'IDENTIFIER', NO_PRECEDENCE, IDENTIFIER_TOKEN,
      stringValue: null);

  static const TokenType INT = const TokenType(
      /* index = */ 4, 'int', 'INT', NO_PRECEDENCE, INT_TOKEN,
      stringValue: null);

  static const TokenType MULTI_LINE_COMMENT = const TokenType(/* index = */ 5,
      'comment', 'MULTI_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN,
      stringValue: null);

  static const TokenType SCRIPT_TAG = const TokenType(
      /* index = */ 6, 'script', 'SCRIPT_TAG', NO_PRECEDENCE, SCRIPT_TOKEN);

  static const TokenType SINGLE_LINE_COMMENT = const TokenType(/* index = */ 7,
      'comment', 'SINGLE_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN,
      stringValue: null);

  static const TokenType STRING = const TokenType(
      /* index = */ 8, 'string', 'STRING', NO_PRECEDENCE, STRING_TOKEN,
      stringValue: null);

  static const TokenType AMPERSAND = const TokenType(/* index = */ 9, '&',
      'AMPERSAND', BITWISE_AND_PRECEDENCE, AMPERSAND_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType AMPERSAND_AMPERSAND = const TokenType(
      /* index = */ 10,
      '&&',
      'AMPERSAND_AMPERSAND',
      LOGICAL_AND_PRECEDENCE,
      AMPERSAND_AMPERSAND_TOKEN,
      isOperator: true,
      isBinaryOperator: true);

  // This is not yet part of the language and not supported by fasta
  static const TokenType AMPERSAND_AMPERSAND_EQ = const TokenType(
      /* index = */ 11,
      '&&=',
      'AMPERSAND_AMPERSAND_EQ',
      ASSIGNMENT_PRECEDENCE,
      AMPERSAND_AMPERSAND_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.AMPERSAND_AMPERSAND,
      isOperator: true);

  static const TokenType AMPERSAND_EQ = const TokenType(/* index = */ 12, '&=',
      'AMPERSAND_EQ', ASSIGNMENT_PRECEDENCE, AMPERSAND_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.AMPERSAND,
      isOperator: true);

  static const TokenType AT =
      const TokenType(/* index = */ 13, '@', 'AT', NO_PRECEDENCE, AT_TOKEN);

  static const TokenType BANG = const TokenType(
      /* index = */ 14, '!', 'BANG', PREFIX_PRECEDENCE, BANG_TOKEN,
      isOperator: true);

  static const TokenType BANG_EQ = const TokenType(
      /* index = */ 15, '!=', 'BANG_EQ', EQUALITY_PRECEDENCE, BANG_EQ_TOKEN,
      isOperator: true);

  static const TokenType BANG_EQ_EQ = const TokenType(/* index = */ 16, '!==',
      'BANG_EQ_EQ', EQUALITY_PRECEDENCE, BANG_EQ_EQ_TOKEN);

  static const TokenType BAR = const TokenType(
      /* index = */ 17, '|', 'BAR', BITWISE_OR_PRECEDENCE, BAR_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType BAR_BAR = const TokenType(
      /* index = */ 18, '||', 'BAR_BAR', LOGICAL_OR_PRECEDENCE, BAR_BAR_TOKEN,
      isOperator: true, isBinaryOperator: true);

  // This is not yet part of the language and not supported by fasta
  static const TokenType BAR_BAR_EQ = const TokenType(/* index = */ 19, '||=',
      'BAR_BAR_EQ', ASSIGNMENT_PRECEDENCE, BAR_BAR_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.BAR_BAR, isOperator: true);

  static const TokenType BAR_EQ = const TokenType(
      /* index = */ 20, '|=', 'BAR_EQ', ASSIGNMENT_PRECEDENCE, BAR_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.BAR, isOperator: true);

  static const TokenType COLON = const TokenType(
      /* index = */ 21, ':', 'COLON', NO_PRECEDENCE, COLON_TOKEN);

  static const TokenType COMMA = const TokenType(
      /* index = */ 22, ',', 'COMMA', NO_PRECEDENCE, COMMA_TOKEN);

  static const TokenType CARET = const TokenType(
      /* index = */ 23, '^', 'CARET', BITWISE_XOR_PRECEDENCE, CARET_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType CARET_EQ = const TokenType(
      /* index = */ 24, '^=', 'CARET_EQ', ASSIGNMENT_PRECEDENCE, CARET_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.CARET, isOperator: true);

  static const TokenType CLOSE_CURLY_BRACKET = const TokenType(/* index = */ 25,
      '}', 'CLOSE_CURLY_BRACKET', NO_PRECEDENCE, CLOSE_CURLY_BRACKET_TOKEN);

  static const TokenType CLOSE_PAREN = const TokenType(
      /* index = */ 26, ')', 'CLOSE_PAREN', NO_PRECEDENCE, CLOSE_PAREN_TOKEN);

  static const TokenType CLOSE_SQUARE_BRACKET = const TokenType(
      /* index = */ 27,
      ']',
      'CLOSE_SQUARE_BRACKET',
      NO_PRECEDENCE,
      CLOSE_SQUARE_BRACKET_TOKEN);

  static const TokenType EQ = const TokenType(
      /* index = */ 28, '=', 'EQ', ASSIGNMENT_PRECEDENCE, EQ_TOKEN,
      isOperator: true);

  static const TokenType EQ_EQ = const TokenType(
      /* index = */ 29, '==', 'EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  /// The `===` operator is not supported in the Dart language
  /// but is parsed as such by the scanner to support better recovery
  /// when a JavaScript code snippet is pasted into a Dart file.
  static const TokenType EQ_EQ_EQ = const TokenType(
      /* index = */ 30, '===', 'EQ_EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_EQ_TOKEN);

  static const TokenType FUNCTION = const TokenType(
      /* index = */ 31, '=>', 'FUNCTION', NO_PRECEDENCE, FUNCTION_TOKEN);

  static const TokenType GT = const TokenType(
      /* index = */ 32, '>', 'GT', RELATIONAL_PRECEDENCE, GT_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType GT_EQ = const TokenType(
      /* index = */ 33, '>=', 'GT_EQ', RELATIONAL_PRECEDENCE, GT_EQ_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType GT_GT = const TokenType(
      /* index = */ 34, '>>', 'GT_GT', SHIFT_PRECEDENCE, GT_GT_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType GT_GT_EQ = const TokenType(/* index = */ 35, '>>=',
      'GT_GT_EQ', ASSIGNMENT_PRECEDENCE, GT_GT_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.GT_GT, isOperator: true);

  static const TokenType GT_GT_GT = const TokenType(
      /* index = */ 36, '>>>', 'GT_GT_GT', SHIFT_PRECEDENCE, GT_GT_GT_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType GT_GT_GT_EQ = const TokenType(/* index = */ 37, '>>>=',
      'GT_GT_GT_EQ', ASSIGNMENT_PRECEDENCE, GT_GT_GT_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.GT_GT_GT, isOperator: true);

  static const TokenType HASH =
      const TokenType(/* index = */ 38, '#', 'HASH', NO_PRECEDENCE, HASH_TOKEN);

  static const TokenType INDEX = const TokenType(
      /* index = */ 39, '[]', 'INDEX', SELECTOR_PRECEDENCE, INDEX_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType INDEX_EQ = const TokenType(
      /* index = */ 40, '[]=', 'INDEX_EQ', NO_PRECEDENCE, INDEX_EQ_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType LT = const TokenType(
      /* index = */ 41, '<', 'LT', RELATIONAL_PRECEDENCE, LT_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType LT_EQ = const TokenType(
      /* index = */ 42, '<=', 'LT_EQ', RELATIONAL_PRECEDENCE, LT_EQ_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType LT_LT = const TokenType(
      /* index = */ 43, '<<', 'LT_LT', SHIFT_PRECEDENCE, LT_LT_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType LT_LT_EQ = const TokenType(/* index = */ 44, '<<=',
      'LT_LT_EQ', ASSIGNMENT_PRECEDENCE, LT_LT_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.LT_LT, isOperator: true);

  static const TokenType MINUS = const TokenType(
      /* index = */ 45, '-', 'MINUS', ADDITIVE_PRECEDENCE, MINUS_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType MINUS_EQ = const TokenType(
      /* index = */ 46, '-=', 'MINUS_EQ', ASSIGNMENT_PRECEDENCE, MINUS_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.MINUS, isOperator: true);

  static const TokenType MINUS_MINUS = const TokenType(/* index = */ 47, '--',
      'MINUS_MINUS', POSTFIX_PRECEDENCE, MINUS_MINUS_TOKEN,
      isOperator: true);

  static const TokenType OPEN_CURLY_BRACKET = const TokenType(/* index = */ 48,
      '{', 'OPEN_CURLY_BRACKET', NO_PRECEDENCE, OPEN_CURLY_BRACKET_TOKEN);

  static const TokenType OPEN_PAREN = const TokenType(/* index = */ 49, '(',
      'OPEN_PAREN', SELECTOR_PRECEDENCE, OPEN_PAREN_TOKEN);

  static const TokenType OPEN_SQUARE_BRACKET = const TokenType(
      /* index = */ 50,
      '[',
      'OPEN_SQUARE_BRACKET',
      SELECTOR_PRECEDENCE,
      OPEN_SQUARE_BRACKET_TOKEN);

  static const TokenType PERCENT = const TokenType(/* index = */ 51, '%',
      'PERCENT', MULTIPLICATIVE_PRECEDENCE, PERCENT_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType PERCENT_EQ = const TokenType(/* index = */ 52, '%=',
      'PERCENT_EQ', ASSIGNMENT_PRECEDENCE, PERCENT_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.PERCENT, isOperator: true);

  static const TokenType PERIOD = const TokenType(
      /* index = */ 53, '.', 'PERIOD', SELECTOR_PRECEDENCE, PERIOD_TOKEN);

  static const TokenType PERIOD_PERIOD = const TokenType(/* index = */ 54, '..',
      'PERIOD_PERIOD', CASCADE_PRECEDENCE, PERIOD_PERIOD_TOKEN,
      isOperator: true);

  static const TokenType PLUS = const TokenType(
      /* index = */ 55, '+', 'PLUS', ADDITIVE_PRECEDENCE, PLUS_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType PLUS_EQ = const TokenType(
      /* index = */ 56, '+=', 'PLUS_EQ', ASSIGNMENT_PRECEDENCE, PLUS_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.PLUS, isOperator: true);

  static const TokenType PLUS_PLUS = const TokenType(
      /* index = */ 57, '++', 'PLUS_PLUS', POSTFIX_PRECEDENCE, PLUS_PLUS_TOKEN,
      isOperator: true);

  static const TokenType QUESTION = const TokenType(
      /* index = */ 58, '?', 'QUESTION', CONDITIONAL_PRECEDENCE, QUESTION_TOKEN,
      isOperator: true);

  static const TokenType QUESTION_PERIOD = const TokenType(/* index = */ 59,
      '?.', 'QUESTION_PERIOD', SELECTOR_PRECEDENCE, QUESTION_PERIOD_TOKEN,
      isOperator: true);

  static const TokenType QUESTION_QUESTION = const TokenType(/* index = */ 60,
      '??', 'QUESTION_QUESTION', IF_NULL_PRECEDENCE, QUESTION_QUESTION_TOKEN,
      isOperator: true, isBinaryOperator: true);

  static const TokenType QUESTION_QUESTION_EQ = const TokenType(
      /* index = */ 61,
      '??=',
      'QUESTION_QUESTION_EQ',
      ASSIGNMENT_PRECEDENCE,
      QUESTION_QUESTION_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.QUESTION_QUESTION,
      isOperator: true);

  static const TokenType SEMICOLON = const TokenType(
      /* index = */ 62, ';', 'SEMICOLON', NO_PRECEDENCE, SEMICOLON_TOKEN);

  static const TokenType SLASH = const TokenType(
      /* index = */ 63, '/', 'SLASH', MULTIPLICATIVE_PRECEDENCE, SLASH_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType SLASH_EQ = const TokenType(
      /* index = */ 64, '/=', 'SLASH_EQ', ASSIGNMENT_PRECEDENCE, SLASH_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.SLASH, isOperator: true);

  static const TokenType STAR = const TokenType(
      /* index = */ 65, '*', 'STAR', MULTIPLICATIVE_PRECEDENCE, STAR_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType STAR_EQ = const TokenType(
      /* index = */ 66, '*=', 'STAR_EQ', ASSIGNMENT_PRECEDENCE, STAR_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.STAR, isOperator: true);

  static const TokenType STRING_INTERPOLATION_EXPRESSION = const TokenType(
      /* index = */ 67,
      '\${',
      'STRING_INTERPOLATION_EXPRESSION',
      NO_PRECEDENCE,
      STRING_INTERPOLATION_TOKEN);

  static const TokenType STRING_INTERPOLATION_IDENTIFIER = const TokenType(
      /* index = */ 68,
      '\$',
      'STRING_INTERPOLATION_IDENTIFIER',
      NO_PRECEDENCE,
      STRING_INTERPOLATION_IDENTIFIER_TOKEN);

  static const TokenType TILDE = const TokenType(
      /* index = */ 69, '~', 'TILDE', PREFIX_PRECEDENCE, TILDE_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType TILDE_SLASH = const TokenType(/* index = */ 70, '~/',
      'TILDE_SLASH', MULTIPLICATIVE_PRECEDENCE, TILDE_SLASH_TOKEN,
      isOperator: true, isBinaryOperator: true, isUserDefinableOperator: true);

  static const TokenType TILDE_SLASH_EQ = const TokenType(/* index = */ 71,
      '~/=', 'TILDE_SLASH_EQ', ASSIGNMENT_PRECEDENCE, TILDE_SLASH_EQ_TOKEN,
      binaryOperatorOfCompoundAssignment: TokenType.TILDE_SLASH,
      isOperator: true);

  static const TokenType BACKPING = const TokenType(
      /* index = */ 72, '`', 'BACKPING', NO_PRECEDENCE, BACKPING_TOKEN);

  static const TokenType BACKSLASH = const TokenType(
      /* index = */ 73, '\\', 'BACKSLASH', NO_PRECEDENCE, BACKSLASH_TOKEN);

  static const TokenType PERIOD_PERIOD_PERIOD = const TokenType(
      /* index = */ 74,
      '...',
      'PERIOD_PERIOD_PERIOD',
      NO_PRECEDENCE,
      PERIOD_PERIOD_PERIOD_TOKEN);

  static const TokenType PERIOD_PERIOD_PERIOD_QUESTION = const TokenType(
      /* index = */ 75,
      '...?',
      'PERIOD_PERIOD_PERIOD_QUESTION',
      NO_PRECEDENCE,
      PERIOD_PERIOD_PERIOD_QUESTION_TOKEN);

  static const TokenType QUESTION_PERIOD_PERIOD = const TokenType(
      /* index = */ 76,
      '?..',
      'QUESTION_PERIOD_PERIOD',
      CASCADE_PRECEDENCE,
      QUESTION_PERIOD_PERIOD_TOKEN);

  static const TokenType AS = Keyword.AS;

  static const TokenType IS = Keyword.IS;

  /**
   * Token type used by error tokens.
   */
  static const TokenType BAD_INPUT = const TokenType(/* index = */ 77,
      'malformed input', 'BAD_INPUT', NO_PRECEDENCE, BAD_INPUT_TOKEN,
      stringValue: null);

  /**
   * Token type used by synthetic tokens that are created during parser
   * recovery (non-analyzer use case).
   */
  static const TokenType RECOVERY = const TokenType(
      /* index = */ 78, 'recovery', 'RECOVERY', NO_PRECEDENCE, RECOVERY_TOKEN,
      stringValue: null);

  // TODO(danrubel): "all" is misleading
  // because this list does not include all TokenType instances.
  static const List<TokenType> all = const <TokenType>[
    TokenType.EOF,
    TokenType.DOUBLE,
    TokenType.HEXADECIMAL,
    TokenType.IDENTIFIER,
    TokenType.INT,
    TokenType.MULTI_LINE_COMMENT,
    TokenType.SCRIPT_TAG,
    TokenType.SINGLE_LINE_COMMENT,
    TokenType.STRING,
    TokenType.AMPERSAND,
    TokenType.AMPERSAND_AMPERSAND,
    TokenType.AMPERSAND_EQ,
    TokenType.AT,
    TokenType.BANG,
    TokenType.BANG_EQ,
    TokenType.BAR,
    TokenType.BAR_BAR,
    TokenType.BAR_EQ,
    TokenType.COLON,
    TokenType.COMMA,
    TokenType.CARET,
    TokenType.CARET_EQ,
    TokenType.CLOSE_CURLY_BRACKET,
    TokenType.CLOSE_PAREN,
    TokenType.CLOSE_SQUARE_BRACKET,
    TokenType.EQ,
    TokenType.EQ_EQ,
    TokenType.FUNCTION,
    TokenType.GT,
    TokenType.GT_EQ,
    TokenType.GT_GT,
    TokenType.GT_GT_EQ,
    TokenType.HASH,
    TokenType.INDEX,
    TokenType.INDEX_EQ,
    TokenType.LT,
    TokenType.LT_EQ,
    TokenType.LT_LT,
    TokenType.LT_LT_EQ,
    TokenType.MINUS,
    TokenType.MINUS_EQ,
    TokenType.MINUS_MINUS,
    TokenType.OPEN_CURLY_BRACKET,
    TokenType.OPEN_PAREN,
    TokenType.OPEN_SQUARE_BRACKET,
    TokenType.PERCENT,
    TokenType.PERCENT_EQ,
    TokenType.PERIOD,
    TokenType.PERIOD_PERIOD,
    TokenType.PLUS,
    TokenType.PLUS_EQ,
    TokenType.PLUS_PLUS,
    TokenType.QUESTION,
    TokenType.QUESTION_PERIOD,
    TokenType.QUESTION_QUESTION,
    TokenType.QUESTION_QUESTION_EQ,
    TokenType.SEMICOLON,
    TokenType.SLASH,
    TokenType.SLASH_EQ,
    TokenType.STAR,
    TokenType.STAR_EQ,
    TokenType.STRING_INTERPOLATION_EXPRESSION,
    TokenType.STRING_INTERPOLATION_IDENTIFIER,
    TokenType.TILDE,
    TokenType.TILDE_SLASH,
    TokenType.TILDE_SLASH_EQ,
    TokenType.BACKPING,
    TokenType.BACKSLASH,
    TokenType.PERIOD_PERIOD_PERIOD,
    TokenType.PERIOD_PERIOD_PERIOD_QUESTION,

    // TODO(danrubel): Should these be added to the "all" list?
    //TokenType.IS,
    //TokenType.AS,

    // These are not yet part of the language and not supported by fasta
    //TokenType.AMPERSAND_AMPERSAND_EQ,
    //TokenType.BAR_BAR_EQ,

    // Supported by fasta but not part of the language
    //TokenType.BANG_EQ_EQ,
    //TokenType.EQ_EQ_EQ,

    // Used by synthetic tokens generated during recovery
    //TokenType.BAD_INPUT,
    //TokenType.RECOVERY,
  ];

  /**
   * A unique index identifying this [TokenType].
   */
  final int index;

  /**
   * The binary operator that is invoked by this compound assignment operator,
   * or `null` otherwise.
   */
  final TokenType? binaryOperatorOfCompoundAssignment;

  final int kind;

  /**
   * `true` if this token type represents a modifier
   * such as `abstract` or `const`.
   */
  final bool isModifier;

  /**
   * `true` if this token type represents an operator.
   */
  final bool isOperator;

  /**
   * `true` if this token type represents a binary operator.
   */
  final bool isBinaryOperator;

  /**
   * `true` if this token type represents a keyword starting a top level
   * declaration such as `class`, `enum`, `import`, etc.
   */
  final bool isTopLevelKeyword;

  /**
   * `true` if this token type represents an operator
   * that can be defined by users.
   */
  final bool isUserDefinableOperator;

  /**
   * The lexeme that defines this type of token,
   * or `null` if there is more than one possible lexeme for this type of token.
   */
  final String lexeme;

  /**
   * The name of the token type.
   */
  final String name;

  /**
   * The precedence of this type of token,
   * or `0` if the token does not represent an operator.
   */
  final int precedence;

  /**
   * See [Token.stringValue] for an explanation.
   */
  final String? stringValue;

  const TokenType(
      this.index, this.lexeme, this.name, this.precedence, this.kind,
      {this.binaryOperatorOfCompoundAssignment,
      this.isBinaryOperator = false,
      this.isModifier = false,
      this.isOperator = false,
      this.isTopLevelKeyword = false,
      this.isUserDefinableOperator = false,
      String? stringValue = 'unspecified'})
      : this.stringValue = stringValue == 'unspecified' ? lexeme : stringValue;

  /**
   * Return `true` if this type of token represents an additive operator.
   */
  bool get isAdditiveOperator => precedence == ADDITIVE_PRECEDENCE;

  /**
   * Return `true` if this type of token represents an assignment operator.
   */
  bool get isAssignmentOperator => precedence == ASSIGNMENT_PRECEDENCE;

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
      this == TokenType.AMPERSAND ||
      this == TokenType.AMPERSAND_AMPERSAND ||
      this == TokenType.BAR ||
      this == TokenType.BAR_BAR ||
      this == TokenType.CARET ||
      this == TokenType.PLUS ||
      this == TokenType.STAR;

  /**
   * A flag indicating whether the keyword is a "built-in" identifier.
   */
  bool get isBuiltIn => false;

  /// A flag indicating whether the keyword is a "reserved word".
  bool get isReservedWord => false;

  /**
   * Return `true` if this type of token represents an equality operator.
   */
  bool get isEqualityOperator =>
      this == TokenType.BANG_EQ || this == TokenType.EQ_EQ;

  /**
   * Return `true` if this type of token represents an increment operator.
   */
  bool get isIncrementOperator =>
      this == TokenType.PLUS_PLUS || this == TokenType.MINUS_MINUS;

  /**
   * Return `true` if this type of token is a keyword.
   */
  bool get isKeyword => kind == KEYWORD_TOKEN;

  /**
   * A flag indicating whether the keyword can be used as an identifier
   * in some situations.
   */
  bool get isPseudo => false;

  /**
   * Return `true` if this type of token represents a multiplicative operator.
   */
  bool get isMultiplicativeOperator => precedence == MULTIPLICATIVE_PRECEDENCE;

  /**
   * Return `true` if this type of token represents a relational operator.
   */
  bool get isRelationalOperator =>
      this == TokenType.LT ||
      this == TokenType.LT_EQ ||
      this == TokenType.GT ||
      this == TokenType.GT_EQ;

  /**
   * Return `true` if this type of token represents a shift operator.
   */
  bool get isShiftOperator => precedence == SHIFT_PRECEDENCE;

  /**
   * Return `true` if this type of token represents a unary postfix operator.
   */
  bool get isUnaryPostfixOperator => precedence == POSTFIX_PRECEDENCE;

  /**
   * Return `true` if this type of token represents a unary prefix operator.
   */
  bool get isUnaryPrefixOperator =>
      precedence == PREFIX_PRECEDENCE ||
      this == TokenType.MINUS ||
      this == TokenType.PLUS_PLUS ||
      this == TokenType.MINUS_MINUS;

  /**
   * Return `true` if this type of token represents a selector operator
   * (starting token of a selector).
   */
  bool get isSelectorOperator => precedence == SELECTOR_PRECEDENCE;

  @override
  String toString() => name;
}

/**
 * Constant list of [TokenType] and [Keyword] ordered by index.
 */
const List<TokenType> _tokenTypesByIndex = [
  TokenType.EOF,
  TokenType.DOUBLE,
  TokenType.HEXADECIMAL,
  TokenType.IDENTIFIER,
  TokenType.INT,
  TokenType.MULTI_LINE_COMMENT,
  TokenType.SCRIPT_TAG,
  TokenType.SINGLE_LINE_COMMENT,
  TokenType.STRING,
  TokenType.AMPERSAND,
  TokenType.AMPERSAND_AMPERSAND,
  TokenType.AMPERSAND_AMPERSAND_EQ,
  TokenType.AMPERSAND_EQ,
  TokenType.AT,
  TokenType.BANG,
  TokenType.BANG_EQ,
  TokenType.BANG_EQ_EQ,
  TokenType.BAR,
  TokenType.BAR_BAR,
  TokenType.BAR_BAR_EQ,
  TokenType.BAR_EQ,
  TokenType.COLON,
  TokenType.COMMA,
  TokenType.CARET,
  TokenType.CARET_EQ,
  TokenType.CLOSE_CURLY_BRACKET,
  TokenType.CLOSE_PAREN,
  TokenType.CLOSE_SQUARE_BRACKET,
  TokenType.EQ,
  TokenType.EQ_EQ,
  TokenType.EQ_EQ_EQ,
  TokenType.FUNCTION,
  TokenType.GT,
  TokenType.GT_EQ,
  TokenType.GT_GT,
  TokenType.GT_GT_EQ,
  TokenType.GT_GT_GT,
  TokenType.GT_GT_GT_EQ,
  TokenType.HASH,
  TokenType.INDEX,
  TokenType.INDEX_EQ,
  TokenType.LT,
  TokenType.LT_EQ,
  TokenType.LT_LT,
  TokenType.LT_LT_EQ,
  TokenType.MINUS,
  TokenType.MINUS_EQ,
  TokenType.MINUS_MINUS,
  TokenType.OPEN_CURLY_BRACKET,
  TokenType.OPEN_PAREN,
  TokenType.OPEN_SQUARE_BRACKET,
  TokenType.PERCENT,
  TokenType.PERCENT_EQ,
  TokenType.PERIOD,
  TokenType.PERIOD_PERIOD,
  TokenType.PLUS,
  TokenType.PLUS_EQ,
  TokenType.PLUS_PLUS,
  TokenType.QUESTION,
  TokenType.QUESTION_PERIOD,
  TokenType.QUESTION_QUESTION,
  TokenType.QUESTION_QUESTION_EQ,
  TokenType.SEMICOLON,
  TokenType.SLASH,
  TokenType.SLASH_EQ,
  TokenType.STAR,
  TokenType.STAR_EQ,
  TokenType.STRING_INTERPOLATION_EXPRESSION,
  TokenType.STRING_INTERPOLATION_IDENTIFIER,
  TokenType.TILDE,
  TokenType.TILDE_SLASH,
  TokenType.TILDE_SLASH_EQ,
  TokenType.BACKPING,
  TokenType.BACKSLASH,
  TokenType.PERIOD_PERIOD_PERIOD,
  TokenType.PERIOD_PERIOD_PERIOD_QUESTION,
  TokenType.QUESTION_PERIOD_PERIOD,
  TokenType.BAD_INPUT,
  TokenType.RECOVERY,
  Keyword.ABSTRACT,
  Keyword.AS,
  Keyword.ASSERT,
  Keyword.ASYNC,
  Keyword.AUGMENT,
  Keyword.AWAIT,
  Keyword.BASE,
  Keyword.BREAK,
  Keyword.CASE,
  Keyword.CATCH,
  Keyword.CLASS,
  Keyword.CONST,
  Keyword.CONTINUE,
  Keyword.COVARIANT,
  Keyword.DEFAULT,
  Keyword.DEFERRED,
  Keyword.DO,
  Keyword.DYNAMIC,
  Keyword.ELSE,
  Keyword.ENUM,
  Keyword.EXPORT,
  Keyword.EXTENDS,
  Keyword.EXTENSION,
  Keyword.EXTERNAL,
  Keyword.FACTORY,
  Keyword.FALSE,
  Keyword.FINAL,
  Keyword.FINALLY,
  Keyword.FOR,
  Keyword.FUNCTION,
  Keyword.GET,
  Keyword.HIDE,
  Keyword.IF,
  Keyword.IMPLEMENTS,
  Keyword.IMPORT,
  Keyword.IN,
  Keyword.INOUT,
  Keyword.INTERFACE,
  Keyword.IS,
  Keyword.LATE,
  Keyword.LIBRARY,
  Keyword.MIXIN,
  Keyword.NATIVE,
  Keyword.NEW,
  Keyword.NULL,
  Keyword.OF,
  Keyword.ON,
  Keyword.OPERATOR,
  Keyword.OUT,
  Keyword.PART,
  Keyword.PATCH,
  Keyword.REQUIRED,
  Keyword.RETHROW,
  Keyword.RETURN,
  Keyword.SEALED,
  Keyword.SET,
  Keyword.SHOW,
  Keyword.SOURCE,
  Keyword.STATIC,
  Keyword.SUPER,
  Keyword.SWITCH,
  Keyword.SYNC,
  Keyword.THIS,
  Keyword.THROW,
  Keyword.TRUE,
  Keyword.TRY,
  Keyword.TYPEDEF,
  Keyword.VAR,
  Keyword.VOID,
  Keyword.WHEN,
  Keyword.WHILE,
  Keyword.WITH,
  Keyword.YIELD,
];
