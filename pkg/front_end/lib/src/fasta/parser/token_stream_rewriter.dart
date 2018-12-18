// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../scanner/error_token.dart' show UnmatchedToken;

import '../../scanner/token.dart'
    show
        BeginToken,
        SimpleToken,
        SyntheticBeginToken,
        SyntheticStringToken,
        SyntheticToken,
        Token,
        TokenType;

/// Provides the capability of inserting tokens into a token stream. This
/// implementation does this by rewriting the previous token to point to the
/// inserted token.
class TokenStreamRewriter {
  // TODO(brianwilkerson):
  //
  // When we get to the point of removing `token.previous`, the plan is to
  // convert this into an interface and provide two implementations.
  //
  // One, used by Fasta, will connect the inserted tokens to the following token
  // without modifying the previous token.
  //
  // The other, used by 'analyzer', will be created with the first token in the
  // stream (actually with the BOF marker at the beginning of the stream). It
  // will be created only when invoking 'analyzer' specific parse methods (in
  // `Parser`), such as
  //
  // Token parseUnitWithRewrite(Token bof) {
  //   rewriter = AnalyzerTokenStreamRewriter(bof);
  //   return parseUnit(bof.next);
  // }
  //

  /// Insert a synthetic open and close parenthesis and return the new synthetic
  /// open parenthesis. If [insertIdentifier] is true, then a synthetic
  /// identifier is included between the open and close parenthesis.
  Token insertParens(Token token, bool includeIdentifier) {
    Token next = token.next;
    int offset = next.charOffset;
    BeginToken leftParen =
        next = new SyntheticBeginToken(TokenType.OPEN_PAREN, offset);
    if (includeIdentifier) {
      next = next.setNext(
          new SyntheticStringToken(TokenType.IDENTIFIER, '', offset, 0));
    }
    next = next.setNext(new SyntheticToken(TokenType.CLOSE_PAREN, offset));
    leftParen.endGroup = next;
    next.setNext(token.next);

    // A no-op rewriter could skip this step.
    token.setNext(leftParen);

    return leftParen;
  }

  /// Insert a synthetic identifier after [token] and return the new identifier.
  Token insertSyntheticIdentifier(Token token) {
    return insertToken(
        token,
        new SyntheticStringToken(
            TokenType.IDENTIFIER, '', token.next.charOffset, 0));
  }

  /// Insert [newToken] after [token] and return [newToken].
  Token insertToken(Token token, Token newToken) {
    newToken.setNext(token.next);

    // A no-op rewriter could skip this step.
    token.setNext(newToken);

    return newToken;
  }

  /// Move [endGroup] (a synthetic `)`, `]`, or `}` token) and associated
  /// error token after [token] in the token stream and return [endGroup].
  Token moveSynthetic(Token token, Token endGroup) {
    assert(endGroup.beforeSynthetic != null);
    Token errorToken;
    if (endGroup.next is UnmatchedToken) {
      errorToken = endGroup.next;
    }

    // Remove endGroup from its current location
    endGroup.beforeSynthetic.setNext((errorToken ?? endGroup).next);

    // Insert endGroup into its new location
    Token next = token.next;
    token.setNext(endGroup);
    (errorToken ?? endGroup).setNext(next);
    endGroup.offset = next.offset;
    if (errorToken != null) {
      errorToken.offset = next.offset;
    }

    return endGroup;
  }

  /// Replace the single token immediately following the [previousToken] with
  /// the chain of tokens starting at the [replacementToken]. Return the
  /// [replacementToken].
  Token replaceTokenFollowing(Token previousToken, Token replacementToken) {
    Token replacedToken = previousToken.next;
    previousToken.setNext(replacementToken);

    (replacementToken as SimpleToken).precedingComments =
        replacedToken.precedingComments;

    _lastTokenInChain(replacementToken).setNext(replacedToken.next);

    return replacementToken;
  }

  /// Given the [firstToken] in a chain of tokens to be inserted, return the
  /// last token in the chain.
  ///
  /// As a side-effect, this method also ensures that the tokens in the chain
  /// have their `previous` pointers set correctly.
  Token _lastTokenInChain(Token firstToken) {
    Token previous;
    Token current = firstToken;
    while (current.next != null && current.next.type != TokenType.EOF) {
      if (previous != null) {
        current.previous = previous;
      }
      previous = current;
      current = current.next;
    }
    if (previous != null) {
      current.previous = previous;
    }
    return current;
  }
}

/// Provides the capability of adding tokens that lead into a token stream
/// without modifying the original token stream and not setting the any token's
/// `previous` field.
class TokenStreamGhostWriter implements TokenStreamRewriter {
  @override
  Token insertParens(Token token, bool includeIdentifier) {
    Token next = token.next;
    int offset = next.charOffset;
    BeginToken leftParen =
        next = new SyntheticBeginToken(TokenType.OPEN_PAREN, offset);
    if (includeIdentifier) {
      Token identifier =
          new SyntheticStringToken(TokenType.IDENTIFIER, '', offset, 0);
      next.next = identifier;
      next = identifier;
    }
    Token rightParen = new SyntheticToken(TokenType.CLOSE_PAREN, offset);
    next.next = rightParen;
    rightParen.next = token.next;

    return leftParen;
  }

  /// Insert a synthetic identifier after [token] and return the new identifier.
  Token insertSyntheticIdentifier(Token token) {
    return insertToken(
        token,
        new SyntheticStringToken(
            TokenType.IDENTIFIER, '', token.next.charOffset, 0));
  }

  @override
  Token insertToken(Token token, Token newToken) {
    newToken.next = token.next;
    return newToken;
  }

  @override
  Token moveSynthetic(Token token, Token endGroup) {
    Token newEndGroup =
        new SyntheticToken(endGroup.type, token.next.charOffset);
    newEndGroup.next = token.next;
    return newEndGroup;
  }

  @override
  Token replaceTokenFollowing(Token previousToken, Token replacementToken) {
    Token replacedToken = previousToken.next;

    (replacementToken as SimpleToken).precedingComments =
        replacedToken.precedingComments;

    _lastTokenInChain(replacementToken).next = replacedToken.next;
    return replacementToken;
  }

  /// Given the [firstToken] in a chain of tokens to be inserted, return the
  /// last token in the chain.
  Token _lastTokenInChain(Token firstToken) {
    Token current = firstToken;
    while (current.next != null && current.next.type != TokenType.EOF) {
      current = current.next;
    }
    return current;
  }
}
