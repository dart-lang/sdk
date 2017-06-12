// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.token_utils;

import 'package:front_end/src/fasta/scanner/error_token.dart' show ErrorToken;

import 'package:front_end/src/scanner/token.dart' show Keyword, Token;

import 'package:front_end/src/fasta/scanner/token.dart'
    show BeginGroupToken, CommentToken, DartDocToken, StringToken, SymbolToken;

import 'package:front_end/src/fasta/scanner/token_constants.dart';

import 'package:front_end/src/scanner/errors.dart' show translateErrorToken;

import 'package:front_end/src/scanner/token.dart' as analyzer
    show
        BeginToken,
        BeginTokenWithComment,
        CommentToken,
        Keyword,
        KeywordToken,
        KeywordTokenWithComment,
        StringToken,
        StringTokenWithComment,
        Token,
        TokenWithComment;

import 'package:front_end/src/scanner/errors.dart' as analyzer
    show ScannerErrorCode;

import 'package:analyzer/dart/ast/token.dart' show TokenType;

import 'package:front_end/src/fasta/errors.dart' show internalError;

/// Class capable of converting a stream of Fasta tokens to a stream of analyzer
/// tokens.
///
/// This is a class rather than an ordinary method so that it can be subclassed
/// in tests.
///
/// TODO(paulberry,ahe): Fasta includes comments directly in the token
/// stream, rather than pointing to them via a "precedingComment" pointer, as
/// analyzer does.  This seems like it will complicate parsing and other
/// operations.
class ToAnalyzerTokenStreamConverter {
  /// Synthetic token pointing to the first token in the analyzer token stream.
  analyzer.Token _analyzerTokenHead;

  /// The most recently generated analyzer token, or [_analyzerTokenHead] if no
  /// tokens have been generated yet.
  analyzer.Token _analyzerTokenTail;

  /// Stack of analyzer "begin" tokens which need to be linked up to
  /// corresponding "end" tokens once those tokens are translated.
  ///
  /// The first element of this list is always a sentinel `null` value so that
  /// we don't have to check if it is empty.
  ///
  /// See additional documentation in [_matchGroups].
  List<analyzer.BeginToken> _beginTokenStack;

  /// Stack of fasta "end" tokens corresponding to the tokens in
  /// [_endTokenStack].
  ///
  /// The first element of this list is always a sentinel `null` value so that
  /// we don't have to check if it is empty.
  ///
  /// See additional documentation in [_matchGroups].
  List<Token> _endTokenStack;

  /// Converts a stream of Fasta tokens (starting with [token] and continuing to
  /// EOF) to a stream of analyzer tokens.
  analyzer.Token convertTokens(Token token) {
    _analyzerTokenHead = new analyzer.Token(TokenType.EOF, -1);
    _analyzerTokenHead.previous = _analyzerTokenHead;
    _analyzerTokenTail = _analyzerTokenHead;
    _beginTokenStack = [null];
    _endTokenStack = <Token>[null];

    while (true) {
      if (token.type.kind == BAD_INPUT_TOKEN) {
        ErrorToken errorToken = token;
        translateErrorToken(errorToken, reportError);
      } else {
        var translatedToken = translateToken(
            token, translateCommentTokens(token.precedingComments));
        _matchGroups(token, translatedToken);
        translatedToken.setNext(translatedToken);
        _analyzerTokenTail.setNext(translatedToken);
        translatedToken.previous = _analyzerTokenTail;
        _analyzerTokenTail = translatedToken;
      }
      if (token.isEof) {
        return _analyzerTokenHead.next;
      }
      token = token.next;
    }
  }

  /// Handles an error found during [convertTokens].
  ///
  /// Intended to be overridden by derived classes; by default, does nothing.
  void reportError(analyzer.ScannerErrorCode errorCode, int offset,
      List<Object> arguments) {}

  /// Translates a sequence of fasta comment tokens to the corresponding
  /// analyzer tokens.
  analyzer.CommentToken translateCommentTokens(analyzer.Token token) {
    analyzer.CommentToken head;
    if (token != null) {
      head = toAnalyzerCommentToken(token);
      analyzer.CommentToken tail = head;
      token = token.next;
      while (token != null) {
        tail = tail.setNext(toAnalyzerCommentToken(token));
        token = token.next;
      }
    }
    return head;
  }

