// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the tokens that are produced by the scanner, used by the parser, and
 * referenced from the [AST structure](ast.dart).
 */
import 'dart:collection';

import 'package:front_end/src/base/syntactic_entity.dart';
import 'package:front_end/src/fasta/scanner/precedence.dart';
import 'package:front_end/src/scanner/string_utilities.dart';
import 'package:front_end/src/fasta/scanner/precedence.dart' as fasta;

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
  static const Keyword ABSTRACT = const Keyword("abstract", isBuiltIn: true);

  static const Keyword AS =
      const Keyword("as", info: fasta.AS_INFO, isBuiltIn: true);

  static const Keyword ASSERT = const Keyword("assert");

  static const Keyword ASYNC = const Keyword("async", isPseudo: true);

  static const Keyword AWAIT = const Keyword("await", isPseudo: true);

  static const Keyword BREAK = const Keyword("break");

  static const Keyword CASE = const Keyword("case");

  static const Keyword CATCH = const Keyword("catch");

  static const Keyword CLASS = const Keyword("class");

  static const Keyword CONST = const Keyword("const");

  static const Keyword CONTINUE = const Keyword("continue");

  static const Keyword COVARIANT = const Keyword("covariant", isBuiltIn: true);

  static const Keyword DEFAULT = const Keyword("default");

  static const Keyword DEFERRED = const Keyword("deferred", isBuiltIn: true);

  static const Keyword DO = const Keyword("do");

  static const Keyword DYNAMIC = const Keyword("dynamic", isBuiltIn: true);

  static const Keyword ELSE = const Keyword("else");

  static const Keyword ENUM = const Keyword("enum");

  static const Keyword EXPORT = const Keyword("export", isBuiltIn: true);

  static const Keyword EXTENDS = const Keyword("extends");

  static const Keyword EXTERNAL = const Keyword("external", isBuiltIn: true);

  static const Keyword FACTORY = const Keyword("factory", isBuiltIn: true);

  static const Keyword FALSE = const Keyword("false");

  static const Keyword FINAL = const Keyword("final");

  static const Keyword FINALLY = const Keyword("finally");

  static const Keyword FOR = const Keyword("for");

  static const Keyword FUNCTION = const Keyword("Function", isPseudo: true);

  static const Keyword GET = const Keyword("get", isBuiltIn: true);

  static const Keyword HIDE = const Keyword("hide", isPseudo: true);

  static const Keyword IF = const Keyword("if");

  static const Keyword IMPLEMENTS =
      const Keyword("implements", isBuiltIn: true);

  static const Keyword IMPORT = const Keyword("import", isBuiltIn: true);

  static const Keyword IN = const Keyword("in");

  static const Keyword IS = const Keyword("is", info: fasta.IS_INFO);

  static const Keyword LIBRARY = const Keyword("library", isBuiltIn: true);

  static const Keyword NATIVE = const Keyword("native", isPseudo: true);

  static const Keyword NEW = const Keyword("new");

  static const Keyword NULL = const Keyword("null");

  static const Keyword OF = const Keyword("of", isPseudo: true);

  static const Keyword ON = const Keyword("on", isPseudo: true);

  static const Keyword OPERATOR = const Keyword("operator", isBuiltIn: true);

  static const Keyword PART = const Keyword("part", isBuiltIn: true);

  static const Keyword PATCH = const Keyword("patch", isPseudo: true);

  static const Keyword RETHROW = const Keyword("rethrow");

  static const Keyword RETURN = const Keyword("return");

  static const Keyword SET = const Keyword("set", isBuiltIn: true);

  static const Keyword SHOW = const Keyword("show", isPseudo: true);

  static const Keyword SOURCE = const Keyword("source", isPseudo: true);

  static const Keyword STATIC = const Keyword("static", isBuiltIn: true);

  static const Keyword SUPER = const Keyword("super");

  static const Keyword SWITCH = const Keyword("switch");

  static const Keyword SYNC = const Keyword("sync", isPseudo: true);

  static const Keyword THIS = const Keyword("this");

  static const Keyword THROW = const Keyword("throw");

  static const Keyword TRUE = const Keyword("true");

  static const Keyword TRY = const Keyword("try");

  static const Keyword TYPEDEF = const Keyword("typedef", isBuiltIn: true);

  static const Keyword VAR = const Keyword("var");

  static const Keyword VOID = const Keyword("void");

  static const Keyword WHILE = const Keyword("while");

  static const Keyword WITH = const Keyword("with");

  static const Keyword YIELD = const Keyword("yield", isPseudo: true);

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

  final TokenType info;

  /**
   * A flag indicating whether the keyword is "built-in" identifier.
   */
  final bool isBuiltIn;

  /**
   * A flag indicating whether the keyword can be used as an identifier
   * in some situations.
   */
  final bool isPseudo;

  /**
   * The lexeme for the keyword.
   */
  final String syntax;

  /**
   * Initialize a newly created keyword.
   */
  const Keyword(this.syntax,
      {this.isBuiltIn: false,
      this.isPseudo: false,
      this.info: fasta.KEYWORD_INFO});

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
  String get name => syntax.toUpperCase();

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
  // Changed return type from Keyword to Object because
  // fasta considers pseudo-keywords to be keywords rather than identifiers
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
class TokenType {
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
      const TokenType('&&=', 'AMPERSAND_AMPERSAND_EQ', 1, -1);

