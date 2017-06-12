// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the tokens that are produced by the scanner, used by the parser, and
 * referenced from the [AST structure](ast.dart).
 */
import 'dart:collection';

import 'package:front_end/src/base/syntactic_entity.dart';
import 'package:front_end/src/fasta/scanner/token_constants.dart';
import 'package:front_end/src/scanner/string_utilities.dart';

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

/**
 * The opening half of a grouping pair of tokens. This is used for curly
 * brackets ('{'), parentheses ('('), and square brackets ('[').
 */
class BeginToken extends SimpleToken {
  /**
   * The token that corresponds to this token.
   */
  Token endToken;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset].
   */
  BeginToken(TokenType type, int offset) : super(type, offset) {
    assert(type == TokenType.LT ||
        type == TokenType.OPEN_CURLY_BRACKET ||
        type == TokenType.OPEN_PAREN ||
        type == TokenType.OPEN_SQUARE_BRACKET ||
        type == TokenType.STRING_INTERPOLATION_EXPRESSION);
  }

  @override
  Token copy() => new BeginToken(type, offset);

  /**
   * The token that corresponds to this token.
   */
  Token get endGroup => endToken;

  /**
   * Set the token that corresponds to this token.
   */
  set endGroup(Token token) {
    endToken = token;
  }
}

/**
 * A begin token that is preceded by comments.
 */
class BeginTokenWithComment extends BeginToken implements TokenWithComment {
  /**
   * The first comment in the list of comments that precede this token.
   */
  @override
  CommentToken _precedingComment;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset] and to be preceded by the comments reachable from the given
   * [_precedingComment].
   */
  BeginTokenWithComment(TokenType type, int offset, this._precedingComment)
      : super(type, offset) {
    _setCommentParent(_precedingComment);
  }

  @override
  CommentToken get precedingComments => _precedingComment;

  @override
  void set precedingComments(CommentToken comment) {
    _precedingComment = comment;
    _setCommentParent(_precedingComment);
  }

  @override
  Token copy() =>
      new BeginTokenWithComment(type, offset, copyComments(precedingComments));
}

/**
 * A token representing a comment.
 */
class CommentToken extends StringToken {
  /**
   * The token that contains this comment.
   */
  TokenWithComment parent;

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  CommentToken(TokenType type, String value, int offset)
      : super(type, value, offset);

  @override
  CommentToken copy() => new CommentToken(type, _value, offset);

  /**
   * Remove this comment token from the list.
   *
   * This is used when we decide to interpret the comment as syntax.
   */
  void remove() {
    if (previous != null) {
      previous.setNextWithoutSettingPrevious(next);
      next?.previous = previous;
    } else {
      assert(parent.precedingComments == this);
      parent.precedingComments = next;
    }
  }
}

/**
 * A documentation comment token.
 */
class DocumentationCommentToken extends CommentToken {
  /**
   * The references embedded within the documentation comment.
   * This list will be empty unless this is a documentation comment that has
   * references embedded within it.
   */
  final List<Token> references = <Token>[];

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  DocumentationCommentToken(TokenType type, String value, int offset)
      : super(type, value, offset);

  @override
  CommentToken copy() {
    DocumentationCommentToken copy =
        new DocumentationCommentToken(type, _value, offset);
    references.forEach((ref) => copy.references.add(ref.copy()));
    return copy;
  }
}

