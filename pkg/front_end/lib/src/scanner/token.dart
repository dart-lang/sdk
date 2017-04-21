// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the tokens that are produced by the scanner, used by the parser, and
 * referenced from the [AST structure](ast.dart).
 */
import 'dart:collection';

import 'package:front_end/src/base/syntactic_entity.dart';
import 'package:front_end/src/scanner/string_utilities.dart';
import 'package:front_end/src/fasta/scanner/keyword.dart' as fasta;
import 'package:front_end/src/fasta/scanner/precedence.dart' as fasta;

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
    assert(type == TokenType.OPEN_CURLY_BRACKET ||
        type == TokenType.OPEN_PAREN ||
        type == TokenType.OPEN_SQUARE_BRACKET ||
        type == TokenType.STRING_INTERPOLATION_EXPRESSION);
  }

  @override
  Token copy() => new BeginToken(type, offset);
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
  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = precedingComments;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
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
abstract class Keyword {
  static const Keyword ABSTRACT = fasta.Keyword.ABSTRACT;

  static const Keyword AS = fasta.Keyword.AS;

  static const Keyword ASSERT = fasta.Keyword.ASSERT;

  static const Keyword BREAK = fasta.Keyword.BREAK;

  static const Keyword CASE = fasta.Keyword.CASE;

  static const Keyword CATCH = fasta.Keyword.CATCH;

  static const Keyword CLASS = fasta.Keyword.CLASS;

  static const Keyword CONST = fasta.Keyword.CONST;

  static const Keyword CONTINUE = fasta.Keyword.CONTINUE;

  static const Keyword COVARIANT = fasta.Keyword.COVARIANT;

  static const Keyword DEFAULT = fasta.Keyword.DEFAULT;

  static const Keyword DEFERRED = fasta.Keyword.DEFERRED;

  static const Keyword DO = fasta.Keyword.DO;

  static const Keyword DYNAMIC = fasta.Keyword.DYNAMIC;

  static const Keyword ELSE = fasta.Keyword.ELSE;

  static const Keyword ENUM = fasta.Keyword.ENUM;

  static const Keyword EXPORT = fasta.Keyword.EXPORT;

  static const Keyword EXTENDS = fasta.Keyword.EXTENDS;

  static const Keyword EXTERNAL = fasta.Keyword.EXTERNAL;

  static const Keyword FACTORY = fasta.Keyword.FACTORY;

  static const Keyword FALSE = fasta.Keyword.FALSE;

  static const Keyword FINAL = fasta.Keyword.FINAL;

  static const Keyword FINALLY = fasta.Keyword.FINALLY;

  static const Keyword FOR = fasta.Keyword.FOR;

  static const Keyword GET = fasta.Keyword.GET;

  static const Keyword IF = fasta.Keyword.IF;

  static const Keyword IMPLEMENTS = fasta.Keyword.IMPLEMENTS;

  static const Keyword IMPORT = fasta.Keyword.IMPORT;

  static const Keyword IN = fasta.Keyword.IN;

  static const Keyword IS = fasta.Keyword.IS;

  static const Keyword LIBRARY = fasta.Keyword.LIBRARY;

  static const Keyword NEW = fasta.Keyword.NEW;

  static const Keyword NULL = fasta.Keyword.NULL;

  static const Keyword OPERATOR = fasta.Keyword.OPERATOR;

  static const Keyword PART = fasta.Keyword.PART;

  static const Keyword RETHROW = fasta.Keyword.RETHROW;

  static const Keyword RETURN = fasta.Keyword.RETURN;

  static const Keyword SET = fasta.Keyword.SET;

  static const Keyword STATIC = fasta.Keyword.STATIC;

  static const Keyword SUPER = fasta.Keyword.SUPER;

  static const Keyword SWITCH = fasta.Keyword.SWITCH;

  static const Keyword THIS = fasta.Keyword.THIS;

  static const Keyword THROW = fasta.Keyword.THROW;

