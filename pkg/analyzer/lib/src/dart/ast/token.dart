// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.ast.token;

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/generated/java_engine.dart';

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
