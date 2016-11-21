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
class Keyword {
  static const Keyword ABSTRACT = const Keyword._('ABSTRACT', "abstract", true);

  static const Keyword AS = const Keyword._('AS', "as", true);

  static const Keyword ASSERT = const Keyword._('ASSERT', "assert");

  static const Keyword BREAK = const Keyword._('BREAK', "break");

  static const Keyword CASE = const Keyword._('CASE', "case");

  static const Keyword CATCH = const Keyword._('CATCH', "catch");

  static const Keyword CLASS = const Keyword._('CLASS', "class");

  static const Keyword CONST = const Keyword._('CONST', "const");

  static const Keyword CONTINUE = const Keyword._('CONTINUE', "continue");

  static const Keyword DEFAULT = const Keyword._('DEFAULT', "default");

  static const Keyword DEFERRED = const Keyword._('DEFERRED', "deferred", true);

  static const Keyword DO = const Keyword._('DO', "do");

  static const Keyword DYNAMIC = const Keyword._('DYNAMIC', "dynamic", true);

  static const Keyword ELSE = const Keyword._('ELSE', "else");

  static const Keyword ENUM = const Keyword._('ENUM', "enum");

  static const Keyword EXPORT = const Keyword._('EXPORT', "export", true);

  static const Keyword EXTENDS = const Keyword._('EXTENDS', "extends");

  static const Keyword EXTERNAL = const Keyword._('EXTERNAL', "external", true);

  static const Keyword FACTORY = const Keyword._('FACTORY', "factory", true);

  static const Keyword FALSE = const Keyword._('FALSE', "false");

  static const Keyword FINAL = const Keyword._('FINAL', "final");

  static const Keyword FINALLY = const Keyword._('FINALLY', "finally");

  static const Keyword FOR = const Keyword._('FOR', "for");

  static const Keyword GET = const Keyword._('GET', "get", true);

  static const Keyword IF = const Keyword._('IF', "if");

  static const Keyword IMPLEMENTS =
      const Keyword._('IMPLEMENTS', "implements", true);

  static const Keyword IMPORT = const Keyword._('IMPORT', "import", true);

  static const Keyword IN = const Keyword._('IN', "in");

  static const Keyword IS = const Keyword._('IS', "is");

  static const Keyword LIBRARY = const Keyword._('LIBRARY', "library", true);

  static const Keyword NEW = const Keyword._('NEW', "new");

  static const Keyword NULL = const Keyword._('NULL', "null");

  static const Keyword OPERATOR = const Keyword._('OPERATOR', "operator", true);

  static const Keyword PART = const Keyword._('PART', "part", true);

  static const Keyword RETHROW = const Keyword._('RETHROW', "rethrow");

  static const Keyword RETURN = const Keyword._('RETURN', "return");

  static const Keyword SET = const Keyword._('SET', "set", true);

  static const Keyword STATIC = const Keyword._('STATIC', "static", true);

  static const Keyword SUPER = const Keyword._('SUPER', "super");

  static const Keyword SWITCH = const Keyword._('SWITCH', "switch");

  static const Keyword THIS = const Keyword._('THIS', "this");

  static const Keyword THROW = const Keyword._('THROW', "throw");

  static const Keyword TRUE = const Keyword._('TRUE', "true");

  static const Keyword TRY = const Keyword._('TRY', "try");

  static const Keyword TYPEDEF = const Keyword._('TYPEDEF', "typedef", true);

  static const Keyword VAR = const Keyword._('VAR', "var");

  static const Keyword VOID = const Keyword._('VOID', "void");

  static const Keyword WHILE = const Keyword._('WHILE', "while");

  static const Keyword WITH = const Keyword._('WITH', "with");

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
  const Keyword._(this.name, this.syntax, [this.isPseudoKeyword = false]);

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
   * Return a newly created token that is a copy of this token but that is not a
   * part of any token stream.
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
class TokenType {
  /**
   * The type of the token that marks the start or end of the input.
   */
  static const TokenType EOF = const _EndOfFileTokenType();