  static const TokenType AMPERSAND_EQ = fasta.AMPERSAND_EQ_INFO;

  static const TokenType AT = fasta.AT_INFO;

  static const TokenType BANG = fasta.BANG_INFO;

  static const TokenType BANG_EQ = fasta.BANG_EQ_INFO;

  static const TokenType BAR = fasta.BAR_INFO;

  static const TokenType BAR_BAR = fasta.BAR_BAR_INFO;

  static const TokenType BAR_BAR_EQ =
      const TokenType('||=', 'BAR_BAR_EQ', 1, -1);

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
      fasta.GENERIC_METHOD_TYPE_LIST;

  static const TokenType GENERIC_METHOD_TYPE_ASSIGN =
      fasta.GENERIC_METHOD_TYPE_ASSIGN;

  static const List<TokenType> all = const <TokenType>[
    TokenType.EOF,
    TokenType.DOUBLE,
    TokenType.HEXADECIMAL,
    TokenType.IDENTIFIER,
    TokenType.INT,
    TokenType.KEYWORD,
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

    // These are not yet part of the language and not supported by fasta
    //TokenType.AMPERSAND_AMPERSAND_EQ,
    //TokenType.BAR_BAR_EQ,
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

  const TokenType(this.lexeme, this.name, this.precedence, this.kind,
      {this.isOperator: false, this.isUserDefinableOperator: false});

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
      this == AMPERSAND_INFO ||
      this == AMPERSAND_AMPERSAND_INFO ||
      this == BAR_INFO ||
      this == BAR_BAR_INFO ||
      this == CARET_INFO ||
      this == PLUS_INFO ||
      this == STAR_INFO;

  /**
   * Return `true` if this type of token represents an equality operator.
   */
  bool get isEqualityOperator => this == BANG_EQ_INFO || this == EQ_EQ_INFO;

  /**
   * Return `true` if this type of token represents an increment operator.
   */
  bool get isIncrementOperator =>
      this == PLUS_PLUS_INFO || this == MINUS_MINUS_INFO;

  /**
   * Return `true` if this type of token represents a multiplicative operator.
   */
  bool get isMultiplicativeOperator => precedence == MULTIPLICATIVE_PRECEDENCE;

  /**
   * Return `true` if this type of token represents a relational operator.
   */
  bool get isRelationalOperator =>
      this == LT_INFO ||
      this == LT_EQ_INFO ||
      this == GT_INFO ||
      this == GT_EQ_INFO;

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
      this == PLUS_PLUS_INFO ||
      this == MINUS_MINUS_INFO;

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
