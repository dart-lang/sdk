// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the tokens that are produced by the scanner, used by the parser, and
 * referenced from the [AST structure](ast.dart).
 */
library analyzer.dart.ast.token;

import 'dart:collection';

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/src/dart/ast/token.dart' show SimpleToken, TokenClass;

/**
 * The keywords in the Dart programming language.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Keyword {
  static const Keyword ABSTRACT = const Keyword._("abstract", isBuiltIn: true);

  static const Keyword AS =
      const Keyword._("as", isBuiltIn: true);

  static const Keyword ASSERT = const Keyword._("assert");

  static const Keyword ASYNC = const Keyword._("async", isPseudo: true);

  static const Keyword AWAIT = const Keyword._("await", isPseudo: true);

  static const Keyword BREAK = const Keyword._("break");

  static const Keyword CASE = const Keyword._("case");

  static const Keyword CATCH = const Keyword._("catch");

  static const Keyword CLASS = const Keyword._("class");

  static const Keyword CONST = const Keyword._("const");

  static const Keyword CONTINUE = const Keyword._("continue");

  static const Keyword COVARIANT = const Keyword._("covariant", isBuiltIn: true);

  static const Keyword DEFAULT = const Keyword._("default");

  static const Keyword DEFERRED = const Keyword._("deferred", isBuiltIn: true);

  static const Keyword DO = const Keyword._("do");

  static const Keyword DYNAMIC = const Keyword._("dynamic", isBuiltIn: true);

  static const Keyword ELSE = const Keyword._("else");

  static const Keyword ENUM = const Keyword._("enum");

  static const Keyword EXPORT = const Keyword._("export", isBuiltIn: true);

  static const Keyword EXTENDS = const Keyword._("extends");

  static const Keyword EXTERNAL = const Keyword._("external", isBuiltIn: true);

  static const Keyword FACTORY = const Keyword._("factory", isBuiltIn: true);

  static const Keyword FALSE = const Keyword._("false");

  static const Keyword FINAL = const Keyword._("final");

  static const Keyword FINALLY = const Keyword._("finally");

  static const Keyword FOR = const Keyword._("for");

  static const Keyword FUNCTION = const Keyword._("Function", isPseudo: true);

  static const Keyword GET = const Keyword._("get", isBuiltIn: true);

  static const Keyword HIDE = const Keyword._("hide", isPseudo: true);

  static const Keyword IF = const Keyword._("if");

  static const Keyword IMPLEMENTS =
      const Keyword._("implements", isBuiltIn: true);

  static const Keyword IMPORT = const Keyword._("import", isBuiltIn: true);

  static const Keyword IN = const Keyword._("in");

  static const Keyword IS = const Keyword._("is");

  static const Keyword LIBRARY = const Keyword._("library", isBuiltIn: true);

  static const Keyword NATIVE = const Keyword._("native", isPseudo: true);

  static const Keyword NEW = const Keyword._("new");

  static const Keyword NULL = const Keyword._("null");

  static const Keyword OF = const Keyword._("of", isPseudo: true);

  static const Keyword ON = const Keyword._("on", isPseudo: true);

  static const Keyword OPERATOR = const Keyword._("operator", isBuiltIn: true);

  static const Keyword PART = const Keyword._("part", isBuiltIn: true);

  static const Keyword PATCH = const Keyword._("patch", isPseudo: true);

  static const Keyword RETHROW = const Keyword._("rethrow");

  static const Keyword RETURN = const Keyword._("return");

  static const Keyword SET = const Keyword._("set", isBuiltIn: true);

  static const Keyword SHOW = const Keyword._("show", isPseudo: true);

  static const Keyword SOURCE = const Keyword._("source", isPseudo: true);

  static const Keyword STATIC = const Keyword._("static", isBuiltIn: true);

  static const Keyword SUPER = const Keyword._("super");

  static const Keyword SWITCH = const Keyword._("switch");

  static const Keyword SYNC = const Keyword._("sync", isPseudo: true);

  static const Keyword THIS = const Keyword._("this");

  static const Keyword THROW = const Keyword._("throw");

  static const Keyword TRUE = const Keyword._("true");

  static const Keyword TRY = const Keyword._("try");

  static const Keyword TYPEDEF = const Keyword._("typedef", isBuiltIn: true);

  static const Keyword VAR = const Keyword._("var");

  static const Keyword VOID = const Keyword._("void");

  static const Keyword WHILE = const Keyword._("while");

  static const Keyword WITH = const Keyword._("with");

  static const Keyword YIELD = const Keyword._("yield", isPseudo: true);

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
  final String lexeme;

  /**
   * Initialize a newly created keyword to have the given [name] and [syntax].
   * The keyword is a pseudo-keyword if the [isPseudoKeyword] flag is `true`.
   */
  const Keyword._(this.lexeme,
      {this.isBuiltIn: false,
      this.isPseudo: false});

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

  /**
   * The lexeme for the keyword.
   *
   * Deprecated - use [lexeme] instead.
   */
  @deprecated
  String get syntax => lexeme; // TODO (danrubel): remove this

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
   * Return `true` if this type of token is a keyword.
   */
  bool get isKeyword => this == KEYWORD;

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