  /// Translates a single fasta non-comment token to the corresponding analyzer
  /// token.
  ///
  /// [precedingComments] is not `null`, the translated token is pointed to it.
  analyzer.Token translateToken(
          Token token, analyzer.CommentToken precedingComments) =>
      toAnalyzerToken(token, precedingComments);

  /// Creates appropriate begin/end token links based on the fact that [token]
  /// was translated to [translatedToken].
  ///
  /// Background: both fasta and analyzer have links from a "BeginToken" to its
  /// matching "EndToken" in a group (like parentheses and braces).  However,
  /// fasta may contain synthetic tokens from error recovery that are not mapped
  /// to the analyzer token stream.  We use [_beginTokenStack] and
  /// [_endTokenStack] to create the appropriate links for non-synthetic tokens
  /// in the way analyzer expects.
  void _matchGroups(Token token, analyzer.Token translatedToken) {
    if (identical(_endTokenStack.last, token)) {
      _beginTokenStack.last.endToken = translatedToken;
      _beginTokenStack.removeLast();
      _endTokenStack.removeLast();
    }
    // Synthetic end tokens have a length of zero.
    if (translatedToken is analyzer.BeginToken &&
        token is BeginGroupToken &&
        token.endGroup != null &&
        token.endGroup.charOffset != token.charOffset) {
      _beginTokenStack.add(translatedToken);
      _endTokenStack.add(token.endGroup);
    }
  }
}

/// Converts a single Fasta comment token to an analyzer comment token.
analyzer.CommentToken toAnalyzerCommentToken(Token token) {
  TokenType type;
  if (token.type == TokenType.GENERIC_METHOD_TYPE_ASSIGN) {
    type = TokenType.GENERIC_METHOD_TYPE_ASSIGN;
  } else if (token.type == TokenType.GENERIC_METHOD_TYPE_LIST) {
    type = TokenType.GENERIC_METHOD_TYPE_LIST;
  } else {
    // TODO(paulberry,ahe): It would be nice if the scanner gave us an
    // easier way to distinguish between the two types of comment.
    type = token.lexeme.startsWith('/*')
        ? TokenType.MULTI_LINE_COMMENT
        : TokenType.SINGLE_LINE_COMMENT;
  }
  return new analyzer.CommentToken(type, token.lexeme, token.charOffset);
}

/// Converts a stream of Analyzer tokens (starting with [token] and continuing
/// to EOF) to a stream of Fasta tokens.
///
/// TODO(paulberry): Analyzer tokens do not record error conditions, so a round
/// trip through this function and [toAnalyzerTokenStream] will lose error
/// information.
Token fromAnalyzerTokenStream(analyzer.Token analyzerToken) {
  Token tokenHead = new SymbolToken.eof(-1);
  Token tokenTail = tokenHead;

  // Both fasta and analyzer have links from a "BeginToken" to its matching
  // "EndToken" in a group (like parentheses and braces).  However, only fasta
  // makes these links for angle brackets.  We use these stacks to map the
  // links from the analyzer token stream into equivalent links in the fasta
  // token stream, and to create the links that fasta expects for angle
  // brackets.

  // Note: beginTokenStack and endTokenStack are seeded with a sentinel value
  // so that we don't have to check if they're empty.
  var beginTokenStack = <BeginGroupToken>[null];
  var endTokenStack = <analyzer.Token>[null];
  var angleBracketStack = <BeginGroupToken>[];
  void matchGroups(analyzer.Token analyzerToken, Token translatedToken) {
    if (identical(endTokenStack.last, analyzerToken)) {
      angleBracketStack.clear();
      beginTokenStack.last.endGroup = translatedToken;
      beginTokenStack.removeLast();
      endTokenStack.removeLast();
    } else if (translatedToken.type.kind == LT_TOKEN) {
      BeginGroupToken beginGroupToken = translatedToken;
      angleBracketStack.add(beginGroupToken);
    } else if (translatedToken.type.kind == GT_TOKEN &&
        angleBracketStack.isNotEmpty) {
      angleBracketStack.removeLast().endGroup = translatedToken;
    } else if (translatedToken.type.kind == GT_GT_TOKEN &&
        angleBracketStack.isNotEmpty) {
      angleBracketStack.removeLast();
      if (angleBracketStack.isNotEmpty) {
        angleBracketStack.removeLast().endGroup = translatedToken;
      }
    }
    // TODO(paulberry): generate synthetic closer tokens and "UnmatchedToken"
    // tokens as appropriate.
    if (translatedToken is BeginGroupToken &&
        analyzerToken is analyzer.BeginToken &&
        analyzerToken.endToken != null) {
      angleBracketStack.clear();
      beginTokenStack.add(translatedToken);
      endTokenStack.add(analyzerToken.endToken);
    }
  }

  analyzer.Token translateAndAppend(analyzer.Token analyzerToken) {
    var token = fromAnalyzerToken(analyzerToken);
    // Sanity check
    if (analyzerToken.precedingComments != null) {
      if (token.precedingComments == null) {
        return internalError(
            'expected translated token $token to have preceedingComments');
      }
    } else {
      if (token.precedingComments != null) {
        return internalError('token $token has unexpected preceedingComments');
      }
    }
    tokenTail.next = token;
    tokenTail.next.previous = tokenTail; // ignore: deprecated_member_use
    tokenTail = token;
    matchGroups(analyzerToken, token);
    return analyzerToken.next;
  }

  while (true) {
    // TODO(paulberry): join up begingroup/endgroup.
    if (analyzerToken.type == TokenType.EOF) {
      SymbolToken eof = new SymbolToken.eof(analyzerToken.offset);
      tokenTail.next = eof;
      eof.previous = tokenTail; // ignore: deprecated_member_use
      eof.precedingComments =
          _translateComments(analyzerToken.precedingComments);
      eof.next = eof;
      return tokenHead.next;
    }
    analyzerToken = translateAndAppend(analyzerToken);
  }
}