  static const TokenType DOUBLE = const TokenType._('DOUBLE');

  static const TokenType HEXADECIMAL = const TokenType._('HEXADECIMAL');

  static const TokenType IDENTIFIER = const TokenType._('IDENTIFIER');

  static const TokenType INT = const TokenType._('INT');

  static const TokenType KEYWORD = const TokenType._('KEYWORD');

  static const TokenType MULTI_LINE_COMMENT =
      const TokenType._('MULTI_LINE_COMMENT');

  static const TokenType SCRIPT_TAG = const TokenType._('SCRIPT_TAG');

  static const TokenType SINGLE_LINE_COMMENT =
      const TokenType._('SINGLE_LINE_COMMENT');

  static const TokenType STRING = const TokenType._('STRING');

  static const TokenType AMPERSAND =
      const TokenType._('AMPERSAND', TokenClass.BITWISE_AND_OPERATOR, '&');

  static const TokenType AMPERSAND_AMPERSAND = const TokenType._(
      'AMPERSAND_AMPERSAND', TokenClass.LOGICAL_AND_OPERATOR, '&&');

  static const TokenType AMPERSAND_AMPERSAND_EQ = const TokenType._(
      'AMPERSAND_AMPERSAND_EQ', TokenClass.ASSIGNMENT_OPERATOR, '&&=');

  static const TokenType AMPERSAND_EQ =
      const TokenType._('AMPERSAND_EQ', TokenClass.ASSIGNMENT_OPERATOR, '&=');

  static const TokenType AT = const TokenType._('AT', TokenClass.NO_CLASS, '@');

  static const TokenType BANG =
      const TokenType._('BANG', TokenClass.UNARY_PREFIX_OPERATOR, '!');

  static const TokenType BANG_EQ =
      const TokenType._('BANG_EQ', TokenClass.EQUALITY_OPERATOR, '!=');

  static const TokenType BAR =
      const TokenType._('BAR', TokenClass.BITWISE_OR_OPERATOR, '|');

  static const TokenType BAR_BAR =
      const TokenType._('BAR_BAR', TokenClass.LOGICAL_OR_OPERATOR, '||');

  static const TokenType BAR_BAR_EQ =
      const TokenType._('BAR_BAR_EQ', TokenClass.ASSIGNMENT_OPERATOR, '||=');

  static const TokenType BAR_EQ =
      const TokenType._('BAR_EQ', TokenClass.ASSIGNMENT_OPERATOR, '|=');

  static const TokenType COLON =
      const TokenType._('COLON', TokenClass.NO_CLASS, ':');

  static const TokenType COMMA =
      const TokenType._('COMMA', TokenClass.NO_CLASS, ',');

  static const TokenType CARET =
      const TokenType._('CARET', TokenClass.BITWISE_XOR_OPERATOR, '^');

  static const TokenType CARET_EQ =
      const TokenType._('CARET_EQ', TokenClass.ASSIGNMENT_OPERATOR, '^=');

  static const TokenType CLOSE_CURLY_BRACKET =
      const TokenType._('CLOSE_CURLY_BRACKET', TokenClass.NO_CLASS, '}');

  static const TokenType CLOSE_PAREN =
      const TokenType._('CLOSE_PAREN', TokenClass.NO_CLASS, ')');

  static const TokenType CLOSE_SQUARE_BRACKET =
      const TokenType._('CLOSE_SQUARE_BRACKET', TokenClass.NO_CLASS, ']');

  static const TokenType EQ =
      const TokenType._('EQ', TokenClass.ASSIGNMENT_OPERATOR, '=');

  static const TokenType EQ_EQ =
      const TokenType._('EQ_EQ', TokenClass.EQUALITY_OPERATOR, '==');

  static const TokenType FUNCTION =
      const TokenType._('FUNCTION', TokenClass.NO_CLASS, '=>');

  static const TokenType GT =
      const TokenType._('GT', TokenClass.RELATIONAL_OPERATOR, '>');

