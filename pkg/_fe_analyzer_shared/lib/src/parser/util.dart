// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.util;

import 'dart:typed_data';

import '../messages/codes.dart' show noLength;

import '../scanner/scanner.dart' show Keyword, Token;

import '../scanner/token.dart'
    show BeginToken, SimpleToken, SyntheticToken, TokenIsAExtension, TokenType;

/// Returns true if [token] is the symbol or keyword [value].
bool optional(String value, Token token) {
  return identical(value, token.stringValue);
}

/// Returns the token before the close brace, bracket, or parenthesis
/// associated with [left]. For '<', it may return `null`.
Token? beforeCloseBraceTokenFor(BeginToken left) {
  Token? endToken = left.endToken;
  if (endToken == null) {
    return null;
  }
  Token token = left;
  Token next = token.next!;
  while (next != endToken && next != next.next) {
    token = next;
    next = token.next!;
  }
  return token;
}

/// Return [token] or a token before [token] which is either
/// not synthetic or synthetic with non-zero length.
Token findPreviousNonZeroLengthToken(Token token) {
  while (token.isSynthetic && token.length == 0) {
    Token? previous = token.beforeSynthetic;
    if (previous == token) {
      throw new StateError("token == token.beforeSynthetic");
    }
    if (previous == null) {
      break;
    }
    token = previous;
  }
  return token;
}

/// Return [token] or a token after [token] which is either
/// not synthetic or synthetic with non-zero length.
/// This may return EOF if there are no more non-synthetic tokens in the stream.
Token findNonZeroLengthToken(Token token) {
  while (token.isSynthetic && token.length == 0 && !token.isEof) {
    token = token.next!;
  }
  return token;
}

bool isDigit(int c) => c >= 0x30 && c <= 0x39;

bool isLetter(int c) => c >= 0x41 && c <= 0x5A || c >= 0x61 && c <= 0x7A;

bool isLetterOrDigit(int c) => isLetter(c) || isDigit(c);

bool isWhitespace(int c) => c == 0x20 || c == 0xA || c == 0xD || c == 0x9;

bool isAnyOf(Token token, List<TokenType> values) {
  TokenType type = token.type;
  for (TokenType tokenValue in values) {
    if (tokenValue == type) {
      return true;
    }
  }
  return false;
}

/// A null-aware alternative to `token.length`.  If [token] is `null`, returns
/// [noLength].
int lengthForToken(Token? token) {
  return token == null ? noLength : token.length;
}

/// Returns the length of the span from [begin] to [end] (inclusive). If both
/// tokens are null, return [noLength]. If one of the tokens are null, return
/// the length of the other token.
int lengthOfSpan(Token? begin, Token? end) {
  if (begin == null) return lengthForToken(end);
  if (end == null) return lengthForToken(begin);
  return end.offset + end.length - begin.offset;
}

Token skipMetadata(Token token) {
  token = token.next!;
  assert(token.isA(TokenType.AT));
  Token next = token.next!;
  // Corresponds to 'ensureIdentifier' in [parseMetadata].
  if (next.isIdentifier) {
    token = next;
    next = token.next!;
    // Corresponds to 'parseQualifiedRestOpt' in [parseMetadata].
    if (next.isA(TokenType.PERIOD)) {
      token = next;
      next = token.next!;
      if (next.isIdentifier) {
        token = next;
        next = token.next!;
      }
    }
    // Corresponds to 'computeTypeParamOrArg' in [parseMetadata].
    if (next.isA(TokenType.LT) && !next.endGroup!.isSynthetic) {
      token = next.endGroup!;
      next = token.next!;
    }

    // The extra .identifier after arguments in [parseMetadata].
    if (next.isA(TokenType.PERIOD)) {
      token = next;
      next = token.next!;
      if (next.isIdentifier) {
        token = next;
        next = token.next!;
      }
    }

    // Corresponds to 'parseArgumentsOpt' in [parseMetadata].
    if (next.isA(TokenType.OPEN_PAREN) && !next.endGroup!.isSynthetic) {
      token = next.endGroup!;
      next = token.next!;
    }
  }
  return token;
}

/// Split `>=` into two separate tokens.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtEq(Token token) {
  assert(token.isA(TokenType.GT_EQ));
  return new SimpleToken(
    TokenType.GT,
    token.charOffset,
    token.precedingComments,
  )..setNext(
    new SimpleToken(TokenType.EQ, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next,
  );
}