/**
 * The keywords in the Dart programming language.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Keyword extends TokenType {
  static const Keyword ABSTRACT =
      const Keyword("abstract", "ABSTRACT", isBuiltIn: true);

  static const Keyword AS = const Keyword("as", "AS",
      precedence: RELATIONAL_PRECEDENCE, isBuiltIn: true);

  static const Keyword ASSERT = const Keyword("assert", "ASSERT");

  static const Keyword ASYNC = const Keyword("async", "ASYNC", isPseudo: true);

  static const Keyword AWAIT = const Keyword("await", "AWAIT", isPseudo: true);

  static const Keyword BREAK = const Keyword("break", "BREAK");

  static const Keyword CASE = const Keyword("case", "CASE");

  static const Keyword CATCH = const Keyword("catch", "CATCH");

  static const Keyword CLASS = const Keyword("class", "CLASS");

  static const Keyword CONST = const Keyword("const", "CONST");

  static const Keyword CONTINUE = const Keyword("continue", "CONTINUE");

  static const Keyword COVARIANT =
      const Keyword("covariant", "COVARIANT", isBuiltIn: true);

  static const Keyword DEFAULT = const Keyword("default", "DEFAULT");

  static const Keyword DEFERRED =
      const Keyword("deferred", "DEFERRED", isBuiltIn: true);

  static const Keyword DO = const Keyword("do", "DO");

  static const Keyword DYNAMIC =
      const Keyword("dynamic", "DYNAMIC", isBuiltIn: true);

  static const Keyword ELSE = const Keyword("else", "ELSE");

  static const Keyword ENUM = const Keyword("enum", "ENUM");

  static const Keyword EXPORT =
      const Keyword("export", "EXPORT", isBuiltIn: true);

  static const Keyword EXTENDS = const Keyword("extends", "EXTENDS");

  static const Keyword EXTERNAL =
      const Keyword("external", "EXTERNAL", isBuiltIn: true);

  static const Keyword FACTORY =
      const Keyword("factory", "FACTORY", isBuiltIn: true);

  static const Keyword FALSE = const Keyword("false", "FALSE");

  static const Keyword FINAL = const Keyword("final", "FINAL");

  static const Keyword FINALLY = const Keyword("finally", "FINALLY");

  static const Keyword FOR = const Keyword("for", "FOR");

  static const Keyword FUNCTION =
      const Keyword("Function", "FUNCTION", isPseudo: true);

  static const Keyword GET = const Keyword("get", "GET", isBuiltIn: true);

  static const Keyword HIDE = const Keyword("hide", "HIDE", isPseudo: true);

  static const Keyword IF = const Keyword("if", "IF");

  static const Keyword IMPLEMENTS =
      const Keyword("implements", "IMPLEMENTS", isBuiltIn: true);

  static const Keyword IMPORT =
      const Keyword("import", "IMPORT", isBuiltIn: true);

  static const Keyword IN = const Keyword("in", "IN");

  static const Keyword IS =
      const Keyword("is", "IS", precedence: RELATIONAL_PRECEDENCE);

  static const Keyword LIBRARY =
      const Keyword("library", "LIBRARY", isBuiltIn: true);

  static const Keyword NATIVE =
      const Keyword("native", "NATIVE", isPseudo: true);

  static const Keyword NEW = const Keyword("new", "NEW");

  static const Keyword NULL = const Keyword("null", "NULL");

  static const Keyword OF = const Keyword("of", "OF", isPseudo: true);

  static const Keyword ON = const Keyword("on", "ON", isPseudo: true);

  static const Keyword OPERATOR =
      const Keyword("operator", "OPERATOR", isBuiltIn: true);

  static const Keyword PART = const Keyword("part", "PART", isBuiltIn: true);

  static const Keyword PATCH = const Keyword("patch", "PATCH", isPseudo: true);

  static const Keyword RETHROW = const Keyword("rethrow", "RETHROW");

  static const Keyword RETURN = const Keyword("return", "RETURN");

  static const Keyword SET = const Keyword("set", "SET", isBuiltIn: true);

  static const Keyword SHOW = const Keyword("show", "SHOW", isPseudo: true);

  static const Keyword SOURCE =
      const Keyword("source", "SOURCE", isPseudo: true);

  static const Keyword STATIC =
      const Keyword("static", "STATIC", isBuiltIn: true);

  static const Keyword SUPER = const Keyword("super", "SUPER");

  static const Keyword SWITCH = const Keyword("switch", "SWITCH");

  static const Keyword SYNC = const Keyword("sync", "SYNC", isPseudo: true);

  static const Keyword THIS = const Keyword("this", "THIS");

  static const Keyword THROW = const Keyword("throw", "THROW");

  static const Keyword TRUE = const Keyword("true", "TRUE");

  static const Keyword TRY = const Keyword("try", "TRY");

  static const Keyword TYPEDEF =
      const Keyword("typedef", "TYPEDEF", isBuiltIn: true);

  static const Keyword VAR = const Keyword("var", "VAR");

  static const Keyword VOID = const Keyword("void", "VOID");

  static const Keyword WHILE = const Keyword("while", "WHILE");

  static const Keyword WITH = const Keyword("with", "WITH");

  static const Keyword YIELD = const Keyword("yield", "YIELD", isPseudo: true);

  static const List<Keyword> values = const <Keyword>[
    ABSTRACT,
    AS,
    ASSERT,
    ASYNC,
    AWAIT,
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
    IS,
    LIBRARY,
    NATIVE,
    NEW,
    NULL,
    OF,
    ON,
    OPERATOR,
    PART,
    PATCH,
    RETHROW,
    RETURN,
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
    WHILE,
    WITH,
    YIELD,
  ];

  /**
   * A table mapping the lexemes of keywords to the corresponding keyword.
   */
  static final Map<String, Keyword> keywords = _createKeywordMap();

  /**
   * A flag indicating whether the keyword is "built-in" identifier.
   */
  @override
  final bool isBuiltIn;

  @override
  final bool isPseudo;

  /**
   * Initialize a newly created keyword.
   */
  const Keyword(String lexeme, String name,
      {this.isBuiltIn: false,
      this.isPseudo: false,
      int precedence: NO_PRECEDENCE})
      : super(lexeme, name, precedence, KEYWORD_TOKEN);

  bool get isBuiltInOrPseudo => isBuiltIn || isPseudo;

  /**
   * A flag indicating whether the keyword is "built-in" identifier.
   * This method exists for backward compatibility and will be removed.
   * Use [isBuiltIn] instead.
   */
  @deprecated
  bool get isPseudoKeyword => isBuiltIn; // TODO (danrubel): remove this

  /**
   * The name of the keyword type.
   */
  String get name => lexeme.toUpperCase();

  /**
   * The lexeme for the keyword.
   *
   * Deprecated - use [lexeme] instead.
   */
  @deprecated
  String get syntax => lexeme;

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
  KeywordToken(this.keyword, int offset) : super(keyword, offset);

  @override
  Token copy() => new KeywordToken(keyword, offset);

  @override
  bool get isIdentifier => keyword.isPseudo || keyword.isBuiltIn;

  @override
  Object value() => keyword;
}