  static const Keyword TRUE = fasta.Keyword.TRUE;

  static const Keyword TRY = fasta.Keyword.TRY;

  static const Keyword TYPEDEF = fasta.Keyword.TYPEDEF;

  static const Keyword VAR = fasta.Keyword.VAR;

  static const Keyword VOID = fasta.Keyword.VOID;

  static const Keyword WHILE = fasta.Keyword.WHILE;

  static const Keyword WITH = fasta.Keyword.WITH;

  static const List<Keyword> values = const <Keyword>[
    ABSTRACT,
    AS,
    ASSERT,
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
    GET,
    IF,
    IMPLEMENTS,
    IMPORT,
    IN,
    IS,
    LIBRARY,
    NEW,
    NULL,
    OPERATOR,
    PART,
    RETHROW,
    RETURN,
    SET,
    STATIC,
    SUPER,
    SWITCH,
    THIS,
    THROW,
    TRUE,
    TRY,
    TYPEDEF,
    VAR,
    VOID,
    WHILE,
    WITH,
  ];

  /**
   * A table mapping the lexemes of keywords to the corresponding keyword.
   */
  static final Map<String, Keyword> keywords = _createKeywordMap();

  /**
   * The name of the keyword type.
   */
  String get name;

  /**
   * The lexeme for the keyword.
   */
  String get syntax;

  /**
   * A flag indicating whether the keyword is a pseudo-keyword. Pseudo keywords
   * can be used as identifiers.
   */
  bool get isPseudoKeyword;

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
 * A token representing a keyword in the language.
 */
class KeywordToken extends SimpleToken {
  @override
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
  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = precedingComments;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
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

  /**
   * The next token in the token stream.
   */
  Token _next;

  /**
   * Initialize a newly created token to have the given [type] and [offset].
   */
  SimpleToken(this.type, this.offset);

  @override
  int get end => offset + length;

  @override
  bool get isOperator => type.isOperator;

  @override
  bool get isSynthetic => length == 0;

  @override
  bool get isUserDefinableOperator => type.isUserDefinableOperator;

  @override
  Keyword get keyword => null;

  @override
  int get length => lexeme.length;

  @override
  String get lexeme => type.lexeme;

  @override
  Token get next => _next;

  @override
  CommentToken get precedingComments => null;

  @override
  void applyDelta(int delta) {
    offset += delta;
  }

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
    _next = token;
    token.previous = this;
    return token;
  }

  @override
  Token setNextWithoutSettingPrevious(Token token) {
    _next = token;
    return token;
  }

  @override
  String toString() => lexeme;

  @override
  Object value() => type.lexeme;

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
  void applyDelta(int delta) {
    super.applyDelta(delta);
    Token token = precedingComments;
    while (token != null) {
      token.applyDelta(delta);
      token = token.next;
    }
  }

  @override
  Token copy() => new StringTokenWithComment(
      type, lexeme, offset, copyComments(precedingComments));
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

  @override
  int get end;

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

  @override
  int get length;

  /**
   * Return the lexeme that represents this token.
   */
  String get lexeme;

  /**
   * Return the next token in the token stream.
   */
  Token get next;

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
   * Return the type of the token.
   */
  TokenType get type;

  /**
   * Apply (add) the given [delta] to this token's offset.
   */
  void applyDelta(int delta);

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
abstract class TokenType {
  /**
   * The type of the token that marks the start or end of the input.
   */
  static const TokenType EOF = fasta.EOF_INFO;

  static const TokenType DOUBLE = fasta.DOUBLE_INFO;

  static const TokenType HEXADECIMAL = fasta.HEXADECIMAL_INFO;

  static const TokenType IDENTIFIER = fasta.IDENTIFIER_INFO;

  static const TokenType INT = fasta.INT_INFO;

  static const TokenType KEYWORD = fasta.KEYWORD_INFO;