/// Converts a single analyzer token into a Fasta token.
Token fromAnalyzerToken(analyzer.Token token) {
  Token comments = _translateComments(token.precedingComments);
  Token beginGroup(TokenType type) =>
      new BeginGroupToken(type, token.offset, comments);
  Token string(TokenType type) =>
      new StringToken.fromString(type, token.lexeme, token.offset,
          precedingComments: comments);
  Token symbol(TokenType type) => new SymbolToken(type, token.offset, comments);
  if (token.type.isKeyword) {
    var keyword = Keyword.keywords[token.lexeme];
    if (keyword != null) {
      return new analyzer.KeywordTokenWithComment(
          keyword, token.offset, comments);
    } else {
      return internalError("Unrecognized keyword: '${token.lexeme}'.");
    }
  }
  switch (token.type) {
    case TokenType.DOUBLE:
      return string(TokenType.DOUBLE);
    case TokenType.HEXADECIMAL:
      return string(TokenType.HEXADECIMAL);
    case TokenType.IDENTIFIER:
      // Certain identifiers have special grammatical meanings even though they
      // are neither keywords nor built-in identifiers (e.g. "async").  Analyzer
      // represents these as identifiers.  Fasta represents them as keywords
      // with the "isPseudo" property.
      var keyword = Keyword.keywords[token.lexeme];
      if (keyword != null) {
        assert(keyword.isPseudo);
        return new analyzer.KeywordTokenWithComment(
            keyword, token.offset, comments);
      } else {
        return string(TokenType.IDENTIFIER);
      }
      break;
    case TokenType.INT:
      return string(TokenType.INT);
    case TokenType.MULTI_LINE_COMMENT:
      if (token.lexeme.startsWith('/**')) {
        return new DartDocToken.fromSubstring(TokenType.MULTI_LINE_COMMENT,
            token.lexeme, 0, token.lexeme.length, 0);
      }
      return new CommentToken.fromSubstring(TokenType.MULTI_LINE_COMMENT,
          token.lexeme, 0, token.lexeme.length, 0);
    case TokenType.SCRIPT_TAG:
      return string(TokenType.SCRIPT_TAG);
    case TokenType.SINGLE_LINE_COMMENT:
      if (token.lexeme.startsWith('///')) {
        return new DartDocToken.fromSubstring(TokenType.SINGLE_LINE_COMMENT,
            token.lexeme, 0, token.lexeme.length, 0);
      }
      return new CommentToken.fromSubstring(TokenType.SINGLE_LINE_COMMENT,
          token.lexeme, 0, token.lexeme.length, 0);
    case TokenType.STRING:
      return string(TokenType.STRING);
    case TokenType.AMPERSAND:
      return symbol(TokenType.AMPERSAND);
    case TokenType.AMPERSAND_AMPERSAND:
      return symbol(TokenType.AMPERSAND_AMPERSAND);
    case TokenType.AMPERSAND_AMPERSAND_EQ:
      return symbol(TokenType.AMPERSAND_AMPERSAND_EQ);
    case TokenType.AMPERSAND_EQ:
      return symbol(TokenType.AMPERSAND_EQ);
    case TokenType.AT:
      return symbol(TokenType.AT);
    case TokenType.BANG:
      return symbol(TokenType.BANG);
    case TokenType.BANG_EQ:
      return symbol(TokenType.BANG_EQ);
    case TokenType.BAR:
      return symbol(TokenType.BAR);
    case TokenType.BAR_BAR:
      return symbol(TokenType.BAR_BAR);
    case TokenType.BAR_BAR_EQ:
      return symbol(TokenType.BAR_BAR_EQ);
    case TokenType.BAR_EQ:
      return symbol(TokenType.BAR_EQ);
    case TokenType.COLON:
      return symbol(TokenType.COLON);
    case TokenType.COMMA:
      return symbol(TokenType.COMMA);
    case TokenType.CARET:
      return symbol(TokenType.CARET);
    case TokenType.CARET_EQ:
      return symbol(TokenType.CARET_EQ);
    case TokenType.CLOSE_CURLY_BRACKET:
      return symbol(TokenType.CLOSE_CURLY_BRACKET);
    case TokenType.CLOSE_PAREN:
      return symbol(TokenType.CLOSE_PAREN);
    case TokenType.CLOSE_SQUARE_BRACKET:
      return symbol(TokenType.CLOSE_SQUARE_BRACKET);
    case TokenType.EQ:
      return symbol(TokenType.EQ);
    case TokenType.EQ_EQ:
      return symbol(TokenType.EQ_EQ);
    case TokenType.FUNCTION:
      return symbol(TokenType.FUNCTION);
    case TokenType.GT:
      return symbol(TokenType.GT);
    case TokenType.GT_EQ:
      return symbol(TokenType.GT_EQ);
    case TokenType.GT_GT:
      return symbol(TokenType.GT_GT);
    case TokenType.GT_GT_EQ:
      return symbol(TokenType.GT_GT_EQ);
    case TokenType.HASH:
      return symbol(TokenType.HASH);
    case TokenType.INDEX:
      return symbol(TokenType.INDEX);
    case TokenType.INDEX_EQ:
      return symbol(TokenType.INDEX_EQ);
    case TokenType.LT:
      return beginGroup(TokenType.LT);
    case TokenType.LT_EQ:
      return symbol(TokenType.LT_EQ);
    case TokenType.LT_LT:
      return symbol(TokenType.LT_LT);
    case TokenType.LT_LT_EQ:
      return symbol(TokenType.LT_LT_EQ);
    case TokenType.MINUS:
      return symbol(TokenType.MINUS);
    case TokenType.MINUS_EQ:
      return symbol(TokenType.MINUS_EQ);
    case TokenType.MINUS_MINUS:
      return symbol(TokenType.MINUS_MINUS);
    case TokenType.OPEN_CURLY_BRACKET:
      return beginGroup(TokenType.OPEN_CURLY_BRACKET);
    case TokenType.OPEN_PAREN:
      return beginGroup(TokenType.OPEN_PAREN);
    case TokenType.OPEN_SQUARE_BRACKET:
      return beginGroup(TokenType.OPEN_SQUARE_BRACKET);
    case TokenType.PERCENT:
      return symbol(TokenType.PERCENT);
    case TokenType.PERCENT_EQ:
      return symbol(TokenType.PERCENT_EQ);
    case TokenType.PERIOD:
      return symbol(TokenType.PERIOD);
    case TokenType.PERIOD_PERIOD:
      return symbol(TokenType.PERIOD_PERIOD);
    case TokenType.PLUS:
      return symbol(TokenType.PLUS);
    case TokenType.PLUS_EQ:
      return symbol(TokenType.PLUS_EQ);
    case TokenType.PLUS_PLUS:
      return symbol(TokenType.PLUS_PLUS);
    case TokenType.QUESTION:
      return symbol(TokenType.QUESTION);
    case TokenType.QUESTION_PERIOD:
      return symbol(TokenType.QUESTION_PERIOD);
    case TokenType.QUESTION_QUESTION:
      return symbol(TokenType.QUESTION_QUESTION);
    case TokenType.QUESTION_QUESTION_EQ:
      return symbol(TokenType.QUESTION_QUESTION_EQ);
    case TokenType.SEMICOLON:
      return symbol(TokenType.SEMICOLON);
    case TokenType.SLASH:
      return symbol(TokenType.SLASH);
    case TokenType.SLASH_EQ:
      return symbol(TokenType.SLASH_EQ);
    case TokenType.STAR:
      return symbol(TokenType.STAR);
    case TokenType.STAR_EQ:
      return symbol(TokenType.STAR_EQ);
    case TokenType.STRING_INTERPOLATION_EXPRESSION:
      return beginGroup(TokenType.STRING_INTERPOLATION_EXPRESSION);
    case TokenType.STRING_INTERPOLATION_IDENTIFIER:
      return symbol(TokenType.STRING_INTERPOLATION_IDENTIFIER);
    case TokenType.TILDE:
      return symbol(TokenType.TILDE);
    case TokenType.TILDE_SLASH:
      return symbol(TokenType.TILDE_SLASH);
    case TokenType.TILDE_SLASH_EQ:
      return symbol(TokenType.TILDE_SLASH_EQ);
    case TokenType.BACKPING:
      return symbol(TokenType.BACKPING);
    case TokenType.BACKSLASH:
      return symbol(TokenType.BACKSLASH);
    case TokenType.PERIOD_PERIOD_PERIOD:
      return symbol(TokenType.PERIOD_PERIOD_PERIOD);
    // case TokenType.GENERIC_METHOD_TYPE_ASSIGN
    // case TokenType.GENERIC_METHOD_TYPE_LIST
    default:
      return internalError('Unhandled token type ${token.type}');
  }
}