/**
 * A keyword token that is preceded by comments.
 */
class KeywordTokenWithComment extends KeywordToken implements TokenWithComment {
  /**
   * The first comment in the list of comments that precede this token.
   */
  @override
  CommentToken _precedingComment;

  /**
   * Initialize a newly created token to to represent the given [keyword] at the
   * given [offset] and to be preceded by the comments reachable from the given
   * [_precedingComment].
   */
  KeywordTokenWithComment(Keyword keyword, int offset, this._precedingComment)
      : super(keyword, offset) {
    _setCommentParent(_precedingComment);
  }

  @override
  CommentToken get precedingComments => _precedingComment;

  void set precedingComments(CommentToken comment) {
    _precedingComment = comment;
    _setCommentParent(_precedingComment);
  }

  @override
  Token copy() => new KeywordTokenWithComment(
      keyword, offset, copyComments(precedingComments));
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
  final TokenType type;

  /**
   * The offset from the beginning of the file to the first character in the
   * token.
   */
  @override
  int offset = 0;

  /**
   * The previous token in the token stream.
   */
  @override
  Token previous;

  @override
  Token next;

  /**
   * Initialize a newly created token to have the given [type] and [offset].
   */
  SimpleToken(this.type, this.offset);

  @override
  int get charCount => length;

  @override
  int get charOffset => offset;

  @override
  int get charEnd => end;

  @override
  int get end => offset + length;

  @override
  bool get isEof => type == TokenType.EOF;

  @override
  bool get isIdentifier => false;

  @override
  bool get isOperator => type.isOperator;

  @override
  bool get isSynthetic => length == 0;

  @override
  bool get isUserDefinableOperator => type.isUserDefinableOperator;

  @override
  Keyword get keyword => null;

  @override
  int get kind => type.kind;

  @override
  int get length => lexeme.length;

  @override
  String get lexeme => type.lexeme;

  @override
  CommentToken get precedingComments => null;

  @override
  String get stringValue => type.stringValue;

  @override
  Token copy() => new Token(type, offset);

  @override
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
    return token;
  }

  @override
  Token setNextWithoutSettingPrevious(Token token) {
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
  void _setCommentParent(CommentToken comment) {
    while (comment != null) {
      comment.parent = this;
      comment = comment.next;
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
  String _value;

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset].
   */
  StringToken(TokenType type, String value, int offset) : super(type, offset) {
    this._value = StringUtilities.intern(value);
  }

  @override
  bool get isIdentifier => identical(kind, IDENTIFIER_TOKEN);

  @override
  String get lexeme => _value;

  @override
  Token copy() => new StringToken(type, _value, offset);

  @override
  String value() => _value;
}

/**
 * A string token that is preceded by comments.
 */
class StringTokenWithComment extends StringToken implements TokenWithComment {
  /**
   * The first comment in the list of comments that precede this token.
   */
  CommentToken _precedingComment;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset] and to be preceded by the comments reachable from the given
   * [comment].
   */
  StringTokenWithComment(
      TokenType type, String value, int offset, this._precedingComment)
      : super(type, value, offset) {
    _setCommentParent(_precedingComment);
  }

  @override
  CommentToken get precedingComments => _precedingComment;

  void set precedingComments(CommentToken comment) {
    _precedingComment = comment;
    _setCommentParent(_precedingComment);
  }

  @override
  Token copy() => new StringTokenWithComment(
      type, lexeme, offset, copyComments(precedingComments));
}