  static const TokenType GT_EQ =
      const TokenType._('GT_EQ', TokenClass.RELATIONAL_OPERATOR, '>=');

  static const TokenType GT_GT =
      const TokenType._('GT_GT', TokenClass.SHIFT_OPERATOR, '>>');

  static const TokenType GT_GT_EQ =
      const TokenType._('GT_GT_EQ', TokenClass.ASSIGNMENT_OPERATOR, '>>=');

  static const TokenType HASH =
      const TokenType._('HASH', TokenClass.NO_CLASS, '#');

  static const TokenType INDEX =
      const TokenType._('INDEX', TokenClass.UNARY_POSTFIX_OPERATOR, '[]');

  static const TokenType INDEX_EQ =
      const TokenType._('INDEX_EQ', TokenClass.UNARY_POSTFIX_OPERATOR, '[]=');

  static const TokenType IS =
      const TokenType._('IS', TokenClass.RELATIONAL_OPERATOR, 'is');

  static const TokenType LT =
      const TokenType._('LT', TokenClass.RELATIONAL_OPERATOR, '<');

  static const TokenType LT_EQ =
      const TokenType._('LT_EQ', TokenClass.RELATIONAL_OPERATOR, '<=');

  static const TokenType LT_LT =
      const TokenType._('LT_LT', TokenClass.SHIFT_OPERATOR, '<<');

  static const TokenType LT_LT_EQ =
      const TokenType._('LT_LT_EQ', TokenClass.ASSIGNMENT_OPERATOR, '<<=');

  static const TokenType MINUS =
      const TokenType._('MINUS', TokenClass.ADDITIVE_OPERATOR, '-');

  static const TokenType MINUS_EQ =
      const TokenType._('MINUS_EQ', TokenClass.ASSIGNMENT_OPERATOR, '-=');

  static const TokenType MINUS_MINUS =
      const TokenType._('MINUS_MINUS', TokenClass.UNARY_PREFIX_OPERATOR, '--');

  static const TokenType OPEN_CURLY_BRACKET =
      const TokenType._('OPEN_CURLY_BRACKET', TokenClass.NO_CLASS, '{');

  static const TokenType OPEN_PAREN =
      const TokenType._('OPEN_PAREN', TokenClass.UNARY_POSTFIX_OPERATOR, '(');

  static const TokenType OPEN_SQUARE_BRACKET = const TokenType._(
      'OPEN_SQUARE_BRACKET', TokenClass.UNARY_POSTFIX_OPERATOR, '[');

  static const TokenType PERCENT =
      const TokenType._('PERCENT', TokenClass.MULTIPLICATIVE_OPERATOR, '%');

  static const TokenType PERCENT_EQ =
      const TokenType._('PERCENT_EQ', TokenClass.ASSIGNMENT_OPERATOR, '%=');

  static const TokenType PERIOD =
      const TokenType._('PERIOD', TokenClass.UNARY_POSTFIX_OPERATOR, '.');

  static const TokenType PERIOD_PERIOD =
      const TokenType._('PERIOD_PERIOD', TokenClass.CASCADE_OPERATOR, '..');

  static const TokenType PLUS =
      const TokenType._('PLUS', TokenClass.ADDITIVE_OPERATOR, '+');

  static const TokenType PLUS_EQ =
      const TokenType._('PLUS_EQ', TokenClass.ASSIGNMENT_OPERATOR, '+=');

  static const TokenType PLUS_PLUS =
      const TokenType._('PLUS_PLUS', TokenClass.UNARY_PREFIX_OPERATOR, '++');

  static const TokenType QUESTION =
      const TokenType._('QUESTION', TokenClass.CONDITIONAL_OPERATOR, '?');

  static const TokenType QUESTION_PERIOD = const TokenType._(
      'QUESTION_PERIOD', TokenClass.UNARY_POSTFIX_OPERATOR, '?.');

  static const TokenType QUESTION_QUESTION =
      const TokenType._('QUESTION_QUESTION', TokenClass.IF_NULL_OPERATOR, '??');