  static const TokenType MULTI_LINE_COMMENT = fasta.MULTI_LINE_COMMENT_INFO;

  static const TokenType SCRIPT_TAG = fasta.SCRIPT_INFO;

  static const TokenType SINGLE_LINE_COMMENT = fasta.SINGLE_LINE_COMMENT_INFO;

  static const TokenType STRING = fasta.STRING_INFO;

  static const TokenType AMPERSAND = fasta.AMPERSAND_INFO;

  static const TokenType AMPERSAND_AMPERSAND = fasta.AMPERSAND_AMPERSAND_INFO;

  static const TokenType AMPERSAND_AMPERSAND_EQ =
      const fasta.PrecedenceInfo('&&=', 'AMPERSAND_AMPERSAND_EQ', 1, -1);

  static const TokenType AMPERSAND_EQ = fasta.AMPERSAND_EQ_INFO;

  static const TokenType AT = fasta.AT_INFO;

  static const TokenType BANG = fasta.BANG_INFO;

  static const TokenType BANG_EQ = fasta.BANG_EQ_INFO;

  static const TokenType BAR = fasta.BAR_INFO;

  static const TokenType BAR_BAR = fasta.BAR_BAR_INFO;

  static const TokenType BAR_BAR_EQ =
      const fasta.PrecedenceInfo('||=', 'BAR_BAR_EQ', 1, -1);

  static const TokenType BAR_EQ = fasta.BAR_EQ_INFO;

  static const TokenType COLON = fasta.COLON_INFO;

  static const TokenType COMMA = fasta.COMMA_INFO;

  static const TokenType CARET = fasta.CARET_INFO;

  static const TokenType CARET_EQ = fasta.CARET_EQ_INFO;

  static const TokenType CLOSE_CURLY_BRACKET = fasta.CLOSE_CURLY_BRACKET_INFO;

  static const TokenType CLOSE_PAREN = fasta.CLOSE_PAREN_INFO;

  static const TokenType CLOSE_SQUARE_BRACKET = fasta.CLOSE_SQUARE_BRACKET_INFO;

  static const TokenType EQ = fasta.EQ_INFO;

  static const TokenType EQ_EQ = fasta.EQ_EQ_INFO;

  static const TokenType FUNCTION = fasta.FUNCTION_INFO;

  static const TokenType GT = fasta.GT_INFO;

  static const TokenType GT_EQ = fasta.GT_EQ_INFO;

  static const TokenType GT_GT = fasta.GT_GT_INFO;

  static const TokenType GT_GT_EQ = fasta.GT_GT_EQ_INFO;

  static const TokenType HASH = fasta.HASH_INFO;

  static const TokenType INDEX = fasta.INDEX_INFO;

  static const TokenType INDEX_EQ = fasta.INDEX_EQ_INFO;

  static const TokenType LT = fasta.LT_INFO;

  static const TokenType LT_EQ = fasta.LT_EQ_INFO;

  static const TokenType LT_LT = fasta.LT_LT_INFO;

  static const TokenType LT_LT_EQ = fasta.LT_LT_EQ_INFO;

  static const TokenType MINUS = fasta.MINUS_INFO;

  static const TokenType MINUS_EQ = fasta.MINUS_EQ_INFO;

  static const TokenType MINUS_MINUS = fasta.MINUS_MINUS_INFO;

  static const TokenType OPEN_CURLY_BRACKET = fasta.OPEN_CURLY_BRACKET_INFO;

  static const TokenType OPEN_PAREN = fasta.OPEN_PAREN_INFO;

  static const TokenType OPEN_SQUARE_BRACKET = fasta.OPEN_SQUARE_BRACKET_INFO;

  static const TokenType PERCENT = fasta.PERCENT_INFO;

  static const TokenType PERCENT_EQ = fasta.PERCENT_EQ_INFO;

  static const TokenType PERIOD = fasta.PERIOD_INFO;

  static const TokenType PERIOD_PERIOD = fasta.PERIOD_PERIOD_INFO;