/**
 * A synthetic keyword token.
 */
class SyntheticKeywordToken extends KeywordToken {
  /**
   * Initialize a newly created token to represent the given [keyword] at the
   * given [offset].
   */
  SyntheticKeywordToken(Keyword keyword, int offset) : super(keyword, offset);

  @override
  int get length => 0;

  @override
  Token copy() => new SyntheticKeywordToken(keyword, offset);
}

/**
 * A token whose value is independent of it's type.
 */
class SyntheticStringToken extends StringToken {
  final int _length;

  /**
   * Initialize a newly created token to represent a token of the given [type]
   * with the given [value] at the given [offset]. If the [length] is
   * not specified, then it defaults to the length of [value].
   */
  SyntheticStringToken(TokenType type, String value, int offset, [this._length])
      : super(type, value, offset);

  @override
  bool get isSynthetic => true;

  @override
  int get length => _length ?? super.length;

  @override
  Token copy() => new SyntheticStringToken(type, _value, offset);
}

/**
 * A synthetic token.
 */
class SyntheticToken extends SimpleToken {
  SyntheticToken(TokenType type, int offset) : super(type, offset);

  @override
  int get length => 0;

  @override
  Token copy() => new SyntheticToken(type, offset);
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
  factory Token(TokenType type, int offset) = SimpleToken;