analyzer.Token toAnalyzerToken(Token token,
    [analyzer.CommentToken commentToken]) {
  if (token == null) return null;
  analyzer.Token makeStringToken(TokenType tokenType) {
    if (commentToken == null) {
      return new analyzer.StringToken(
          tokenType, token.lexeme, token.charOffset);
    } else {
      return new analyzer.StringTokenWithComment(
          tokenType, token.lexeme, token.charOffset, commentToken);
    }
  }

  analyzer.Token makeBeginToken(TokenType tokenType) {
    if (commentToken == null) {
      return new analyzer.BeginToken(tokenType, token.charOffset);
    } else {
      return new analyzer.BeginTokenWithComment(
          tokenType, token.charOffset, commentToken);
    }
  }

  switch (token.kind) {
    case DOUBLE_TOKEN:
      return makeStringToken(TokenType.DOUBLE);

    case HEXADECIMAL_TOKEN:
      return makeStringToken(TokenType.HEXADECIMAL);

    case IDENTIFIER_TOKEN:
      return makeStringToken(TokenType.IDENTIFIER);

    case INT_TOKEN:
      return makeStringToken(TokenType.INT);

    case KEYWORD_TOKEN:
      var syntax = token.type.lexeme;
      // TODO(paulberry): if the map lookup proves to be too slow, consider
      // using a switch statement, or perhaps a string of
      // "if (identical(syntax, "foo"))" checks.  (Note that identical checks
      // should be safe because the Fasta scanner uses string literals for
      // the values of keyword.syntax.)
      var keyword =
          _keywordMap[syntax] ?? internalError('Unknown keyword: $syntax');
      if (commentToken == null) {
        return new analyzer.KeywordToken(keyword, token.charOffset);
      } else {
        return new analyzer.KeywordTokenWithComment(
            keyword, token.charOffset, commentToken);
      }
      break;

    case SCRIPT_TOKEN:
      return makeStringToken(TokenType.SCRIPT_TAG);

    case STRING_TOKEN:
      return makeStringToken(TokenType.STRING);

    case OPEN_CURLY_BRACKET_TOKEN:
    case OPEN_SQUARE_BRACKET_TOKEN:
    case OPEN_PAREN_TOKEN:
    case STRING_INTERPOLATION_TOKEN:
      return makeBeginToken(token.type);

    default:
      if (commentToken == null) {
        return new analyzer.Token(token.type, token.charOffset);
      } else {
        return new analyzer.TokenWithComment(
            token.type, token.charOffset, commentToken);
      }
      break;
  }
}