  static const TokenType PLUS = fasta.PLUS_INFO;

  static const TokenType PLUS_EQ = fasta.PLUS_EQ_INFO;

  static const TokenType PLUS_PLUS = fasta.PLUS_PLUS_INFO;

  static const TokenType QUESTION = fasta.QUESTION_INFO;

  static const TokenType QUESTION_PERIOD = fasta.QUESTION_PERIOD_INFO;

  static const TokenType QUESTION_QUESTION = fasta.QUESTION_QUESTION_INFO;

  static const TokenType QUESTION_QUESTION_EQ = fasta.QUESTION_QUESTION_EQ_INFO;

  static const TokenType SEMICOLON = fasta.SEMICOLON_INFO;

  static const TokenType SLASH = fasta.SLASH_INFO;

  static const TokenType SLASH_EQ = fasta.SLASH_EQ_INFO;

  static const TokenType STAR = fasta.STAR_INFO;

  static const TokenType STAR_EQ = fasta.STAR_EQ_INFO;

  static const TokenType STRING_INTERPOLATION_EXPRESSION =
      fasta.STRING_INTERPOLATION_INFO;

  static const TokenType STRING_INTERPOLATION_IDENTIFIER =
      fasta.STRING_INTERPOLATION_IDENTIFIER_INFO;

  static const TokenType TILDE = fasta.TILDE_INFO;

  static const TokenType TILDE_SLASH = fasta.TILDE_SLASH_INFO;

  static const TokenType TILDE_SLASH_EQ = fasta.TILDE_SLASH_EQ_INFO;

  static const TokenType BACKPING = fasta.BACKPING_INFO;

  static const TokenType BACKSLASH = fasta.BACKSLASH_INFO;

  static const TokenType PERIOD_PERIOD_PERIOD = fasta.PERIOD_PERIOD_PERIOD_INFO;

  static const TokenType GENERIC_METHOD_TYPE_LIST =
      const fasta.PrecedenceInfo(null, 'GENERIC_METHOD_TYPE_LIST', 0, -1);

  static const TokenType GENERIC_METHOD_TYPE_ASSIGN =
      const fasta.PrecedenceInfo(null, 'GENERIC_METHOD_TYPE_ASSIGN', 0, -1);

  /**
   * The name of the token type.
   */
  String get name;

  /**
   * The lexeme that defines this type of token, or `null` if there is more than
   * one possible lexeme for this type of token.
   */
  String get lexeme;

  /**
   * Return `true` if this type of token represents an additive operator.
   */
  bool get isAdditiveOperator;

  /**
   * Return `true` if this type of token represents an assignment operator.
   */
  bool get isAssignmentOperator;

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
  bool get isAssociativeOperator;

  /**
   * Return `true` if this type of token represents an equality operator.
   */
  bool get isEqualityOperator;

  /**
   * Return `true` if this type of token represents an increment operator.
   */
  bool get isIncrementOperator;

  /**
   * Return `true` if this type of token represents a multiplicative operator.
   */
  bool get isMultiplicativeOperator;

  /**
   * Return `true` if this token type represents an operator.
   */
  bool get isOperator;

  /**
   * Return `true` if this type of token represents a relational operator.
   */
  bool get isRelationalOperator;

  /**
   * Return `true` if this type of token represents a shift operator.
   */
  bool get isShiftOperator;

  /**
   * Return `true` if this type of token represents a unary postfix operator.
   */
  bool get isUnaryPostfixOperator;

  /**
   * Return `true` if this type of token represents a unary prefix operator.
   */
  bool get isUnaryPrefixOperator;

  /**
   * Return `true` if this token type represents an operator that can be defined
   * by users.
   */
  bool get isUserDefinableOperator;

  /**
   * Return the precedence of the token, or `0` if the token does not represent
   * an operator.
   */
  int get precedence;

  @override
  String toString() => name;
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