  static const TokenType QUESTION_QUESTION_EQ = const TokenType._(
      'QUESTION_QUESTION_EQ', TokenClass.ASSIGNMENT_OPERATOR, '??=');

  static const TokenType SEMICOLON =
      const TokenType._('SEMICOLON', TokenClass.NO_CLASS, ';');

  static const TokenType SLASH =
      const TokenType._('SLASH', TokenClass.MULTIPLICATIVE_OPERATOR, '/');

  static const TokenType SLASH_EQ =
      const TokenType._('SLASH_EQ', TokenClass.ASSIGNMENT_OPERATOR, '/=');

  static const TokenType STAR =
      const TokenType._('STAR', TokenClass.MULTIPLICATIVE_OPERATOR, '*');

  static const TokenType STAR_EQ =
      const TokenType._('STAR_EQ', TokenClass.ASSIGNMENT_OPERATOR, "*=");

  static const TokenType STRING_INTERPOLATION_EXPRESSION = const TokenType._(
      'STRING_INTERPOLATION_EXPRESSION', TokenClass.NO_CLASS, '\${');

  static const TokenType STRING_INTERPOLATION_IDENTIFIER = const TokenType._(
      'STRING_INTERPOLATION_IDENTIFIER', TokenClass.NO_CLASS, '\$');

  static const TokenType TILDE =
      const TokenType._('TILDE', TokenClass.UNARY_PREFIX_OPERATOR, '~');

  static const TokenType TILDE_SLASH = const TokenType._(
      'TILDE_SLASH', TokenClass.MULTIPLICATIVE_OPERATOR, '~/');

  static const TokenType TILDE_SLASH_EQ = const TokenType._(
      'TILDE_SLASH_EQ', TokenClass.ASSIGNMENT_OPERATOR, '~/=');

  static const TokenType BACKPING =
      const TokenType._('BACKPING', TokenClass.NO_CLASS, '`');

  static const TokenType BACKSLASH =
      const TokenType._('BACKSLASH', TokenClass.NO_CLASS, '\\');

  static const TokenType PERIOD_PERIOD_PERIOD =
      const TokenType._('PERIOD_PERIOD_PERIOD', TokenClass.NO_CLASS, '...');

  static const TokenType GENERIC_METHOD_TYPE_LIST =
      const TokenType._('GENERIC_METHOD_TYPE_LIST');

  static const TokenType GENERIC_METHOD_TYPE_ASSIGN =
      const TokenType._('GENERIC_METHOD_TYPE_ASSIGN');

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

  /**
   * Initialize a newly created token type to have the given [name],
   * [_tokenClass] and [lexeme].
   */
  const TokenType._(this.name,
      [this._tokenClass = TokenClass.NO_CLASS, this.lexeme = null]);

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
      identical(lexeme, '++') || identical(lexeme, '--');

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
      identical(lexeme, '==') ||
      identical(lexeme, '~') ||
      identical(lexeme, '[]') ||
      identical(lexeme, '[]=') ||
      identical(lexeme, '*') ||
      identical(lexeme, '/') ||
      identical(lexeme, '%') ||
      identical(lexeme, '~/') ||
      identical(lexeme, '+') ||
      identical(lexeme, '-') ||
      identical(lexeme, '<<') ||
      identical(lexeme, '>>') ||
      identical(lexeme, '>=') ||
      identical(lexeme, '>') ||
      identical(lexeme, '<=') ||
      identical(lexeme, '<') ||
      identical(lexeme, '&') ||
      identical(lexeme, '^') ||
      identical(lexeme, '|');

  /**
   * Return the precedence of the token, or `0` if the token does not represent
   * an operator.
   */
  int get precedence => _tokenClass.precedence;

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

/**
 * A token representing the end (either the head or the tail) of a stream of
 * tokens.
 */
class _EndOfFileTokenType extends TokenType {
  /**
   * Initialize a newly created token.
   */
  const _EndOfFileTokenType() : super._('EOF', TokenClass.NO_CLASS, '');

  @override
  String toString() => '-eof-';
}