analyzer.Token _translateComments(analyzer.Token token) {
  if (token == null) {
    return null;
  }
  Token head = fromAnalyzerToken(token);
  Token tail = head;
  token = token.next;
  while (token != null) {
    tail.next = fromAnalyzerToken(token);
    tail.next.previous = tail; // ignore: deprecated_member_use
    tail = tail.next;
    token = token.next;
  }
  return head;
}

final _keywordMap = {
  "assert": analyzer.Keyword.ASSERT,
  "break": analyzer.Keyword.BREAK,
  "case": analyzer.Keyword.CASE,
  "catch": analyzer.Keyword.CATCH,
  "class": analyzer.Keyword.CLASS,
  "const": analyzer.Keyword.CONST,
  "continue": analyzer.Keyword.CONTINUE,
  "default": analyzer.Keyword.DEFAULT,
  "do": analyzer.Keyword.DO,
  "else": analyzer.Keyword.ELSE,
  "enum": analyzer.Keyword.ENUM,
  "extends": analyzer.Keyword.EXTENDS,
  "false": analyzer.Keyword.FALSE,
  "final": analyzer.Keyword.FINAL,
  "finally": analyzer.Keyword.FINALLY,
  "for": analyzer.Keyword.FOR,
  "if": analyzer.Keyword.IF,
  "in": analyzer.Keyword.IN,
  "new": analyzer.Keyword.NEW,
  "null": analyzer.Keyword.NULL,
  "rethrow": analyzer.Keyword.RETHROW,
  "return": analyzer.Keyword.RETURN,
  "super": analyzer.Keyword.SUPER,
  "switch": analyzer.Keyword.SWITCH,
  "this": analyzer.Keyword.THIS,
  "throw": analyzer.Keyword.THROW,
  "true": analyzer.Keyword.TRUE,
  "try": analyzer.Keyword.TRY,
  "var": analyzer.Keyword.VAR,
  "void": analyzer.Keyword.VOID,
  "while": analyzer.Keyword.WHILE,
  "with": analyzer.Keyword.WITH,
  //
  "is": analyzer.Keyword.IS,
  //
  "abstract": analyzer.Keyword.ABSTRACT,
  "as": analyzer.Keyword.AS,
  "covariant": analyzer.Keyword.COVARIANT,
  "deferred": analyzer.Keyword.DEFERRED,
  "dynamic": analyzer.Keyword.DYNAMIC,
  "export": analyzer.Keyword.EXPORT,
  "external": analyzer.Keyword.EXTERNAL,
  "factory": analyzer.Keyword.FACTORY,
  "get": analyzer.Keyword.GET,
  "implements": analyzer.Keyword.IMPLEMENTS,
  "import": analyzer.Keyword.IMPORT,
  "library": analyzer.Keyword.LIBRARY,
  "operator": analyzer.Keyword.OPERATOR,
  "part": analyzer.Keyword.PART,
  "set": analyzer.Keyword.SET,
  "static": analyzer.Keyword.STATIC,
  "typedef": analyzer.Keyword.TYPEDEF,
  //
  "async": analyzer.Keyword.ASYNC,
  "await": analyzer.Keyword.AWAIT,
  "Function": analyzer.Keyword.FUNCTION,
  "hide": analyzer.Keyword.HIDE,
  "native": analyzer.Keyword.NATIVE,
  "of": analyzer.Keyword.OF,
  "on": analyzer.Keyword.ON,
  "patch": analyzer.Keyword.PATCH,
  "show": analyzer.Keyword.SHOW,
  "source": analyzer.Keyword.SOURCE,
  "sync": analyzer.Keyword.SYNC,
  "yield": analyzer.Keyword.YIELD,
};