  /**
   * Initialize a newly created end-of-file token to have the given [offset].
   */
  factory Token.eof(int offset, [CommentToken precedingComments]) {
    Token eof = precedingComments == null
        ? new SimpleToken(TokenType.EOF, offset)
        : new TokenWithComment(TokenType.EOF, offset, precedingComments);
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

  @override
  int get end;

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
   * Return `true` if this token represents an operator that can be defined by
   * users.
   */
  bool get isUserDefinableOperator;

  /**
   * Return the keyword, if a keyword token, or `null` otherwise.
   */
  Keyword get keyword;

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
  Token get next;

  /**
   * Return the next token in the token stream.
   */
  void set next(Token next);

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
  Token get precedingComments;

  /**
   * Return the previous token in the token stream.
   */
  Token get previous;

  /**
   * Set the previous token in the token stream to the given [token].
   */
  void set previous(Token token);

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
  String get stringValue;

  /**
   * Return the type of the token.
   */
  TokenType get type;

  /**
   * Return a newly created token that is a copy of this tokens
   * including any [preceedingComment] tokens,
   * but that is not a part of any token stream.
   */
  Token copy();

  /**
   * Copy a linked list of comment tokens identical to the given comment tokens.
   */
  Token copyComments(Token token);

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
  Token setNextWithoutSettingPrevious(Token token);

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
   * Compare the given [tokens] to find the token that appears first in the
   * source being parsed. That is, return the left-most of all of the tokens.
   * The list must be non-`null`, but the elements of the list are allowed to be
   * `null`. Return the token with the smallest offset, or `null` if the list is
   * empty or if all of the elements of the list are `null`.
   */
  static Token lexicallyFirst(List<Token> tokens) {
    Token first = null;
    int offset = -1;
    int length = tokens.length;
    for (int i = 0; i < length; i++) {
      Token token = tokens[i];
      if (token != null && (offset < 0 || token.offset < offset)) {
        first = token;
        offset = token.offset;
      }
    }
    return first;
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
      const TokenClass('ADDITIVE_OPERATOR', 13);

  /**
   * A value used to indicate that the token type is an assignment operator.
   */
  static const TokenClass ASSIGNMENT_OPERATOR =
      const TokenClass('ASSIGNMENT_OPERATOR', 1);

  /**
   * A value used to indicate that the token type is a bitwise-and operator.
   */
  static const TokenClass BITWISE_AND_OPERATOR =
      const TokenClass('BITWISE_AND_OPERATOR', 11);

  /**
   * A value used to indicate that the token type is a bitwise-or operator.
   */
  static const TokenClass BITWISE_OR_OPERATOR =
      const TokenClass('BITWISE_OR_OPERATOR', 9);

  /**
   * A value used to indicate that the token type is a bitwise-xor operator.
   */
  static const TokenClass BITWISE_XOR_OPERATOR =
      const TokenClass('BITWISE_XOR_OPERATOR', 10);

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
      const TokenClass('EQUALITY_OPERATOR', 7);

  /**
   * A value used to indicate that the token type is an if-null operator.
   */
  static const TokenClass IF_NULL_OPERATOR =
      const TokenClass('IF_NULL_OPERATOR', 4);

  /**
   * A value used to indicate that the token type is a logical-and operator.
   */
  static const TokenClass LOGICAL_AND_OPERATOR =
      const TokenClass('LOGICAL_AND_OPERATOR', 6);

  /**
   * A value used to indicate that the token type is a logical-or operator.
   */
  static const TokenClass LOGICAL_OR_OPERATOR =
      const TokenClass('LOGICAL_OR_OPERATOR', 5);

  /**
   * A value used to indicate that the token type is a multiplicative operator.
   */
  static const TokenClass MULTIPLICATIVE_OPERATOR =
      const TokenClass('MULTIPLICATIVE_OPERATOR', 14);

  /**
   * A value used to indicate that the token type is a relational operator.
   */
  static const TokenClass RELATIONAL_OPERATOR =
      const TokenClass('RELATIONAL_OPERATOR', 8);

  /**
   * A value used to indicate that the token type is a shift operator.
   */
  static const TokenClass SHIFT_OPERATOR =
      const TokenClass('SHIFT_OPERATOR', 12);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static const TokenClass UNARY_POSTFIX_OPERATOR =
      const TokenClass('UNARY_POSTFIX_OPERATOR', 16);

  /**
   * A value used to indicate that the token type is a unary operator.
   */
  static const TokenClass UNARY_PREFIX_OPERATOR =
      const TokenClass('UNARY_PREFIX_OPERATOR', 15);

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
  const TokenClass(this.name, [this.precedence = 0]);

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
      const TokenType('', 'EOF', NO_PRECEDENCE, EOF_TOKEN);

  static const TokenType DOUBLE = const TokenType(
      'double', 'DOUBLE', NO_PRECEDENCE, DOUBLE_TOKEN,
      stringValue: null);

  static const TokenType HEXADECIMAL = const TokenType(
      'hexadecimal', 'HEXADECIMAL', NO_PRECEDENCE, HEXADECIMAL_TOKEN,
      stringValue: null);

  static const TokenType IDENTIFIER = const TokenType(
      'identifier', 'STRING_INT', NO_PRECEDENCE, IDENTIFIER_TOKEN,
      stringValue: null);

  static const TokenType INT = const TokenType(
      'int', 'INT', NO_PRECEDENCE, INT_TOKEN,
      stringValue: null);

  static const TokenType MULTI_LINE_COMMENT = const TokenType(
      'comment', 'MULTI_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN,
      stringValue: null);

  static const TokenType SCRIPT_TAG =
      const TokenType('script', 'SCRIPT_TAG', NO_PRECEDENCE, SCRIPT_TOKEN);

  static const TokenType SINGLE_LINE_COMMENT = const TokenType(
      'comment', 'SINGLE_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN,
      stringValue: null);

  static const TokenType STRING = const TokenType(
      'string', 'STRING', NO_PRECEDENCE, STRING_TOKEN,
      stringValue: null);

  static const TokenType AMPERSAND = const TokenType(
      '&', 'AMPERSAND', BITWISE_AND_PRECEDENCE, AMPERSAND_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType AMPERSAND_AMPERSAND = const TokenType('&&',
      'AMPERSAND_AMPERSAND', LOGICAL_AND_PRECEDENCE, AMPERSAND_AMPERSAND_TOKEN,
      isOperator: true);

  // This is not yet part of the language and not supported by fasta
  static const TokenType AMPERSAND_AMPERSAND_EQ = const TokenType(
      '&&=',
      'AMPERSAND_AMPERSAND_EQ',
      ASSIGNMENT_PRECEDENCE,
      AMPERSAND_AMPERSAND_EQ_TOKEN,
      isOperator: true);

  static const TokenType AMPERSAND_EQ = const TokenType(
      '&=', 'AMPERSAND_EQ', ASSIGNMENT_PRECEDENCE, AMPERSAND_EQ_TOKEN,
      isOperator: true);

  static const TokenType AT =
      const TokenType('@', 'AT', NO_PRECEDENCE, AT_TOKEN);

  static const TokenType BANG = const TokenType(
      '!', 'BANG', PREFIX_PRECEDENCE, BANG_TOKEN,
      isOperator: true);

  static const TokenType BANG_EQ = const TokenType(
      '!=', 'BANG_EQ', EQUALITY_PRECEDENCE, BANG_EQ_TOKEN,
      isOperator: true);

  static const TokenType BANG_EQ_EQ = const TokenType(
      '!==', 'BANG_EQ_EQ', EQUALITY_PRECEDENCE, BANG_EQ_EQ_TOKEN);

  static const TokenType BAR = const TokenType(
      '|', 'BAR', BITWISE_OR_PRECEDENCE, BAR_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType BAR_BAR = const TokenType(
      '||', 'BAR_BAR', LOGICAL_OR_PRECEDENCE, BAR_BAR_TOKEN,
      isOperator: true);

  // This is not yet part of the language and not supported by fasta
  static const TokenType BAR_BAR_EQ = const TokenType(
      '||=', 'BAR_BAR_EQ', ASSIGNMENT_PRECEDENCE, BAR_BAR_EQ_TOKEN,
      isOperator: true);

  static const TokenType BAR_EQ = const TokenType(
      '|=', 'BAR_EQ', ASSIGNMENT_PRECEDENCE, BAR_EQ_TOKEN,
      isOperator: true);

  static const TokenType COLON =
      const TokenType(':', 'COLON', NO_PRECEDENCE, COLON_TOKEN);

  static const TokenType COMMA =
      const TokenType(',', 'COMMA', NO_PRECEDENCE, COMMA_TOKEN);

  static const TokenType CARET = const TokenType(
      '^', 'CARET', BITWISE_XOR_PRECEDENCE, CARET_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType CARET_EQ = const TokenType(
      '^=', 'CARET_EQ', ASSIGNMENT_PRECEDENCE, CARET_EQ_TOKEN,
      isOperator: true);

  static const TokenType CLOSE_CURLY_BRACKET = const TokenType(
      '}', 'CLOSE_CURLY_BRACKET', NO_PRECEDENCE, CLOSE_CURLY_BRACKET_TOKEN);

  static const TokenType CLOSE_PAREN =
      const TokenType(')', 'CLOSE_PAREN', NO_PRECEDENCE, CLOSE_PAREN_TOKEN);

  static const TokenType CLOSE_SQUARE_BRACKET = const TokenType(
      ']', 'CLOSE_SQUARE_BRACKET', NO_PRECEDENCE, CLOSE_SQUARE_BRACKET_TOKEN);

  static const TokenType EQ = const TokenType(
      '=', 'EQ', ASSIGNMENT_PRECEDENCE, EQ_TOKEN,
      isOperator: true);

  static const TokenType EQ_EQ = const TokenType(
      '==', 'EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  /// The `===` operator is not supported in the Dart language
  /// but is parsed as such by the scanner to support better recovery
  /// when a JavaScript code snippet is pasted into a Dart file.
  static const TokenType EQ_EQ_EQ =
      const TokenType('===', 'EQ_EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_EQ_TOKEN);

  static const TokenType FUNCTION =
      const TokenType('=>', 'FUNCTION', NO_PRECEDENCE, FUNCTION_TOKEN);

  static const TokenType GT = const TokenType(
      '>', 'GT', RELATIONAL_PRECEDENCE, GT_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType GT_EQ = const TokenType(
      '>=', 'GT_EQ', RELATIONAL_PRECEDENCE, GT_EQ_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType GT_GT = const TokenType(
      '>>', 'GT_GT', SHIFT_PRECEDENCE, GT_GT_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType GT_GT_EQ = const TokenType(
      '>>=', 'GT_GT_EQ', ASSIGNMENT_PRECEDENCE, GT_GT_EQ_TOKEN,
      isOperator: true);

  static const TokenType HASH =
      const TokenType('#', 'HASH', NO_PRECEDENCE, HASH_TOKEN);

  static const TokenType INDEX = const TokenType(
      '[]', 'INDEX', NO_PRECEDENCE, INDEX_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType INDEX_EQ = const TokenType(
      '[]=', 'INDEX_EQ', NO_PRECEDENCE, INDEX_EQ_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType LT = const TokenType(
      '<', 'LT', RELATIONAL_PRECEDENCE, LT_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType LT_EQ = const TokenType(
      '<=', 'LT_EQ', RELATIONAL_PRECEDENCE, LT_EQ_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType LT_LT = const TokenType(
      '<<', 'LT_LT', SHIFT_PRECEDENCE, LT_LT_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType LT_LT_EQ = const TokenType(
      '<<=', 'LT_LT_EQ', ASSIGNMENT_PRECEDENCE, LT_LT_EQ_TOKEN,
      isOperator: true);

  static const TokenType MINUS = const TokenType(
      '-', 'MINUS', ADDITIVE_PRECEDENCE, MINUS_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType MINUS_EQ = const TokenType(
      '-=', 'MINUS_EQ', ASSIGNMENT_PRECEDENCE, MINUS_EQ_TOKEN,
      isOperator: true);

  static const TokenType MINUS_MINUS = const TokenType(
      '--', 'MINUS_MINUS', POSTFIX_PRECEDENCE, MINUS_MINUS_TOKEN,
      isOperator: true);

  static const TokenType OPEN_CURLY_BRACKET = const TokenType(
      '{', 'OPEN_CURLY_BRACKET', NO_PRECEDENCE, OPEN_CURLY_BRACKET_TOKEN);

  static const TokenType OPEN_PAREN =
      const TokenType('(', 'OPEN_PAREN', POSTFIX_PRECEDENCE, OPEN_PAREN_TOKEN);

  static const TokenType OPEN_SQUARE_BRACKET = const TokenType('[',
      'OPEN_SQUARE_BRACKET', POSTFIX_PRECEDENCE, OPEN_SQUARE_BRACKET_TOKEN);

  static const TokenType PERCENT = const TokenType(
      '%', 'PERCENT', MULTIPLICATIVE_PRECEDENCE, PERCENT_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType PERCENT_EQ = const TokenType(
      '%=', 'PERCENT_EQ', ASSIGNMENT_PRECEDENCE, PERCENT_EQ_TOKEN,
      isOperator: true);

  static const TokenType PERIOD =
      const TokenType('.', 'PERIOD', POSTFIX_PRECEDENCE, PERIOD_TOKEN);

  static const TokenType PERIOD_PERIOD = const TokenType(
      '..', 'PERIOD_PERIOD', CASCADE_PRECEDENCE, PERIOD_PERIOD_TOKEN,
      isOperator: true);

  static const TokenType PLUS = const TokenType(
      '+', 'PLUS', ADDITIVE_PRECEDENCE, PLUS_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType PLUS_EQ = const TokenType(
      '+=', 'PLUS_EQ', ASSIGNMENT_PRECEDENCE, PLUS_EQ_TOKEN,
      isOperator: true);

  static const TokenType PLUS_PLUS = const TokenType(
      '++', 'PLUS_PLUS', POSTFIX_PRECEDENCE, PLUS_PLUS_TOKEN,
      isOperator: true);

  static const TokenType QUESTION = const TokenType(
      '?', 'QUESTION', CONDITIONAL_PRECEDENCE, QUESTION_TOKEN,
      isOperator: true);

  static const TokenType QUESTION_PERIOD = const TokenType(
      '?.', 'QUESTION_PERIOD', POSTFIX_PRECEDENCE, QUESTION_PERIOD_TOKEN,
      isOperator: true);

  static const TokenType QUESTION_QUESTION = const TokenType(
      '??', 'QUESTION_QUESTION', IF_NULL_PRECEDENCE, QUESTION_QUESTION_TOKEN,
      isOperator: true);

  static const TokenType QUESTION_QUESTION_EQ = const TokenType('??=',
      'QUESTION_QUESTION_EQ', ASSIGNMENT_PRECEDENCE, QUESTION_QUESTION_EQ_TOKEN,
      isOperator: true);

  static const TokenType SEMICOLON =
      const TokenType(';', 'SEMICOLON', NO_PRECEDENCE, SEMICOLON_TOKEN);

  static const TokenType SLASH = const TokenType(
      '/', 'SLASH', MULTIPLICATIVE_PRECEDENCE, SLASH_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType SLASH_EQ = const TokenType(
      '/=', 'SLASH_EQ', ASSIGNMENT_PRECEDENCE, SLASH_EQ_TOKEN,
      isOperator: true);

  static const TokenType STAR = const TokenType(
      '*', 'STAR', MULTIPLICATIVE_PRECEDENCE, STAR_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType STAR_EQ = const TokenType(
      '*=', 'STAR_EQ', ASSIGNMENT_PRECEDENCE, STAR_EQ_TOKEN,
      isOperator: true);

  static const TokenType STRING_INTERPOLATION_EXPRESSION = const TokenType(
      '\${',
      'STRING_INTERPOLATION_EXPRESSION',
      NO_PRECEDENCE,
      STRING_INTERPOLATION_TOKEN);

  static const TokenType STRING_INTERPOLATION_IDENTIFIER = const TokenType(
      '\$',
      'STRING_INTERPOLATION_IDENTIFIER',
      NO_PRECEDENCE,
      STRING_INTERPOLATION_IDENTIFIER_TOKEN);

  static const TokenType TILDE = const TokenType(
      '~', 'TILDE', PREFIX_PRECEDENCE, TILDE_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType TILDE_SLASH = const TokenType(
      '~/', 'TILDE_SLASH', MULTIPLICATIVE_PRECEDENCE, TILDE_SLASH_TOKEN,
      isOperator: true, isUserDefinableOperator: true);

  static const TokenType TILDE_SLASH_EQ = const TokenType(
      '~/=', 'TILDE_SLASH_EQ', ASSIGNMENT_PRECEDENCE, TILDE_SLASH_EQ_TOKEN,
      isOperator: true);

  static const TokenType BACKPING =
      const TokenType('`', 'BACKPING', NO_PRECEDENCE, BACKPING_TOKEN);

  static const TokenType BACKSLASH =
      const TokenType('\\', 'BACKSLASH', NO_PRECEDENCE, BACKSLASH_TOKEN);

  static const TokenType PERIOD_PERIOD_PERIOD = const TokenType(
      '...', 'PERIOD_PERIOD_PERIOD', NO_PRECEDENCE, PERIOD_PERIOD_PERIOD_TOKEN);

  static const TokenType GENERIC_METHOD_TYPE_LIST = const TokenType(
      'generic_comment_list',
      'GENERIC_METHOD_TYPE_LIST',
      NO_PRECEDENCE,
      GENERIC_METHOD_TYPE_LIST_TOKEN,
      stringValue: null);

  static const TokenType GENERIC_METHOD_TYPE_ASSIGN = const TokenType(
      'generic_comment_assign',
      'GENERIC_METHOD_TYPE_ASSIGN',
      NO_PRECEDENCE,
      GENERIC_METHOD_TYPE_ASSIGN_TOKEN,
      stringValue: null);

  static const TokenType AS = Keyword.AS;

  static const TokenType IS = Keyword.IS;

  /**
   * Token type used by error tokens.
   */
  static const TokenType BAD_INPUT = const TokenType(
      'malformed input', 'BAD_INPUT', NO_PRECEDENCE, BAD_INPUT_TOKEN,
      stringValue: null);

  /**
   * Token type used by synthetic tokens that are created during parser
   * recovery (non-analyzer use case).
   */
  static const TokenType RECOVERY = const TokenType(
      'recovery', 'RECOVERY', NO_PRECEDENCE, RECOVERY_TOKEN,
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
    TokenType.GENERIC_METHOD_TYPE_LIST,
    TokenType.GENERIC_METHOD_TYPE_ASSIGN,

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

  final int kind;

  /**
   * `true` if this token type represents an operator.
   */
  final bool isOperator;

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
  final String stringValue;

  const TokenType(this.lexeme, this.name, this.precedence, this.kind,
      {this.isOperator: false,
      this.isUserDefinableOperator: false,
      String stringValue: 'unspecified'})
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
      this == TokenType.PLUS_PLUS ||
      this == TokenType.MINUS_MINUS;

  @override
  String toString() => name;

  /**
   * Use [lexeme] instead of this method
   */
  @deprecated
  String get value => lexeme;
}

/**
 * A normal token that is preceded by comments.
 */
class TokenWithComment extends SimpleToken {
  /**
   * The first comment in the list of comments that precede this token.
   */
  CommentToken _precedingComment;

  /**
   * Initialize a newly created token to have the given [type] at the given
   * [offset] and to be preceded by the comments reachable from the given
   * [comment].
   */
  TokenWithComment(TokenType type, int offset, this._precedingComment)
      : super(type, offset) {
    _setCommentParent(_precedingComment);
  }

  @override
  CommentToken get precedingComments => _precedingComment;

  void set precedingComments(CommentToken comment) {
    _precedingComment = comment;
    _setCommentParent(_precedingComment);
  }

  @override
  Token copy() =>
      new TokenWithComment(type, offset, copyComments(precedingComments));
}