/// Split `>>` into two separate tokens.
/// Call [Token.setNext] to add the token to the stream.
SimpleToken splitGtGt(Token token) {
  assert(token.isA(TokenType.GT_GT));
  return new SimpleToken(
    TokenType.GT,
    token.charOffset,
    token.precedingComments,
  )..setNext(
    new SimpleToken(TokenType.GT, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next,
  );
}

/// Split `>>=` into three separate tokens.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtGtEq(Token token) {
  assert(token.isA(TokenType.GT_GT_EQ));
  return new SimpleToken(
    TokenType.GT,
    token.charOffset,
    token.precedingComments,
  )..setNext(
    new SimpleToken(TokenType.GT, token.charOffset + 1)..setNext(
      new SimpleToken(TokenType.EQ, token.charOffset + 2)
        // Set next rather than calling Token.setNext
        // so that the previous token is not set.
        ..next = token.next,
    ),
  );
}

/// Split `>>=` into two separate tokens... `>` followed by `>=`.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtFromGtGtEq(Token token) {
  assert(token.isA(TokenType.GT_GT_EQ));
  return new SimpleToken(
    TokenType.GT,
    token.charOffset,
    token.precedingComments,
  )..setNext(
    new SimpleToken(TokenType.GT_EQ, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next,
  );
}

/// Split `>>>` into two separate tokens... `>` followed by `>>`.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtFromGtGtGt(Token token) {
  assert(token.isA(TokenType.GT_GT_GT));
  return new SimpleToken(
    TokenType.GT,
    token.charOffset,
    token.precedingComments,
  )..setNext(
    new SimpleToken(TokenType.GT_GT, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next,
  );
}

/// Split `>>>=` into two separate tokens... `>` followed by `>>=`.
/// Call [Token.setNext] to add the token to the stream.
Token splitGtFromGtGtGtEq(Token token) {
  assert(token.isA(TokenType.GT_GT_GT_EQ));
  return new SimpleToken(
    TokenType.GT,
    token.charOffset,
    token.precedingComments,
  )..setNext(
    new SimpleToken(TokenType.GT_GT_EQ, token.charOffset + 1)
      // Set next rather than calling Token.setNext
      // so that the previous token is not set.
      ..next = token.next,
  );
}

/// Strips separator characters (underscore) from [source].
///
/// No validation is performed on [source]; it could be a valid int, a valid
/// double, or invalid.
String stripSeparators(String source) {
  Uint8List list = _separatorStripBuffer;
  if (list.length < source.length - 1) {
    // Looking at a very long number. Allocate a new buffer.
    // We only strip separators after finding that there is at least one
    // separator, so the length can be reduced by at least one character.
    list = new Uint8List(source.length - 1);
    if (list.length < 128) {
      // Store the new, larger list as the reusable buffer.
      _separatorStripBuffer = list;
    }
  }

  int writeIndex = 0;
  for (int i = 0; i < source.length; i++) {
    int char = source.codeUnitAt(i);
    if (char != 0x5f /* _ */ ) list[writeIndex++] = char;
  }
  return new String.fromCharCodes(list, 0, writeIndex);
}

/// A reusable buffer for stripping separators from number literals.
///
/// The majority of number literals fit in 24 characters. A maximal double with
/// no unnecessary leading or trailing zeros is 17 digits, one decimal point,
/// one 'e', two '-'s, and three exponent digits: 24 characters.
Uint8List _separatorStripBuffer = new Uint8List(24);

/// Return a synthetic `>` followed by [next].
/// Call [Token.setNext] to add the token to the stream.
Token syntheticGt(Token next) {
  return new SyntheticToken(TokenType.GT, next.charOffset)
    // Set next rather than calling Token.setNext
    // so that the previous token is not set.
    ..next = next;
}

/// Returns the boolean value from a 'true' or 'false' [token].
bool boolFromToken(Token token) {
  bool value = token.isA(Keyword.TRUE);
  assert(value || token.isA(Keyword.FALSE));
  return value;
}

/// Returns the integer value from an integer literal token.
///
/// If [hasSeparators], separator characters, '_', are stripped before parsing
/// the token text.
///
/// `null` is returned if the token text could not be parsed as an integer
/// value. This does _not_ mean that the token is not valid as an integer token
/// since negated integer literals are parsed as a unary operation on the
/// positive integer.
int? intFromToken(Token token, {required bool hasSeparators}) {
  String text = token.lexeme;
  if (hasSeparators) {
    text = stripSeparators(text);
  }
  return int.tryParse(text);
}

/// Returns the double value from an double literal token.
///
/// If [hasSeparators], separator characters, '_', are stripped before parsing
/// the token text.
double doubleFromToken(Token token, {required bool hasSeparators}) {
  String text = token.lexeme;
  if (hasSeparators) {
    text = stripSeparators(text);
  }
  return double.parse(text);
}
